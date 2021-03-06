//
//  NabuAuthenticator.swift
//  PlatformKit
//
//  Created by Daniel on 26/06/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import RxSwift
import ToolKit
import NetworkKit

public class NabuAuthenticator: AuthenticatorAPI {
        
    @available(*, deprecated, message: "This is deprecated. Don't use this.")
    public var token: Single<String> {
        authenticationExecutor.token
    }
    
    private let offlineTokenRepository: NabuOfflineTokenRepositoryAPI
    private let authenticationExecutor: NabuAuthenticationExecutorAPI
    
    public init(offlineTokenRepository: NabuOfflineTokenRepositoryAPI,
                authenticationExecutor: NabuAuthenticationExecutorAPI) {
        self.offlineTokenRepository = offlineTokenRepository
        self.authenticationExecutor = authenticationExecutor
    }
    
    public func authenticate<Response>(_ singleFunction: @escaping (String) -> Single<Response>) -> Single<Response> {
        authenticationExecutor.authenticate(singleFunction: singleFunction)
    }
    
    @available(*, deprecated, message: "Don't use this.")
    public func authenticateWithResult<ResponseType: Decodable, ErrorResponseType: Error & Decodable>(
        _ singleFunction: @escaping (String) -> Single<Result<ResponseType, ErrorResponseType>>
    ) -> Single<Result<ResponseType, ErrorResponseType>> {
        let mappedSingle: (String) -> Single<ResponseType> = { token in
            singleFunction(token)
                .flatMap { result -> Single<ResponseType> in
                    result.single
                }
        }
        return authenticationExecutor
            .authenticate(singleFunction: mappedSingle)
            .map { response -> Result<ResponseType, ErrorResponseType> in
                .success(response)
            }
            .catchError { error -> Single<Result<ResponseType, ErrorResponseType>> in
                guard let mappedError = error as? ErrorResponseType else {
                    throw error
                }
                return .just(.failure(mappedError))
            }
    }
}
