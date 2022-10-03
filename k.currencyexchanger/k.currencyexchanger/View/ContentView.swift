//
//  ContentView.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 22/9/22.
//

import SwiftUI
import CoreData
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserCurrencyTransaction.createdAt,
                                           ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<UserCurrencyTransaction>
    private let currencyExchangeService = CurrencyExchangeService.shared
    private let numberFormatter: NumberFormatter
    
    @StateObject var viewModel = MainViewModel()
    @State var targetCurrency: Currency = ""
    @State var sourceCurrency: Currency = "EUR"  {
        didSet {
            numberFormatter.currencyCode = sourceCurrency
        }
    }
    
    @State var amountToExchange = 0.0
    @State var isCurrencyExchangePopupPresented = false
    @State var isErrorPopupPresented = false
    
    init() {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
    }
    
    var body: some View {
        let transactionsArr = transactions.map { $0 }
        let balanceByCurrency = UserCurrencyTxService.balanceByCurrency(transactions: transactionsArr)
        
        NavigationView {
            List {
                ForEach(balanceByCurrency.sorted(by: >), id: \.key) { currency, amount in
                    HStack {
                        Text(currency)
                        Text(amount.description)
                        Text("-")
                    }.onTapGesture {
                        sourceCurrency = currency
                        viewModel.send(.presentCurrencyExchangePopup)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
        .popover(isPresented: $isCurrencyExchangePopupPresented) {
            currencyPopUpView()
        }
        .popover(isPresented: $isErrorPopupPresented) {
            errorPopUpView()
        }
        .onReceive(viewModel.$state) { state in
            self.isErrorPopupPresented = state.isErrorPopupPresented
            self.isCurrencyExchangePopupPresented = state.isCurrencyExchangePopupPresented
        }
    }
    
    func addItem() {
        let _ = UserCurrencyTxService.shared.performTransaction(currency: "EUR", txType: .debit, amount: 10, currencyExchangeTxId: nil)
    }
    
    @ViewBuilder
    private func currencyPopUpView() -> some View {
        VStack(alignment: .center) {
            Text("Currency Exchange")
            TextField("0.0", value: $amountToExchange, formatter: numberFormatter)
                .font(Font.system(size: 15))
      
            HStack {
                Text(sourceCurrency)
                Image(systemName: "arrow.left.arrow.right")
                Picker("To", selection: $targetCurrency) {
                    ForEach(currencyExchangeService.availableCurrencies(), id: \.self) {
                        Text($0)
                    }
                }
            }
            
            Button {
                viewModel.send(.attemptCurrencyExchange(sourceCurrency, targetCurrency, Decimal(amountToExchange)))
            } label: {
                Text("Exchange")
            }

        }
    }
    
    @ViewBuilder
    private func errorPopUpView() -> some View {
        VStack {
            Text("Error")
            Text(viewModel.state.errorText)
            Button("Dismiss") {
                viewModel.send(.dismissErrorPopup)
            }
        }
    }
    
    @ViewBuilder
    private func infoPopupView() -> some View {
        VStack {
            Text("Info")
            Text(viewModel.state.infoText)
            Button("Dismiss") {
                viewModel.send(.dismissInfoPopup)
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
