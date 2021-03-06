//
//  StellarActivityDetailsInteractor.swift
//  Blockchain
//
//  Created by Paulo on 19/05/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import EthereumKit
import PlatformKit
import RxSwift
import StellarKit

final class StellarActivityDetailsInteractor {
    
    // MARK: - Private Properties

    private let fiatCurrencySettings: FiatCurrencySettingsServiceAPI
    private let priceService: PriceServiceAPI
    private let detailsService: AnyActivityItemEventDetailsFetcher<StellarActivityItemEventDetails>
    
    // MARK: - Init

    init(fiatCurrencySettings: FiatCurrencySettingsServiceAPI = UserInformationServiceProvider.default.settings,
         priceService: PriceServiceAPI = PriceService(),
         provider: StellarServiceProvider = StellarServiceProvider.shared) {
        self.fiatCurrencySettings = fiatCurrencySettings
        self.priceService = priceService
        detailsService = provider.services.activityDetails
    }
    
    // MARK: - Public Functions

    func details(identifier: String, createdAt: Date) -> Observable<StellarActivityDetailsViewModel> {
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
            .map { StellarActivityDetailsViewModel(with: $0, price: $1?.priceInFiat) }
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
            for: .stellar,
            in: fiatCurrency,
            at: date
        )
    }
}
