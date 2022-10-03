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
    
}
