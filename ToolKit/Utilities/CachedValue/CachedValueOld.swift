//
//  CachedValueOld.swift
//  PlatformKit
//
//  Created by Jack on 19/09/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift

/// This implements an in-memory cache with transparent refreshing/invalidation
/// after `refreshInterval` has elapsed.
public class CachedValueOld<Value> {
    
    // MARK: Types
    
    /// The fetch method
    private enum FetchMethod {
        
        /// An observable - keeps streaming elements
        case observable(() -> Observable<Value>)
        
        /// A single - streams once and terminates
        case single(() -> Single<Value>)
    }
    
    enum StreamState: CustomDebugStringConvertible {
                        
        /// The data has not been calculated yet
        case empty
        
        /// The data should be flushed
        case flush
        
        /// The stream erred at some point and is now invalid
        case invalid(shouldFetch: Bool)
        
        /// The stream is in midst of claculating next element
        case calculating
        
        /// The data should be streamed
        case stream(StreamType)
        
        /// Returns the stream
        var streamType: StreamType? {
            switch self {
            case .stream(let streamType):
                return streamType
            default:
                return nil
            }
        }
        
        var isCalculating: Bool {
            guard case .calculating = self else { return false }
            return true
        }
        
        var isInvalid: Bool {
            guard case .invalid = self else { return false }
            return true
        }
        
        var debugDescription: String {
            switch self {
            case .calculating:
                return "calculating"
            case .empty:
                return "empty"
            case .flush:
                return "flush"
            case .invalid(shouldFetch: let shouldFetch):
                return "invalid(shouldFetch: \(shouldFetch))"
            case .stream(let type):
                switch type {
                case .none:
                    return "stream: none"
                case .private(let value):
                    return "private stream: \(value)"
                case .public(let value):
                    return "public stream: \(value)"
                }
            }
        }
    }
    
    /// The type of the stream - only public streams' values are exposed to external subscribers
    enum StreamType {
        
        /// Stream the value publicly
        case `public`(Value)
        
        /// Stream the value privately
        case `private`(Value)
                
        /// Stream nothing
        case none
        
        var isPublic: Bool {
            if case .public = self {
                return true
            }
            return false
        }
        
        var value: Value? {
            switch self {
            case .private(let value), .public(let value):
                return value
            case .none:
                return nil
            }
        }
    }
    
    /// The caching error
    public enum CacheError: Error, CustomDebugStringConvertible {
        
        /// The fetch has failed for a generic reason
        case fetchFailed
        
        /// The fetch has failed because of an unset fech closure
        case unsetFetchClosure
        
        /// Internal error has occurred
        case internalError
        
        public var debugDescription: String {
            let type = String(describing: Value.self)
            switch self {
            case .fetchFailed:
                return "⚠️ Cached Value error - fetch failed for \(type)"
            case .unsetFetchClosure:
                return "⚠️ Cached Value error - `fetch` is not set for \(type)"
            case .internalError:
                return "⚠️ Cached Value error - internal error for \(type)"
            }
        }
    }
    
    // MARK: - Properties
    
    @available(*, deprecated, message: "Do not use this! It is meant to support legacy code")
    public var legacyValue: Value? {
        stateRelay.value.streamType?.value
    }

    public var invalidate: Completable {
        Completable.create { [weak self] observer -> Disposable in
            self?.refreshControl.actionRelay.accept(.flush)
            return Disposables.create()
        }
    }
    
    /// Streams a single value and terminates
    public var valueSingle: Single<Value> {
        valueObservable
            .take(1)
            .asSingle()
    }
    
