//
//  CurrencyExchangeRequest.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 1/10/22.
//

import Foundation

struct CurrencyExchangeRequest {
    let from: AmountWithCurrency
    let toCurrency: Currency
}

struct AmountWithCurrency {
    let currency: Currency
    let amount: Decimal
    
    static func empty(_ currency: Currency) -> AmountWithCurrency {
        return AmountWithCurrency(
            currency: currency,
            amount: 0
        )
    }
}
