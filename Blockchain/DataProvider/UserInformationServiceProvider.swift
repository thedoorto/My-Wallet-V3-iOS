//
//  UserInformationServiceProvider.swift
//  Blockchain
//
//  Created by Daniel Huri on 24/12/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit

final class UserInformationServiceProvider: UserInformationServiceProviding {
    
    /// The default container
    static let `default` = UserInformationServiceProvider()
    
    /// Persistent service that has access to the general wallet settings
    let settings: SettingsServiceAPI &
                  EmailSettingsServiceAPI &
                  LastTransactionSettingsUpdateServiceAPI &
                  EmailNotificationSettingsServiceAPI &
                  FiatCurrencySettingsServiceAPI &
                  MobileSettingsServiceAPI &
                  SMSTwoFactorSettingsServiceAPI
    
    /// Computes and returns an email verification service API
    var emailVerification: EmailVerificationServiceAPI {
        EmailVerificationService(
            syncService: NabuServiceProvider.default.walletSynchronizer,
            settingsService: settings
        )
    }
    
    let general: GeneralInformationService
    
    init(repository: WalletRepositoryAPI = WalletManager.shared.repository,
         informationClient: GeneralInformationClientAPI = GeneralInformationClient(),
         settingsClient: SettingsClientAPI = SettingsClient()) {
        settings = SettingsService(
            client: settingsClient,
            credentialsRepository: repository
        )
        general = GeneralInformationService(client: informationClient)
    }
}
