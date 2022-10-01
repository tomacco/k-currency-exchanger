//
//  CurrencyExchangeResult.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 1/10/22.
//

import Foundation

struct CurrencyExchangeResult {
    let calculatedExchange: CalculatedCurrencyExchange
    let applicableFees: [Currency: Decimal]
    var isSuccessfulExchange: Bool {
        return calculatedExchange.isSuccessfulExchange
    }
}
