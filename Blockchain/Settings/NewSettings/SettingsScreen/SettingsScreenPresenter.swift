//
//  SettingsScreenPresenter.swift
//  Blockchain
//
//  Created by AlexM on 12/12/19.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import BuySellKit
import BuySellUIKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift

final class SettingsScreenPresenter {

    // MARK: - Types

    private typealias CellType = SettingsSectionType.CellType
    typealias Section = SettingsSectionType
    
    // MARK: - Navigation Properties
    
    let trailingButton: Screen.Style.TrailingButton = .none
    
    var leadingButton: Screen.Style.LeadingButton {
        if #available(iOS 13.0, *) {
            return .none
        } else {
            return .close
        }
    }
    
    let barStyle: Screen.Style.Bar = .lightContent()
    
    // MARK: - Public Properties
    
    var sectionObservable: Observable<[SettingsSectionViewModel]> {
        cardsSectionPresenter
            .presenters
            .map(weak: self) { (self, values) -> [SettingsSectionViewModel] in
                self.sectionArrangement.map {
                    SettingsSectionViewModel(
                        sectionType: $0,
                        items: self.cellArrangement(for: $0)
                    )
                }
            }
    }
    
    var sectionArrangement: [Section] {
        sections(
            exchangeEnabled: interactor.pitLinkingConfiguration.isEnabled,
            simpleBuyCardsEnabled: interactor.simpleBuyCardsConfiguration.isEnabled
        )
    }
    
    // MARK: - Cell Presenters
    
    let addCardCellPresenter: AddCardCellPresenter
    let mobileCellPresenter: MobileVerificationCellPresenter
    let emailCellPresenter: EmailVerificationCellPresenter
    let preferredCurrencyCellPresenter: PreferredCurrencyCellPresenter
    let smsTwoFactorSwitchCellPresenter: SMSTwoFactorSwitchCellPresenter
    let emailNotificationsCellPresenter: EmailNotificationsSwitchCellPresenter
    let bioAuthenticationCellPresenter: BioAuthenticationSwitchCellPresenter
    let swipeReceiveCellPresenter: SwipeReceiveSwitchCellPresenter

    let pitCellPresenter: PITConnectionCellPresenter
    let recoveryCellPresenter: RecoveryStatusCellPresenter
    let limitsCellPresenter: TierLimitsCellPresenter
    
    // MARK: - Public
    
    let actionRelay = PublishRelay<SettingsScreenAction>()

    // MARK: Private Properties
    
    private unowned let router: SettingsRouterAPI
    private let cardsSectionPresenter: CardsSettingsSectionPresenter
    private let linkedCardsRelay = BehaviorRelay<[LinkedCardCellPresenter]>(value: [])
    private let interactor: SettingsScreenInteractor
    private let disposeBag = DisposeBag()
    
    init(interactor: SettingsScreenInteractor = SettingsScreenInteractor(),
         router: SettingsRouterAPI) {
        self.router = router
        self.interactor = interactor
        addCardCellPresenter = AddCardCellPresenter(
            paymentMethodTypesService: interactor.simpleBuyService.paymentMethodTypes,
            tierLimitsProviding: interactor.tiersProviding,
            featureFetcher: interactor.featureConfigurator
        )
        emailNotificationsCellPresenter = EmailNotificationsSwitchCellPresenter(
            service: interactor.emailNotificationsService
        )
        emailCellPresenter = EmailVerificationCellPresenter(
            interactor: interactor.emailVerificationBadgeInteractor
        )
        mobileCellPresenter = MobileVerificationCellPresenter(
            interactor: interactor.mobileVerificationBadgeInteractor
        )
        preferredCurrencyCellPresenter = PreferredCurrencyCellPresenter(
            interactor: interactor.preferredCurrencyBadgeInteractor
        )
        
        /// TODO: Provide interactor to the presenter as services
        /// should not be accessed from the presenter
        
        limitsCellPresenter = TierLimitsCellPresenter(
            tiersProviding: interactor.tiersProviding
        )
        pitCellPresenter = PITConnectionCellPresenter(
            pitConnectionProvider: interactor.pitConnnectionProviding
        )
        recoveryCellPresenter = RecoveryStatusCellPresenter(
            recoveryStatusProviding: interactor.recoveryPhraseStatusProviding
        )
        bioAuthenticationCellPresenter = BioAuthenticationSwitchCellPresenter(
            biometryProviding: interactor.biometryProviding,
            appSettingsAuthenticating: interactor.settingsAuthenticating
        )
        swipeReceiveCellPresenter = SwipeReceiveSwitchCellPresenter(
            appSettings: interactor.appSettings
        )
        smsTwoFactorSwitchCellPresenter = SMSTwoFactorSwitchCellPresenter(service: interactor.smsTwoFactorService)
        
        cardsSectionPresenter = CardsSettingsSectionPresenter(
            interactor: interactor.cardSectionInteractor
        )
        
        setup()
    }
    
    // MARK: - Private
    
    private func setup() {
        // Bind notices
        cardsSectionPresenter
            .presenters
            .bindAndCatch(to: linkedCardsRelay)
            .disposed(by: disposeBag)
        
        actionRelay
            .bindAndCatch(to: router.actionRelay)
            .disposed(by: disposeBag)
    }

    private func sections(exchangeEnabled: Bool, simpleBuyCardsEnabled: Bool) -> [Section] {
        var sections: [Section] = [
            .profile,
            .preferences,
            .security
        ]
        
        if simpleBuyCardsEnabled {
            sections.append(.cards)
        }
        
        sections.append(.about)
        
        if exchangeEnabled {
            sections.insert(.connect, at: 2)
        }
        return sections
    }
    
    // MARK: - SettingsCellViewModel
    
    /// `SettingsCellViewModel` arrangement for a given `SettingsSectionType`.
    /// Most of the `CellTypes` have a subtype (e.g. `BadgeCellType`) and a `presenter`.
    /// If they do not, like `PlainCellType`, there's a `viewModel` on an extension.
    /// - Parameters:
    ///   - section: The given section in `Settings` (e.g. `About`, `LinkedCards`)
    private func cellArrangement(for section: Section) -> [SettingsCellViewModel] {
        switch section {
        case .profile:
            return [
                .init(
                    cellType: .badge(.limits, limitsCellPresenter)
                ),
                .init(
                    cellType: .clipboard(.walletID)
                ),
                .init(
                    cellType: .badge(.emailVerification, emailCellPresenter)
                ),
                .init(
                    cellType: .badge(.mobileVerification, mobileCellPresenter)
                ),
                .init(
                    cellType: .plain(.loginToWebWallet)
                )
            ]
        case .preferences:
            return [
                .init(
                    cellType: .switch(.emailNotifications, emailNotificationsCellPresenter)
                ),
                .init(
                    cellType: .badge(.currencyPreference, preferredCurrencyCellPresenter)
                )
            ]
        case .connect:
            return [
                .init(
                    cellType: .badge(.pitConnection, pitCellPresenter)
                )
            ]
        case .cards:
            var viewModels: [SettingsCellViewModel] = linkedCardsRelay
                .value
                .map {
                    .init(
                        cellType: .cards(.linkedCard($0))
                    )
                }
            
            viewModels.append(
                .init(
                    cellType: .cards(.addCard(addCardCellPresenter))
                )
            )
            return viewModels
        case .security:
            var viewModels: [SettingsCellViewModel] = [
                .init(
                    cellType: .switch(.sms2FA, smsTwoFactorSwitchCellPresenter)
                ),
                .init(
                    cellType: .plain(.changePassword)
                ),
                .init(
                    cellType: .badge(.recoveryPhrase, recoveryCellPresenter)
                ),
                .init(
                    cellType: .plain(.changePIN)
                ),
                .init(
                    cellType: .switch(.bioAuthentication, bioAuthenticationCellPresenter)
                )
            ]
            
            if interactor.swipeToReceiveConfiguration.isEnabled {
                viewModels.append(
                    .init(
                        cellType: .switch(.swipeToReceive, swipeReceiveCellPresenter)
                    )
                )
            }
            
            return viewModels
        case .about:
            return [
                .init(
                    cellType: .plain(.rateUs)
                ),
                .init(
                    cellType: .plain(.termsOfService)
                ),
                .init(
                    cellType: .plain(.privacyPolicy)
                ),
                .init(
                    cellType: .plain(.cookiesPolicy)
                )
            ]
        }
    }
    
    // MARK: - Public
    
    /// Should be called each time the `Settings` screen comes into view
    func refresh() {
        interactor.refresh()
    }
    
    // MARK: - Exposed
    
    func navigationBarLeadingButtonTapped() {
        router.previousRelay.accept(())
    }
}
