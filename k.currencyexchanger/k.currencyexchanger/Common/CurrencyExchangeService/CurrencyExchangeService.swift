//
//  CurrencyExchangeService.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation

class CurrencyExchangeService {
    
    static let shared = CurrencyExchangeService()
    
    private let coreDataContext = PersistenceController.shared.container.viewContext
    private var feeRules: [FeesRule] = []
    private var currencyRates : CurrencyRatesModel = CurrencyRatesModel()
    
    private init(){ }
    
    func exchangeCurrencyWithFees(exchangeRequest: CurrencyExchangeRequest) -> CurrencyExchangeResult {
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
            feesRule.calculateFee(exchangeRequest: exchangeRequest, forTxHistory: txHistory)
        }
        .flatMap{ $0 }
        .reduce(into: [Currency: Decimal]()) { partialResult, currentElement in
            let sumSoFar = partialResult[currentElement.key] ?? 0
            partialResult[currentElement.key] = sumSoFar
        }
    }
    
    private func fetchTransactions() -> [UserCurrencyTransaction] {
        let dataRequest = UserCurrencyTransaction.fetchRequest()
        return (try? coreDataContext.fetch(dataRequest)) ?? []
    }
    
    func exchangeRate(fromCurrency: Currency, toCurrency: Currency) -> Double? {
        guard let fromRatio = currencyRates.currencyRates[fromCurrency],
              let toRatio = currencyRates.currencyRates[toCurrency] else {
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
