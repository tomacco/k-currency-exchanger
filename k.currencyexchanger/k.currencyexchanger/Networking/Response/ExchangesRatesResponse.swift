//
//  ExchangesRatesResponse.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation

typealias Currency = String

struct ExchangesRatesResponse: Codable {
    let success: Bool
    let timestamp: Date
    let base: Currency
    let rates: [Currency : Double]
}

extension ExchangesRatesResponse {
    func toCurrencyRatesModel() -> CurrencyRatesModel {
        return CurrencyRatesModel(
            currencyRates: self.rates,
            baseCurrency: self.base
        )
    }
}