    /// Streams a value upon each refresh.
    public var valueObservable: Observable<Value> {
        stateRelay
            .observeOn(configuration.scheduler)
            .do(onSubscribe: { [weak stateRelay] in
                guard let stateRelay = stateRelay else { return }
                switch stateRelay.value {
                case .invalid(shouldFetch: false):
                    stateRelay.accept(.invalid(shouldFetch: true))
                default:
                    break
                }
            })
            .flatMap(weak: self, fetchPriority: configuration.fetchPriority) { (self, state) -> Observable<StreamType> in
                let fetch = { () -> Observable<StreamType> in
                    guard let fetch = self.fetch else { return .just(.none) }
                    switch fetch {
                    case .observable:
                        return self.fetchAsObservable()
                            .catchError { error in
                                throw error
                            }
                            .map { _ in StreamType.none }
                    case .single:
                        return self.fetchAsSingle()
                            .asObservable()
                            .catchError { error in
                                throw error
                            }
                            .map { _ in StreamType.none }
                    }
                }
                
                switch state {
                case .empty:
                    return fetch()
                case .calculating:
                    return .just(.none)
                case .flush:
                    self.stateRelay.accept(.invalid(shouldFetch: false))
                    return .just(.none)
                case .invalid(shouldFetch: let shouldFetch):
                    if shouldFetch {
                        return fetch()
                    } else {
                        return .just(.none)
                    }
                case .stream(.private(let value)):
                    return self.refreshControl.shouldRefresh
                        .asObservable()
                        .flatMap { shouldRefresh -> Observable<StreamType> in
                            if shouldRefresh {
                                return fetch()
                            } else {
                                return .just(.public(value))
                            }
                        }
                case .stream(.public), .stream(.none):
                    return .just(.none)
                }
            }
            .catchError { error in
                switch error {
                case ToolKitError.nullReference:
                    /// Do nothing on a null reference
                    return .just(.none)
                case CacheError.fetchFailed:
                    /// The fetch has failed - we are in invalid state w/o a refetch option
                    /// throw the error to be caught down the observable stream
                    throw error
                default:
                    /// If any error other than `ToolKitError.nullReference`
                    /// or `CacheError.fetchFailed` is thrown, make sure to
                    /// stream an invalid element w/o a fetch
                    self.stateRelay.accept(.invalid(shouldFetch: false))
                    throw CacheError.fetchFailed
                }
            }
            .filter { $0.isPublic }
            .compactMap { $0.value }
    }
    
    /// Fetches (from remote) and caches the value
    public var fetchValue: Single<Value> {
        fetchAsSingle()
    }
    
    public var fetchValueObservable: Observable<Value> {
        fetchAsObservable()
    }
    
    var innerState: Observable<StreamState> {
        stateRelay.asObservable()
    }
    
    // MARK: - Private properties
    
    private let stateRelay = BehaviorRelay<StreamState>(value: .empty)
    
    /// The calculation state streams `StreamType` elements to differentiate between publicly streamed elements
    /// which are ready to be distributed to subscribers, and privately streamed elements which are not intended to be distributed
    private var state: Observable<StreamState> {
        stateRelay.asObservable()
    }
            
