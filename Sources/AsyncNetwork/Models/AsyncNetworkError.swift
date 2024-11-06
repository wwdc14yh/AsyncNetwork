//
//  AsyncNetworkError.swift
//  AsyncNetworkProvider
//
//  Created by y H on 2024/11/2.
//

import Foundation

public enum AsyncNetworkError: Error, Sendable {
    /// Indicates a response failed with an invalid HTTP status code.
    case statusCode(Response)

    /// Indicates a response failed due to an underlying `Error`.
    case underlying(Swift.Error, Response?)

    /// Indicates that an `Endpoint` failed to map to a `URLRequest`.
    case requestMapping(String)

    /// Indicates that an `Endpoint` failed to encode the parameters for the `URLRequest`.
    case parameterEncoding(Swift.Error)
    
    case invalidURL
    
    case cancelled
    
    case unexpectedErrorCaptured
    
    var response: Response? {
        if case .statusCode(let response) = self {
            return response
        } else if case .underlying(_, let response) = self {
            return response
        }
        return nil
    }
}

extension AsyncNetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .statusCode:
            return "Status code didn't fall within the given range."
        case .underlying(let error, _):
            return error.localizedDescription
        case .requestMapping:
            return "Failed to map RequestEndpoint to a URLRequest."
        case .parameterEncoding(let error):
            return "Failed to encode parameters for URLRequest. \(error.localizedDescription)"
        case .cancelled:
            return NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil).localizedDescription
        case .unexpectedErrorCaptured:
            return "Unknown error."
        case .invalidURL:
            return "Invalid url."
        }
    }
}
