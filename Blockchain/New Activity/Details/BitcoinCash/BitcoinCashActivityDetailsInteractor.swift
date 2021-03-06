//
//  BitcoinCashActivityDetailsInteractor.swift
//  Blockchain
//
//  Created by Paulo on 26/05/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import BitcoinKit
import PlatformKit
import RxSwift

final class BitcoinCashActivityDetailsInteractor {

    // MARK: - Private Properties
    
    private let fiatCurrencySettings: FiatCurrencySettingsServiceAPI
    private let priceService: PriceServiceAPI
    private let detailsService: AnyActivityItemEventDetailsFetcher<BitcoinCashActivityItemEventDetails>
    
    // MARK: - Init

    init(wallet: BitcoinWallet = WalletManager.shared.wallet.bitcoin,
         fiatCurrencySettings: FiatCurrencySettingsServiceAPI = UserInformationServiceProvider.default.settings,
         priceService: PriceServiceAPI = PriceService(),
         serviceProvider: BitcoinCashServiceProvider = BitcoinCashServiceProvider.shared) {
        self.detailsService = serviceProvider.services.activityDetails
        self.fiatCurrencySettings = fiatCurrencySettings
        self.priceService = priceService
    }
    
    // MARK: - Public Functions
    
    func details(identifier: String, createdAt: Date) -> Observable<BitcoinCashActivityDetailsViewModel> {
        let transaction = detailsService
            .details(for: identifier)

        let price = self.price(at: createdAt)
            .optional()
            .catchErrorJustReturn(nil)

        return Observable
            .combineLatest(
                transaction,
                price.asObservable()
            )
            .map { BitcoinCashActivityDetailsViewModel(details: $0, price: $1?.priceInFiat) }
    }
    
    // MARK: - Private Functions

    private func price(at date: Date) -> Single<PriceInFiatValue> {
        fiatCurrencySettings
            .fiatCurrency
            .flatMap(weak: self) { (self, fiatCurrency) in
                self.price(at: date, in: fiatCurrency)
            }
    }

    private func price(at date: Date, in fiatCurrency: FiatCurrency) -> Single<PriceInFiatValue> {
        priceService.price(
            for: .bitcoinCash,
            in: fiatCurrency,
            at: date
        )
    }
}
