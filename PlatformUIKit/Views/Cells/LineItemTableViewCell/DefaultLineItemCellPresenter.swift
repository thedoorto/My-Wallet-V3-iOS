//
//  DefaultLineItemCellPresenter.swift
//  PlatformUIKit
//
//  Created by AlexM on 1/29/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import RxRelay
import RxSwift
import RxCocoa
import ToolKit
import PlatformKit

public final class DefaultLineItemCellInteractor: LineItemCellInteracting {
    public let title: LabelContentInteracting
    public let description: LabelContentInteracting

    public init(title: LabelContentInteracting = DefaultLabelContentInteractor(),
                description: LabelContentInteracting = DefaultLabelContentInteractor()) {
        self.title = title
        self.description = description
    }
}

public final class DefaultLineItemCellPresenter: LineItemCellPresenting {

    // MARK: - Properties

    public var image: Driver<UIImage?> {
        return imageRelay.asDriver()
    }

    /// The background color relay
    public let imageRelay = BehaviorRelay<UIImage?>(value: nil)

    public var backgroundColor: Driver<UIColor> {
        return backgroundColorRelay.asDriver()
    }

    /// Accepts tap from a view
    public let tapRelay: PublishRelay<Void> = .init()

    /// The background color relay
    let backgroundColorRelay = BehaviorRelay<UIColor>(value: .clear)

    public let titleLabelContentPresenter: LabelContentPresenting
    public let descriptionLabelContentPresenter: LabelContentPresenting

    // MARK: - Injected

    public let interactor: LineItemCellInteracting

    // MARK: - Init

    public init(interactor: DefaultLineItemCellInteractor) {
        self.interactor = interactor
        titleLabelContentPresenter = DefaultLabelContentPresenter.title(
            interactor: interactor.title
        )
        descriptionLabelContentPresenter = DefaultLabelContentPresenter.description(
            interactor: interactor.description
        )
    }
}
