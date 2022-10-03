//
//  UserCurrencyTransaction+Extension.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 2/10/22.
//

import Foundation


extension UserCurrencyTransaction {
    var transactionType: TxType {
         get {
            return TxType(rawValue: self.transactionTypeValue)!
        }
        set {
            self.transactionTypeValue = newValue.rawValue
        }
    }
}
