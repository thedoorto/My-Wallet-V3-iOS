//
//  SettingsServiceAPI.swift
//  PlatformKit
//
//  Created by Daniel Huri on 23/12/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import RxRelay
import RxSwift

public protocol SettingsServiceAPI: class {
    var valueSingle: Single<WalletSettings> { get }
    var valueObservable: Observable<WalletSettings> { get }
    func fetch(force: Bool) -> Single<WalletSettings>
}

public protocol LastTransactionSettingsUpdateServiceAPI: class {
    func updateLastTransaction() -> Completable
}

public protocol EmailNotificationSettingsServiceAPI: SettingsServiceAPI {
    func emailNotifications(enabled: Bool) -> Completable
}

public protocol UpdateMobileSettingsServiceAPI {
    func update(mobileNumber: String) -> Completable
}

public protocol VerifyMobileSettingsServiceAPI {
    func verify(with code: String) -> Completable
}

public protocol SMSTwoFactorSettingsServiceAPI: SettingsServiceAPI {
    func smsTwoFactorAuthentication(enabled: Bool) -> Completable
}

public protocol MobileSettingsServiceAPI: UpdateMobileSettingsServiceAPI, VerifyMobileSettingsServiceAPI, SettingsServiceAPI { }
