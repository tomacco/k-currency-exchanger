//
//  ErrorCategory.swift
//  k.currencyexchanger
//
//  Created by Ivan Gonzalez on 29/9/22.
//


import Foundation
import SwiftUI

enum ErrorCategory {
    case nonRetryable
    case retryable
    case requiresLogout
}

protocol DescriptiveError: Error {
    var category: ErrorCategory { get }
    var title: String { get }
    var description: String { get }
    var code: Int? { get }
}

extension DescriptiveError {
    var title: String {
        return "Error"
    }
}

extension Error {
    func resolveCategory() -> ErrorCategory {
        guard let categorized = self as? DescriptiveError else {
            return .nonRetryable
        }

        return categorized.category
    }
}

