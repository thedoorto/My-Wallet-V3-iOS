//
//  LabeledButtonView.swift
//  PlatformUIKit
//
//  Created by Daniel Huri on 22/01/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit
import RxCocoa
import RxSwift

public final class LabeledButtonView<ViewModel: LabeledButtonViewModelAPI>: UIView {

    // MARK: - UI Properties

    private let button = UIButton()

    // MARK: - Injected

    var viewModel: ViewModel! {
        didSet {
            disposeBag = DisposeBag()
            guard let viewModel = viewModel else { return }

            button.rx.tap
                .bindAndCatch(to: viewModel.tapRelay)
                .disposed(by: disposeBag)

            viewModel.content
                .drive(button.rx.content)
                .disposed(by: disposeBag)
        }
    }

    // MARK: - Accessors

    private var disposeBag = DisposeBag()

    // MARK: - Setup

    init() {
        super.init(frame: .zero)
        setupButton()
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    
    private func setupButton() {
        addSubview(button)
        button.layoutToSuperview(axis: .horizontal)
        button.layoutToSuperview(axis: .vertical)
        button.maximizeResistanceAndHuggingPriorities()
        button.contentEdgeInsets = .init(horizontal: 8, vertical: 6)
        button.showsTouchWhenHighlighted = true
    }
}
