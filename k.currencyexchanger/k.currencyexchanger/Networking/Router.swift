//
//  Router.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 22/9/22.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

enum DataDecoderType {
    case jsonDecoder
    case htmlDecoder
}

protocol Router {
    associatedtype ResponseType: Decodable
    
    var baseUrl: String { get }
    var decoderType: DataDecoderType { get }
    var endPoint : String { get }
    var method: HTTPMethod { get }
    var headers : [String: String] { get }
    var parameters : [String: String] { get }
    var urlQueryItems: [URLQueryItem] { get }
    var body: Data? { get }
    func getURLRequest() -> URLRequest?
}


extension Router {
        
    var decoderType: DataDecoderType {
        return .jsonDecoder
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var headers: [String : String] {
        return [:]
    }
    
    var parameters: [String: String] {
        return [:]
    }
    
    var urlQueryItems: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        for eachQueryParam in parameters {
            queryItems.append(URLQueryItem(name: eachQueryParam.key, value: eachQueryParam.value))
        }
        return queryItems
    }
    
    var body: Data? {
        nil
    }
    
    var contentTypeHeaders: [String : String] {
        switch method {
        case .get:
            return [:]
        case .post, .put:
            return [
                "Content-Type": "application/json"
            ]
        }
    }
    
    func getURLRequest() -> URLRequest? {
        guard let apiURL = (self.baseUrl + endPoint)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: apiURL) else {
            return nil
        }
        
        var urlComponents = URLComponents(string: apiURL)
        if !urlQueryItems.isEmpty {
            urlComponents?.queryItems = urlQueryItems
        }
        var request = URLRequest(url: urlComponents?.url ?? url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers.merging(contentTypeHeaders, uniquingKeysWith: { $1 })
        request.httpBody = body
        return request
    }
    
}
