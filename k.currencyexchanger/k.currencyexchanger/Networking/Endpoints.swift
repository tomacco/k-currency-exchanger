//
//  Endpoints.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation

fileprivate let apiPlayerKey = InfoPlist.stringFor(key: "API_PLAYER_API_KEY")

protocol AuthorizedApiPlayerRouter: Router {}
extension AuthorizedApiPlayerRouter {
    var headers: [String : String] {
        return ["apiKey": apiPlayerKey]
    }
    
    var baseUrl: String {
        return "https://api.apilayer.com"
    }
}

struct ApiPlayerAllCurrencies: AuthorizedApiPlayerRouter {    
    typealias ResponseType = ExchangesRatesResponse
    
    var endPoint: String {
        return "/exchangerates_data/latest"
    }
    var method: HTTPMethod {
        return .get
    }
}
