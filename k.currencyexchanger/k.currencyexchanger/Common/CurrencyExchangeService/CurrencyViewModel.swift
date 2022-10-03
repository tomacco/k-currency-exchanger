//
//  CurrencyViewModel.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation
import Combine

class CurrencyViewModel: ObservableObject {
    private static let fetchIntervalSeconds : TimeInterval = 60
    
    var subscriptions = Set<AnyCancellable>()
    var state = State()
    
    private let currencyHttpService = CurrencyHTTPService()
    
    private func fetchCurrenciRates() -> AnyPublisher<Event, Never> {
        currencyHttpService.fetchCurrencieRates()
            .map({ response in Event.currencyFetchCompleted(response.toCurrencyRatesModel())})
            .catch({ Just(Event.currencyFetchError($0)) })
                .eraseToAnyPublisher()
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


extension CurrencyViewModel {
    
    struct State {
        var isCurrencyRatesLoaded = false
        var currencyRates: CurrencyRatesModel = CurrencyRatesModel(
            currencyRates: [:],
            baseCurrency: ""
        )
        var currencyApiError: Error? = nil
    }
    
    enum Event {
        case scheduleDataFetch
        case fetchCurrencyRates
        case currencyFetchCompleted(CurrencyRatesModel)
        case currencyFetchError(Error)
    }
    
    func reduce(event: Event) -> AnyPublisher<Event, Never>? {
        switch event {
        case .scheduleDataFetch:
            fetchCurrenciesEvery(seconds: Self.fetchIntervalSeconds)
            return fetchCurrenciRates()
        case .fetchCurrencyRates:
            return fetchCurrenciRates()
        case .currencyFetchCompleted(let currencyRates):
            self.state.isCurrencyRatesLoaded = true
            self.state.currencyRates = currencyRates
        case .currencyFetchError(let error):
            self.state.currencyApiError = error
        }
        return nil
    }
    
    func fetchCurrenciesEvery(seconds: TimeInterval)  {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.send(.fetchCurrencyRates)
        }
    }
    
}
