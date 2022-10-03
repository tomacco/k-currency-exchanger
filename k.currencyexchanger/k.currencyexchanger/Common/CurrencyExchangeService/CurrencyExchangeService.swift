//
//  CurrencyExchangeService.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation
import SwiftUI

class CurrencyExchangeService {
    
    static let shared = CurrencyExchangeService()
    
    private let coreDataContext = PersistenceController.shared.container.viewContext
    private var feeRules: [FeesRule] = FeesRulesLoader.load()
    private var currencyTxService = UserCurrencyTxService.shared
    @Published var currencyViewModel = CurrencyViewModel()
    
    private init(){
        currencyViewModel.send(.scheduleDataFetch)
    }
    
    func exhangeCurrencyAndSaveTransactions(
        exchangeRequest: CurrencyExchangeRequest
    ) -> CurrencyExchangeResult {
        
        //TODO These operations need to be transactional
        
        var currencyExchangeAttemptResult = self.calculateCurrencyExchangeWithFees(exchangeRequest: exchangeRequest)
        
        if !currencyExchangeAttemptResult.isSuccessfulExchange {
            let targetCurrency = currencyExchangeAttemptResult.calculatedExchange.to.currency
            currencyExchangeAttemptResult.error = "Unable to exchange to destination currency '\(targetCurrency)'"
            return currencyExchangeAttemptResult
        }
        guard let convertedAmount = currencyExchangeAttemptResult.calculatedExchange.to.amount else {
            fatalError("Exchange result is marked as successful but target currency amount is nil!")
        }
        
        //Convert the fees to the source currency before crediting the source account.
        let feesInSourceCurrency = self.convertFeesToCurrency(currency: currencyExchangeAttemptResult.calculatedExchange.from.currency,
                                                              fees: currencyExchangeAttemptResult.applicableFees)
        let amountToCredit = currencyExchangeAttemptResult.calculatedExchange.from.amount + feesInSourceCurrency
        let currencyExchangeTxId = UUID().uuidString
        // 1. Credit the source currency
        let isCreditSuccesful = currencyTxService.performTransaction(
            currency: currencyExchangeAttemptResult.calculatedExchange.from.currency,
            txType: .credit,
            amount: amountToCredit,
            currencyExchangeTxId: currencyExchangeTxId
        )
        
        if !isCreditSuccesful {
            currencyExchangeAttemptResult.error = "Not enough funds."
            return currencyExchangeAttemptResult
        }
        
        // 2. Debit the target currency
        let _ = currencyTxService.performTransaction(
            currency: currencyExchangeAttemptResult.calculatedExchange.to.currency,
            txType: .debit,
            amount: convertedAmount,
            currencyExchangeTxId: currencyExchangeTxId
        )
        
        return currencyExchangeAttemptResult
    }
    
    func calculateCurrencyExchangeWithFees(exchangeRequest: CurrencyExchangeRequest) -> CurrencyExchangeResult {
        //1. Calculate the currency exchange
        let exchangedCurrencyAmount = self.doExchange(
            fromCurrency: exchangeRequest.from.currency,
            toCurrency: exchangeRequest.toCurrency,
            amount: exchangeRequest.from.amount
        )
        
        //2. Save the result
        let calculatedExchangeNoFees = CalculatedCurrencyExchange(
            from: AmountWithCurrency(
                currency: exchangeRequest.from.currency,
                amount: exchangeRequest.from.amount),
            to: OptionalAmountWithCurrency(
                currency: exchangeRequest.toCurrency,
                amount: exchangedCurrencyAmount
            )
        )
        
        //3. Calculate fees
        let feesMap = self.calculateFeesForExchange(exchangeRequest: calculatedExchangeNoFees)
        
        return CurrencyExchangeResult(
            calculatedExchange: calculatedExchangeNoFees,
            applicableFees: feesMap
        )
    }
    
    private func calculateFeesForExchange(
        exchangeRequest: CalculatedCurrencyExchange
    ) -> [Currency: Decimal] {
        let txHistory = self.fetchTransactions()
        
        return feeRules.map { feesRule in
            feesRule.calculateFee(
                exchangeRequest: exchangeRequest,
                forTxHistory: txHistory,
                currencyExchangeService: self
            )
        }
        .flatMap{ $0 }
        .reduce(into: [Currency: Decimal]()) { partialResult, currentElement in
            let sumSoFar = partialResult[currentElement.key] ?? 0
            partialResult[currentElement.key] = sumSoFar + currentElement.value
        }
    }
    
    private func fetchTransactions() -> [UserCurrencyTransaction] {
        let dataRequest = UserCurrencyTransaction.fetchRequest()
        return (try? coreDataContext.fetch(dataRequest)) ?? []
    }
    
    func exchangeRate(fromCurrency: Currency, toCurrency: Currency) -> Double? {
        let currencyRates = currencyViewModel.state.currencyRates
        guard let fromRatio = currencyRates.currencyRates[fromCurrency],
              let toRatio = currencyRates.currencyRates[toCurrency] else {
            return nil
        }
        return toRatio / fromRatio 
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
    
    func availableCurrencies() -> [Currency] {
        return currencyViewModel.state.currencyRates.supportedCurrencies.sorted()
    }
    
    func convertFeesToCurrency(currency targetCurrency: Currency, fees: [Currency : Decimal]) -> Decimal {
        return fees.reduce(Decimal(0)) { partialResult, entry in
            (self.doExchange(fromCurrency: entry.key, toCurrency: targetCurrency, amount: entry.value) ?? 0) + partialResult
        }
    }
     
    
}
