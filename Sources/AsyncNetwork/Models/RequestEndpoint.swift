//
//  RequestEndpoint.swift
//  AsyncNetworkProvider
//
//  Created by y H on 2024/11/2.
//

import Foundation

public struct RequestEndpoint: Sendable {
    /// A string representation of the URL for the request.
    public let url: String

    /// The HTTP method for the request.
    public let method: HTTPMethod

    /// The `Task` for the request.
    public let task: EndpointTask

    /// The HTTP header fields for the request.
    public let httpHeaderFields: HTTPHeader?

    public init(url: String, method: HTTPMethod, task: EndpointTask, httpHeaderFields: HTTPHeader?) {
        self.url = url
        self.method = method
        self.task = task
        self.httpHeaderFields = httpHeaderFields
    }

    public func adding(newHTTPHeaderFields: HTTPHeader) -> RequestEndpoint {
        RequestEndpoint(url: url, method: method, task: task, httpHeaderFields: add(httpHeaderFields: newHTTPHeaderFields))
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with replaced `task` parameter.
    public func replacing(task: EndpointTask) -> RequestEndpoint {
        RequestEndpoint(url: url, method: method, task: task, httpHeaderFields: httpHeaderFields)
    }

    fileprivate func add(httpHeaderFields headers: HTTPHeader?) -> HTTPHeader? {
        guard let unwrappedHeaders = headers, unwrappedHeaders.isEmpty == false else {
            return httpHeaderFields
        }

        var newHTTPHeaderFields = httpHeaderFields ?? [:]
        for (key, value) in unwrappedHeaders {
            newHTTPHeaderFields[key] = value
        }
        return newHTTPHeaderFields
    }
}

extension RequestEndpoint: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        switch task {
        case let .uploadFile(file):
            hasher.combine(file)
        case let .uploadMultipart(multipartData), let .uploadCompositeMultipart(multipartData, _):
            hasher.combine(multipartData)
        default:
            break
        }

        if let request = try? urlRequest() {
            hasher.combine(request)
        } else {
            hasher.combine(url)
        }
    }
    
    /// Note: If both Endpoints fail to produce a URLRequest the comparison will
    /// fall back to comparing each Endpoint's hashValue.
    public static func == (lhs: RequestEndpoint, rhs: RequestEndpoint) -> Bool {
        let areEndpointsEqualInAdditionalProperties: Bool = {
            switch (lhs.task, rhs.task) {
            case (let .uploadFile(file1), let .uploadFile(file2)):
                return file1 == file2
            case (let .uploadMultipart(multipartData1), let .uploadMultipart(multipartData2)),
                 (let .uploadCompositeMultipart(multipartData1, _), let .uploadCompositeMultipart(multipartData2, _)):
                return multipartData1 == multipartData2
            default:
                return true
            }
        }()
        let lhsRequest = try? lhs.urlRequest()
        let rhsRequest = try? rhs.urlRequest()
        if lhsRequest != nil, rhsRequest == nil { return false }
        if lhsRequest == nil, rhsRequest != nil { return false }
        if lhsRequest == nil, rhsRequest == nil { return lhs.hashValue == rhs.hashValue && areEndpointsEqualInAdditionalProperties }
        return lhsRequest == rhsRequest && areEndpointsEqualInAdditionalProperties
    }
}

/// Extension for converting an `Endpoint` into a `URLRequest`.
public extension RequestEndpoint {
    /// Returns the `Endpoint` converted to a `URLRequest` if valid. Throws an error otherwise.
    func urlRequest() throws(AsyncNetworkError) -> URLRequest {
        guard let requestURL = Foundation.URL(string: url) else {
            throw .requestMapping(url)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        switch task {
        case .requestPlain, .uploadFile, .uploadMultipart, .downloadDestination:
            return request
        case let .requestData(data):
            request.httpBody = data
            return request
        case let .requestParameters(parameters: parameters, encoding: encoding):
            return try request.encoded(parameters: parameters, parameterEncoding: encoding)
        case let .requestCompositeParameters(bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, urlParameters: urlParameters):
            if let bodyEncoding = bodyEncoding as? URLEncoding, bodyEncoding.destination != .httpBody {
                fatalError("Only URLEncoding that `bodyEncoding` accepts is URLEncoding.httpBody. Others like `default`, `queryString` or `methodDependent` are prohibited - if you want to use them, add your parameters to `urlParameters` instead.")
            }
            let bodyfulRequest = try request.encoded(parameters: bodyParameters, parameterEncoding: bodyEncoding)
            let urlEncoding = URLEncoding(destination: .queryString)
            return try bodyfulRequest.encoded(parameters: urlParameters, parameterEncoding: urlEncoding)
        case let .downloadParameters(parameters: parameters, encoding: encoding, destination: _):
            return try request.encoded(parameters: parameters, parameterEncoding: encoding)
        case let .uploadCompositeMultipart(_, urlParameters: urlParameters):
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        }
    }
}

extension URLRequest {
    func encoded(parameters: Parameters, parameterEncoding: ParameterEncoding) throws(AsyncNetworkError) -> URLRequest {
        do {
            return try parameterEncoding.encode(self, with: parameters)
        } catch {
            throw .parameterEncoding(error)
        }
    }
}
