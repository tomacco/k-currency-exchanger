//
//  Decimal+extension.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 4/10/22.
//

import Foundation

extension Decimal {
    
    func asCurrencyFormattedString() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter.string(from: self as NSNumber) ?? ""
    }
    
}
