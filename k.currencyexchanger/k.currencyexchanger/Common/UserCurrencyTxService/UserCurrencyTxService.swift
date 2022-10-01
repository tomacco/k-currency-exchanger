//
//  UserTransactionsService.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 1/10/22.
//

import Foundation

class UserCurrencyTxService {
    
    static let shared = UserCurrencyTxService()
    
    private let coreDataContext = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    
    func getBalance(forCurrency currency: Currency) -> Decimal {
        let fetchRequest = UserCurrencyTransaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "currency == %@", currency)
        let txForCurrency = (try? coreDataContext.fetch(fetchRequest)) ?? []
        return txForCurrency.reduce(Decimal(0)) {
            $0 + ($1.amount?.decimalValue ?? 0)
        }
    }
    
    func saveTransaction(currency: Currency, amount: Decimal, isCurrencyExchange: Bool) {
        let newTx = UserCurrencyTransaction(context: coreDataContext)
        newTx.currency = currency
        newTx.amount = (amount) as NSDecimalNumber
        newTx.isCurrencyConversion = isCurrencyExchange
        newTx.createdAt = Date()
        newTx.id = UUID().uuidString
        do {
          try coreDataContext.save()
        } catch {
          let nsError = error as NSError
          fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