    private var fetch: FetchMethod?
    private let configuration: CachedValueConfigurationOld
    private let refreshControl: CachedValueRefreshControlOld
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    
    public init(configuration: CachedValueConfigurationOld) {
        self.configuration = configuration
        refreshControl = CachedValueRefreshControlOld(configuration: configuration)
        refreshControl.action
            .observeOn(configuration.scheduler)
            .map { action in
                switch action {
                case .fetch:
                    return .empty
                case .flush:
                    return .flush
                }
            }
            .bindAndCatch(to: stateRelay)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public methods
    
    /// Performs the fetch action and streams the values.
    /// This method is expected to keep streaming values until a termination / disposal event occurs.
    /// Suitable for complex streams throughout the app.
    private func fetchObservableValue(_ fetch: () -> Observable<Value>) -> Observable<Value> {
        fetch()
            .subscribeOn(configuration.scheduler)
            .observeOn(configuration.scheduler)
            .do(
                /// On successful fetch make the relay accept a privately distributed value
                onNext: { [weak self] value in
                    guard let self = self else { return }
                    self.refreshControl.update(refreshDate: Date())
                    self.stateRelay.accept(.stream(.private(value)))
                },
                onSubscribe: { [weak stateRelay] in
                    stateRelay?.accept(.calculating)
                },
                onDispose: { [weak stateRelay] in
                    if case .calculating = stateRelay?.value {
                        stateRelay?.accept(.empty)
                    }
                }
            )
    }
    
    /// Performs the fetch action and streams a single value.
    /// This method is expected to stream a single value per subscription.
    /// Suitable simple use streams and use cases.
    private func fetchSingleValue(_ fetch: () -> Single<Value>) -> Single<Value> {
        fetch()
            .subscribeOn(configuration.scheduler)
            .observeOn(configuration.scheduler)
            .do(
                /// On successful fetch make the relay accept a privately distributed value
                onSuccess: { [weak self] value in
                    guard let self = self else { return }
                    self.refreshControl.update(refreshDate: Date())
                    self.stateRelay.accept(.stream(.private(value)))
                },
                onSubscribe: { [weak stateRelay] in
                    stateRelay?.accept(.calculating)
                },
                onDispose: { [weak stateRelay] in
                    if case .calculating = stateRelay?.value {
                        stateRelay?.accept(.empty)
                    }
                }
            )
    }
    
    /// Sets a fetch method that streams an observable
    public func setFetch(_ fetch: @escaping () -> Observable<Value>) {
        self.fetch = .observable(fetch)
    }
    
    /// Sets a fetch method that streams a single
    public func setFetch(_ fetch: @escaping () -> Single<Value>) {
        self.fetch = .single(fetch)
    }
    
    /// Sets a fetch method that streams a single value (doesn't retain the given object)
    public func setFetch<A: AnyObject>(weak object: A, fetch: @escaping (A) -> Single<Value>) {
        self.fetch = .single { [weak object] in
            guard let object = object else {
                return .error(ToolKitError.nullReference(A.self))
            }
            return fetch(object)
        }
    }
    
    /// Sets a fetch method that streams values (doesn't retain the given object)
    public func setFetch<A: AnyObject>(weak object: A, fetch: @escaping (A) -> Observable<Value>) {
        self.fetch = .observable { [weak object] in
            guard let object = object else {
                return .error(ToolKitError.nullReference(A.self))
            }
            return fetch(object)
        }
    }
    
    // MARK: - Private methods
    
    private func fetchAsObservable() -> Observable<Value> {
        guard let fetch = fetch else {
            return .error(CacheError.unsetFetchClosure)
        }
        guard case .observable(let method) = fetch else {
            return .error(CacheError.internalError)
        }
        return fetchObservableValue(method)
    }
    
    private func fetchAsSingle() -> Single<Value> {
        guard let fetch = fetch else {
            return .error(CacheError.unsetFetchClosure)
        }
        guard case .single(let method) = fetch else {
            return .error(CacheError.internalError)
        }
        return fetchSingleValue(method)
    }
}

private extension ObservableType {
    func flatMap<A: AnyObject, R>(weak object: A,
                                  fetchPriority: CachedValueConfigurationOld.FetchPriority,
                                  selector: @escaping (A, Self.Element) throws -> Observable<R>) -> Observable<R> {
        switch fetchPriority {
        case .fetchAll:
            return flatMap(weak: object, selector: selector)
        case .throttle(milliseconds: let time, scheduler: let scheduler):
            return self.throttle(
                    .milliseconds(time),
                    scheduler: scheduler
                )
                .flatMap(
                    weak: object,
                    selector: selector
                )
        }
    }
}

extension CachedValueOld.StreamType where Value: Equatable {
    
    var debugState: String {
        switch self {
        case .none:
            return "none"
        case .private(let element):
            return "private \(element)"
        case .public(let element):
            return "public \(element)"
        }
    }
}

extension CachedValueOld.StreamState where Value: Equatable {
    
    var debugState: String {
        switch self {
        case .calculating:
            return "calculating"
        case .empty:
            return "empty"
        case .flush:
            return "flush"
        case .invalid(shouldFetch: let shouldFetch):
            return "invalid(shouldFetch: \(shouldFetch))"
        case .stream(let type):
            return type.debugState
        }
    }
}
