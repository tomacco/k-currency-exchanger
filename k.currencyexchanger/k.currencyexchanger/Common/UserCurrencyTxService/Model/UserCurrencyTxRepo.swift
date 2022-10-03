//
//  UserTransactionsService.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 1/10/22.
//

import Foundation

class UserCurrencyTxRepo {
    
    static let shared = UserCurrencyTxRepo()
    
    private let coreDataContext = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    func getAllTransactions() -> [UserCurrencyTransaction] {
        let fetchRequest = UserCurrencyTransaction.fetchRequest()
        return (try? coreDataContext.fetch(fetchRequest)) ?? []
    }
    
    func getBalance(forCurrency currency: Currency) -> Decimal {
        let fetchRequest = UserCurrencyTransaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "currency == %@", currency)
        let txForCurrency = (try? coreDataContext.fetch(fetchRequest)) ?? []
        return txForCurrency.reduce(Decimal(0)) { partialResult, transaction in
            switch transaction.transactionType {
            case .debit:
                return partialResult + (transaction.amount?.decimalValue ?? 0)
            case .credit:
                return partialResult - (transaction.amount?.decimalValue ?? 0)
            }
        }
    }
    
    func saveTransaction(currency: Currency,
                         amount: Decimal,
                         txType: TxType,
                         currencyExchangeTxId: String?) {
        let newTx = UserCurrencyTransaction(context: coreDataContext)
        newTx.currency = currency
        newTx.amount = (amount) as NSDecimalNumber
        newTx.currencyExchangeTxId = currencyExchangeTxId
        newTx.transactionType = txType
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
