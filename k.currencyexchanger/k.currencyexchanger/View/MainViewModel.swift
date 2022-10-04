//
//  MainViewModel.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 3/10/22.
//

import Foundation
import Combine

class MainViewModel: ObservableObject {
    
    var subscriptions = Set<AnyCancellable>()
    @Published var state = State()
    private let numberFormatter: NumberFormatter
    
    init() {
        numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
    }
    
    
    func send(_ event: Event) {
        guard let reducePublisher = reduce(event: event) else {
            return
        }
        
        reducePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: send)
            .store(in: &subscriptions)
    }
    
}

extension MainViewModel {
    
    struct State {
        var isCurrencyExchangePopupPresented = false
        var isErrorPopupPresented = false
        var isInfoPopupPresented = false
        var errorText: String = ""
        var infoText: String = ""
        var isShowingDeleteWarningAlert = false
    }
    
    enum Event {
        case onAppear
        case presentCurrencyExchangePopup
        case attemptCurrencyExchange(Currency, Currency, Decimal)
        case dismissErrorPopup
        case dismissInfoPopup
        case startDeleteAllTransactions
        case deleteAllTransactions
        case dismissDeleteWarningPopup
    }
    
    func reduce(event: Event) -> AnyPublisher<Event, Never>? {
        switch event {
        case .onAppear:
            let userCurrencyTxService = UserCurrencyTxService.shared
            let transactions = userCurrencyTxService.getAllTransactions()
            if transactions.isEmpty {
                let _ = userCurrencyTxService.performTransaction(currency: "EUR",
                                                                 txType: .debit,
                                                                 amount: 1000,
                                                                 currencyExchangeTxId: nil
                )
            }
        case .presentCurrencyExchangePopup:
            DispatchQueue.main.async {
                self.state.isErrorPopupPresented = false
                self.state.isCurrencyExchangePopupPresented = true
            }
        case .attemptCurrencyExchange(let sourceCurrency, let targetCurrency, let amount):
            let exchangeRequest = CurrencyExchangeRequest(
                from: AmountWithCurrency(
                    currency: sourceCurrency,
                    amount: amount),
                toCurrency: targetCurrency
            )
            
            let requestResult = CurrencyExchangeService.shared.exhangeCurrencyAndSaveTransactions(
                exchangeRequest: exchangeRequest
            )
            if !requestResult.isSuccessfulExchange || requestResult.error != nil {
                DispatchQueue.main.async {
                    self.state.infoText = ""
                    self.state.errorText = requestResult.error ?? "Unknown error"
                    self.state.isCurrencyExchangePopupPresented = false
                    self.state.isInfoPopupPresented = false
                    self.state.isErrorPopupPresented = true
                }
                return nil
            }
            // Exchange was successful
            self.showSuccessfulInfoPopup(result: requestResult)
            
        case .dismissErrorPopup:
            DispatchQueue.main.async {
                self.state.isErrorPopupPresented = false
            }
        case .dismissInfoPopup:
            DispatchQueue.main.async {
                self.state.isInfoPopupPresented = false
            }
        case .startDeleteAllTransactions:
            DispatchQueue.main.async {
                self.state.isShowingDeleteWarningAlert = true
                self.state.isInfoPopupPresented = false
                self.state.isErrorPopupPresented = false
            }
        case .deleteAllTransactions:
            UserCurrencyTxService.shared.deleteAllTransactions()
            self.send(.dismissDeleteWarningPopup)
        case .dismissDeleteWarningPopup:
            DispatchQueue.main.async {
                self.state.isShowingDeleteWarningAlert = false
            }
        }
        
        return nil
    }
    
    private func showSuccessfulInfoPopup(result: CurrencyExchangeResult) {
        let sourceCurrency = result.calculatedExchange.from.currency
        let targetCurrency = result.calculatedExchange.to.currency
        
        let sourceAmount = result.calculatedExchange.from.amount.asCurrencyFormattedString()
        let targetAmount = result.calculatedExchange.to.amount!.asCurrencyFormattedString()
        
        let comissionFeeCurrency = result.applicableFees.first?.key ?? ""
        let comissionAmount = (result.applicableFees.first?.value ?? 0).asCurrencyFormattedString()
        
        DispatchQueue.main.async {
            self.state.infoText = "You have converted \(sourceAmount) \(sourceCurrency) to \(targetAmount) \(targetCurrency). Comission fee -> \(comissionAmount) \(comissionFeeCurrency)"
            
            self.state.isInfoPopupPresented = true
            self.state.isCurrencyExchangePopupPresented = false
        }
        
    }
}
