//
//  NetworkError.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//

import Foundation

enum NetworkError: DescriptiveError {
    case urlRequestGenerationFailed
    case requestFailed(errorCode: Int, description: String?)
    case responseDecodingFailed(errorCode: Int?)
    case responseNotFound
    case networkOffline
    case badRequestBody(_ errorCode: Int?)
    case unauthorized(_ errorCode: Int?)
    case forbidden(_ errorCode: Int?)
    case serverError(_ errorCode: Int?)
    case unknownError(errorCode: Int?, description: String?)
    
    var code: Int? {
        switch self {
        case .urlRequestGenerationFailed:
            return nil
        case .requestFailed(errorCode: let errorCode, description: _):
            return errorCode
        case .responseDecodingFailed(errorCode: let errorCode):
            return errorCode
        case .responseNotFound:
            return 0
        case .networkOffline:
            return 0
        case .unauthorized(let errorCode):
            return errorCode
        case .forbidden(let errorCode):
            return errorCode
        case .unknownError(let errorCode, _):
            return errorCode
        case .badRequestBody(let errorCode):
            return errorCode
        case .serverError(let errorCode):
            return errorCode
        }
    }
    
    var description: String {
        switch self {
        case .urlRequestGenerationFailed:
            return NSLocalizedString("Client error: Unable to generate URL Request", comment: "")
        case .unknownError(_, description: let description):
            if let description = description {
                return description
            }
            return NSLocalizedString("Server Response Error",
                                     comment: "")
        case .networkOffline:
            return NSLocalizedString("Network Error", comment: "")
        case .responseDecodingFailed:
            return NSLocalizedString("Decoding failed", comment: "")
        case .responseNotFound:
            return NSLocalizedString("Response not found", comment: "")
        case .badRequestBody:
            return NSLocalizedString("Bad request body", comment: "")
        case .requestFailed(errorCode: let errorCode, description: let description):
            if let description = description {
                if 499 ... 599 ~= errorCode {
                    return String(format: NSLocalizedString("Server Response Error", comment: ""), errorCode)
                }
                else {
                    return description
                }
            } else {
                return String(format: NSLocalizedString("Server Response Error", comment: ""), errorCode)
            }
        case .unauthorized:
            return NSLocalizedString("Invalid credentials", comment: "")
        case .forbidden:
            return NSLocalizedString("User does not have permissions to access this resource",
                                     comment: "")
        case .serverError(_):
            return NSLocalizedString("Server Error", comment: "")
        }
    }

    var category: ErrorCategory {
        switch self {
        case .urlRequestGenerationFailed:
            return .nonRetryable
        case .requestFailed(errorCode: _, description: _):
            return .retryable
        case .responseDecodingFailed(errorCode: _):
            return .nonRetryable
        case .responseNotFound:
            return .nonRetryable
        case .networkOffline:
            return .retryable
        case .badRequestBody(errorCode: _):
            return .nonRetryable
        case .unauthorized(_):
            return .nonRetryable
        case .forbidden(_):
            return .nonRetryable
        case .unknownError(errorCode: _, description: _):
            return .retryable
        case .serverError(_):
            return .retryable
        }
    }
}

