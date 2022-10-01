//
//  FeesRule.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 1/10/22.
//

import Foundation

protocol FeesRule {
    func calculateFee(
        exchangeRequest: CalculatedCurrencyExchange,
        forTxHistory txHistory: [UserCurrencyTransaction]
    ) -> [Currency: Decimal]
}

struct FixedFeeOverXTransactions: FeesRule {
    
    let firstFreeTransactionsCount: Int = 5
    let sourceCurrencyExchangeFeePercentage: Decimal = 0.7 / 100
    
    func calculateFee(
        exchangeRequest: CalculatedCurrencyExchange,
        forTxHistory txHistory: [UserCurrencyTransaction]
    ) -> [Currency: Decimal] {
        if !exchangeRequest.isSuccessfulExchange {
            return [:]
        }
        if txHistory.count <= firstFreeTransactionsCount {
            return [:]
        }
        
        let feeAmount = sourceCurrencyExchangeFeePercentage * exchangeRequest.from.amount
        
        return [exchangeRequest.from.currency : feeAmount]
        
    }
}

struct FeeOverXTransactionsPerDay: FeesRule {
    
    let dailyTransactionsAllowedWithoutFee = 15
    let fixedEurFee : Decimal = 0.3
    let targetCurrencyFeePercentage : Decimal = 1.2 / 100
    let currencyExchangeService = CurrencyExchangeService.shared
    
    func calculateFee(
        exchangeRequest: CalculatedCurrencyExchange,
        forTxHistory txHistory: [UserCurrencyTransaction]
    ) -> [Currency: Decimal] {
        if !exchangeRequest.isSuccessfulExchange {
            return [:]
        }
        let calendar = Calendar.current
        let todayTxs = txHistory
            .filter { transaction in
                calendar.isDateInToday(transaction.createdAt!) //TODO check this forced unwrapping in CoreData Model definition
            }
            .filter { transaction in
                transaction.isCurrencyConversion
            }
        
        if todayTxs.count <= dailyTransactionsAllowedWithoutFee {
            return [:]
        }
        guard let convertedAmount = exchangeRequest.to.amount else {
            fatalError("Exchange is marked as succesful but the converted amount is nil")
        }
        let percentageFee = convertedAmount * targetCurrencyFeePercentage
        guard let fixedFeeInTargetCurrency = currencyExchangeService.doExchange(
            fromCurrency: exchangeRequest.from.currency,
            toCurrency: exchangeRequest.to.currency,
            amount: fixedEurFee
        ) else {
            fatalError("Unable to Exchange fixed fee to target currency")
        }
        
        let totalFee =  percentageFee + fixedFeeInTargetCurrency
        return [exchangeRequest.to.currency : totalFee]
    }
    
    
    
}
