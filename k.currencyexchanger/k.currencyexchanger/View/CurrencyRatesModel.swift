//
//  CurrencyRatesModel.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation

struct CurrencyRatesModel {
    let currencyRates: [Currency : Double]
    let baseCurrency: Currency
    
    lazy var supportedCurrencies:[Currency] = {
        Array(currencyRates.keys)
    }()
    
    func exchangeRate(fromCurrency: Currency, toCurrency: Currency) -> Double? {
        guard let fromRatio = currencyRates[fromCurrency],
              let toRatio = currencyRates[toCurrency] else {
            return nil
        }
        return fromRatio / toRatio
    }
    
    func doExchange(fromCurrency: Currency,
                    toCurrency: Currency,
                    amount: Decimal
    ) -> Decimal? {
        guard let ratio = self.exchangeRate(fromCurrency: fromCurrency, toCurrency: toCurrency) else {
            return nil
        }
        
        return amount * Decimal(ratio)
    }
    
}
