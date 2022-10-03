//
//  UserCurrencyTxService.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 2/10/22.
//

import Foundation

class UserCurrencyTxService {
    
    static let shared = UserCurrencyTxService()
    private init() {}
    
    private let userTxRepo = UserCurrencyTxRepo.shared
    
    func getAllTransactions() -> [UserCurrencyTransaction] {
        return userTxRepo.getAllTransactions()
    }
    
    func getBalance(forCurrency currency: Currency) -> Decimal {
        return userTxRepo.getBalance(forCurrency: currency)
    }
    
    func performTransaction(currency: Currency,
                            txType: TxType,
                            amount: Decimal,
                            currencyExchangeTxId: String?
    ) -> Bool {
        // “Debit all that comes in and credit all that goes out.”
        let balance = userTxRepo.getBalance(forCurrency: currency)

        if txType == .credit {
            let balanceIfCreditOccurs = balance - amount
            if balanceIfCreditOccurs < 0 {
                return false
            }
        }
        
        userTxRepo.saveTransaction(
            currency: currency,
            amount: amount,
            txType: txType,
            currencyExchangeTxId: currencyExchangeTxId
        )
        return true

    }
    
    static func balanceByCurrency(transactions: [UserCurrencyTransaction]) -> [Currency : Decimal] {
        return transactions.reduce(into: [Currency : Decimal]()) { partialResult, currentTx in
            let sumSoFar = partialResult[currentTx.currency!] ?? 0
            let amount = currentTx.amount?.decimalValue ?? 0
            switch currentTx.transactionType {
            case .debit:
                partialResult[currentTx.currency!] = sumSoFar + amount
            case .credit:
                partialResult[currentTx.currency!] = sumSoFar - amount
            }
        }
    }

}
