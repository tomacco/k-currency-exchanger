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
        let areFeesValid = self.checkIfFeesCanBeApplied(
            currencyExchangeAttemptResult.applicableFees,
            targetExchange: currencyExchangeAttemptResult.calculatedExchange.to,
            sourceExchange: currencyExchangeAttemptResult.calculatedExchange.from
        )
        if !areFeesValid {
            currencyExchangeAttemptResult.error = "There is no enough balance 😱"
            return currencyExchangeAttemptResult
        }
        
        let amountToCredit = currencyExchangeAttemptResult.calculatedExchange.from.amount
        let currencyExchangeTxId = UUID().uuidString
        // 1. Credit the source currency
        let isCreditSuccesful = currencyTxService.performTransaction(
            currency: currencyExchangeAttemptResult.calculatedExchange.from.currency,
            txType: .credit,
            amount: amountToCredit,
            currencyExchangeTxId: currencyExchangeTxId
        )
        if !isCreditSuccesful {
            currencyExchangeAttemptResult.error = "There is no enough balance 😱"
            return currencyExchangeAttemptResult
        }
        
        // 2. Debit the target currency
        let _ = currencyTxService.performTransaction(
            currency: currencyExchangeAttemptResult.calculatedExchange.to.currency,
            txType: .debit,
            amount: convertedAmount,
            currencyExchangeTxId: currencyExchangeTxId
        )
        
        // 3. Credit all the fees
        currencyExchangeAttemptResult.applicableFees.forEach { feeCurrency, feeAmount in
            let isFeeCreditSuccesful = currencyTxService.performTransaction(
                currency: feeCurrency,
                txType: .credit,
                amount: feeAmount,
                currencyExchangeTxId: currencyExchangeTxId
            )
            
            if !isFeeCreditSuccesful {
                fatalError("Credit on the fee currency \(feeCurrency), amount \(feeAmount) failed! ")
            }
        }
        
        return currencyExchangeAttemptResult
    }
    
    func checkIfFeesCanBeApplied(
        _ fees: [Currency: Decimal],
        targetExchange: OptionalAmountWithCurrency,
        sourceExchange: AmountWithCurrency
    ) -> Bool {
        for fee in fees {
            let feeAmount = fee.value
            let currency = fee.key
            let balance = UserCurrencyTxService.shared.getBalance(forCurrency: currency)

            //for target currency, use the potential balance if the operation succeeds
            if currency == targetExchange.currency {
                if (targetExchange.amount ?? 0) - feeAmount < 0 {
                    return false
                }
            }
            //for the source currency, substract the amount exchanged from current balance
            else if currency == sourceExchange.currency {
                if (balance - sourceExchange.amount - feeAmount) < 0 {
                    return false
                }
            }
            //Rest of the fees
            else if balance - feeAmount < 0 {
                return false
            }
        }
        return true
        
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
