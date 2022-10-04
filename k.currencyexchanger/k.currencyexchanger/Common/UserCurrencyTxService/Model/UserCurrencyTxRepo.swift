//
//  UserTransactionsService.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 1/10/22.
//

import Foundation
import CoreData

class UserCurrencyTxRepo {
    
    static let shared = UserCurrencyTxRepo()
    
    private let coreDataContext = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    func getAllTransactions() -> [UserCurrencyTransaction] {
        let fetchRequest = UserCurrencyTransaction.fetchRequest()
        return (try? coreDataContext.fetch(fetchRequest)) ?? []
    }
    
    func deleteAllTransactions() {
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserCurrencyTransaction")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try coreDataContext.executeAndMergeChanges(using: deleteRequest)
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
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
    
    @discardableResult
    func saveTransaction(currency: Currency,
                         amount: Decimal,
                         txType: TxType,
                         currencyExchangeTxId: String?) -> Bool {
        let newTx = UserCurrencyTransaction(context: coreDataContext)
        newTx.currency = currency
        newTx.amount = (amount) as NSDecimalNumber
        newTx.currencyExchangeTxId = currencyExchangeTxId
        newTx.transactionType = txType
        newTx.createdAt = Date()
        newTx.id = UUID().uuidString
        do {
            try coreDataContext.save()
            return true
        } catch {
            let nsError = error as NSError
            debugPrint("Unresolved error \(nsError), \(nsError.userInfo)")
            return false
        }
    }
}

/// Source: https://stackoverflow.com/questions/60230251/swiftui-list-does-not-update-automatically-after-deleting-all-core-data-entity
extension NSManagedObjectContext {
    
    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    public func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}
