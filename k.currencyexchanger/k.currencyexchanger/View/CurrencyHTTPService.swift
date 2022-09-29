//
//  CurrencyHTTPService.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation
import Combine

struct CurrencyHTTPService {
    func fetchCurrencieRates() -> AnyPublisher<ExchangesRatesResponse, NetworkError> {
        return HTTPClient.execute(with: ApiPlayerAllCurrencies())
            .eraseToAnyPublisher()
    }
}
