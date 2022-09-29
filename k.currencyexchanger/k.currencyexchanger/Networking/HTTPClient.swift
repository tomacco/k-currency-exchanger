//
//  HTTPClient.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 22/9/22.
//

import Foundation
import Combine


class HTTPClient {
    
    public static let emptyData = "{}".data(using: .utf8)!
    public static var jsonDecoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        return jsonDecoder
    }
    
    static func execute<RouterType>(
        with router: RouterType
    ) -> AnyPublisher<
        RouterType.ResponseType,
        NetworkError
    > where RouterType: Router {
        guard let request = router.getURLRequest() else {
            return Fail<RouterType.ResponseType, NetworkError>(error: .urlRequestGenerationFailed).eraseToAnyPublisher()
        }
        
        return URLSession.shared
                .dataTaskPublisher(for: request)
                .tryMap { response -> Data in
                    try Self.validateResponseOrThrow(response)
                }
                .map { response -> Data in
                    response.isEmpty ? Self.emptyData : response
                }
                .flatMap { (data: Data) -> AnyPublisher<RouterType.ResponseType, Error> in
                    Self.publisherWithDecodedData(data, router)
                }
                .mapError({ error -> NetworkError in
                    Self.mapErrorToNetworkError(error: error, endpoint: router.endPoint)
                })
                .catch({ error -> AnyPublisher<RouterType.ResponseType, NetworkError> in
                    return Fail(error: error)
                            .eraseToAnyPublisher()
                })
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        
        
    }
    
    public static func validateResponseOrThrow(_ response: (data: Data?, response: URLResponse?)) throws -> Data {
        let data = response.data ?? emptyData
        guard let urlResponse = response.response else {
            throw NetworkError.networkOffline
        }

        debugPrint("result:")
        debugPrint(String(decoding: data, as: UTF8.self))
        try validate(response: (data, urlResponse))

        return data
    }
    
    private static func validate(response: (data: Data, response: URLResponse)) throws {
        guard let httpUrlResponse = response.response as? HTTPURLResponse else {
            throw NetworkError.responseNotFound
        }
        let responseStatusCode = httpUrlResponse.statusCode

        switch (responseStatusCode) {
        case (200...204):
            return
        case 400:
            throw NetworkError.badRequestBody(responseStatusCode)
        case 401:
            throw NetworkError.unauthorized(responseStatusCode)
        case 403:
            throw NetworkError.forbidden(responseStatusCode)
        default:
            throw NetworkError.serverError(responseStatusCode)
        }
    }
    
    public static func publisherWithDecodedData<RouterType>(
            _ data: Data,
            _ router:RouterType
    ) -> AnyPublisher<RouterType.ResponseType, Error> where RouterType: Router {
        switch (router.decoderType) {
        case .jsonDecoder:
            return Just(data)
                    .decode(type: RouterType.ResponseType.self, decoder: Self.jsonDecoder)
                    .eraseToAnyPublisher()
        case .htmlDecoder:
            let stringData = String(decoding: data, as: UTF8.self)
            return Just(stringData as! RouterType.ResponseType)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
        }
    }
    
    public static func mapErrorToNetworkError(error: Error, endpoint: String) -> NetworkError {
        debugPrint(error)
        if let error = error as? NetworkError {
            debugPrint("📱 A network error ocurred \(error) 📱")
            return error
        } else if let error = error as? DecodingError {
            debugPrint("❌ Decoding failed for \(endpoint)")
            debugPrint(error)
            return .responseDecodingFailed(errorCode: 0)
        } else {
            debugPrint("☠️ A custom error ocurred \(error) ☠️")
            return .unknownError(errorCode: 0, description: "Unknown error")
        }
    }
    
}
