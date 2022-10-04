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
    }
    
    enum Event {
        case presentCurrencyExchangePopup
        case attemptCurrencyExchange(Currency, Currency, Decimal)
        case dismissErrorPopup
        case dismissInfoPopup
    }
    
    func reduce(event: Event) -> AnyPublisher<Event, Never>? {
        switch event {
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
                    self.state.errorText = requestResult.error ?? "Unknown error"
                    self.state.isCurrencyExchangePopupPresented = false
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
        }
        return nil
    }
    
    private func showSuccessfulInfoPopup(result: CurrencyExchangeResult) {
        let sourceCurrency = result.calculatedExchange.from.currency
        let targetCurrency = result.calculatedExchange.to.currency
        
        let sourceAmount = result.calculatedExchange.from.amount
        let targetAmount = result.calculatedExchange.to.amount!
        
        let comissionFeeCurrency = result.applicableFees.first?.key ?? ""
        let comissionAmount = result.applicableFees.first?.value ?? 0
        
        DispatchQueue.main.async {
            self.state.infoText = "You have converted \(sourceAmount) \(sourceCurrency) to \(targetAmount) \(targetCurrency). Comission fee -> \(comissionAmount) \(comissionFeeCurrency)"
            
            self.state.isInfoPopupPresented = true
            self.state.isCurrencyExchangePopupPresented = false
        }
        
    }
}
