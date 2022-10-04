//
//  ContentView.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 22/9/22.
//

import SwiftUI
import CoreData
import Combine
import AlertToast

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
    @State var targetCurrency: Currency = "EUR"
    @State var sourceCurrency: Currency = "EUR"
    @State var amountToExchange = 0.0
    @FocusState var isCurrencyAmountFocused: Bool
    @State var isCurrencyExchangePopupPresented = false {
        didSet {
            isCurrencyAmountFocused = isCurrencyExchangePopupPresented
        }
    }
    @State var isErrorPopupPresented = false
    @State var estimatedFeesText = ""
    @State var isInfoPopupPresented = false
    
    init() {
        numberFormatter = NumberFormatter()
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
                        Text(numberFormatter.string(from: amount as NSNumber) ?? "?")
                        Image(systemName: "arrow.left.arrow.right")
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
        .toast(isPresenting: $isErrorPopupPresented) {
            AlertToast(type: .regular, title: viewModel.state.errorText)
        }
        .toast(isPresenting: $isInfoPopupPresented) {
            AlertToast(type: .regular, title: viewModel.state.infoText)
        }
        .popover(isPresented: $isCurrencyExchangePopupPresented) {
            currencyPopUpView()
        }
        .onReceive(viewModel.$state) { state in
            self.isErrorPopupPresented = state.isErrorPopupPresented
            self.isCurrencyExchangePopupPresented = state.isCurrencyExchangePopupPresented
            self.isInfoPopupPresented = state.isInfoPopupPresented
        }
    }
    
    func addItem() { //todo delete me
        let _ = UserCurrencyTxService.shared.performTransaction(currency: "EUR", txType: .debit, amount: 10, currencyExchangeTxId: nil)
    }
    
    @ViewBuilder
    private func currencyPopUpView() -> some View {
        VStack(alignment: .center) {
            Text("Currency Exchange")
            TextField("0.0", value: $amountToExchange, formatter: numberFormatter)
                .font(Font.system(size: 18))
                .keyboardType(.numberPad)
                .fixedSize()
                .focused($isCurrencyAmountFocused)
                .onReceive(Just(amountToExchange)) { _ in determineFees() }

      
            HStack {
                Text(sourceCurrency)
                Image(systemName: "arrow.left.arrow.right")
                Picker("To", selection: $targetCurrency) {
                    ForEach(currencyExchangeService.availableCurrencies(), id: \.self) {
                        Text($0)
                    }
                }
            }
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            
            Text(estimatedFeesText)
                .padding(.bottom, 8)
            
            let isExchangeButtonDisabled = !self.isExchangeOperationValid
            
            Button {
                viewModel.send(.attemptCurrencyExchange(sourceCurrency, targetCurrency, Decimal(amountToExchange)))
            } label: {
                Text("Exchange")
            }.disabled(isExchangeButtonDisabled)

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
    
    private var isExchangeOperationValid: Bool {
        get {
            return !(targetCurrency.isEmpty || sourceCurrency == targetCurrency || amountToExchange <= 0)
        }
        set { }
    }
    
    private func determineFees() {
        
        let exchangeRequest = CurrencyExchangeRequest(
            from: AmountWithCurrency(
                currency: sourceCurrency,
                amount: Decimal(amountToExchange)
            ),
            toCurrency: targetCurrency
        )
        let exchResult = currencyExchangeService.calculateCurrencyExchangeWithFees(
            exchangeRequest: exchangeRequest
        )
        
        let feesInSourceCurrency = currencyExchangeService.convertFeesToCurrency(
            currency: sourceCurrency,
            fees: exchResult.applicableFees
        )
        let feeString = numberFormatter.string(from: feesInSourceCurrency as NSNumber) ?? "-"
        self.estimatedFeesText = "Comission Fee: \(feeString) \(sourceCurrency)"
        
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
