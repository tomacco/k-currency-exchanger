//
//  CalculatedCurrencyExchange.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 1/10/22.
//

import Foundation

struct CalculatedCurrencyExchange {
    let from: AmountWithCurrency
    let to: OptionalAmountWithCurrency
    var isSuccessfulExchange: Bool {
        return to.amount != nil
    }
}

struct OptionalAmountWithCurrency {
    let currency: Currency
    let amount: Decimal?
}
