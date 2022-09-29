//
//  CurrencyExchangeApp.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 22/9/22.
//

import SwiftUI

@main
struct CurrencyExchangeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
