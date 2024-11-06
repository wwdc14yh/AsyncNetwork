//
//  EndpointType.swift
//  AsyncNetworkSession
//
//  Created by y H on 2024/11/2.
//

import Alamofire

public typealias HTTPMethod = Alamofire.HTTPMethod
public typealias HTTPHeader = [String: String]

public struct AnyEndpoint: EndpointType {
    private let _endpoint: EndpointType

    public var path: String { _endpoint.path }

    public var method: AsyncNetwork.HTTPMethod { _endpoint.method }

    public var task: AsyncNetwork.EndpointTask { _endpoint.task }

    public var headers: AsyncNetwork.HTTPHeader? { _endpoint.headers }

    public var validationType: ValidationType { _endpoint.validationType }

    public init(_ endpoint: EndpointType) {
        _endpoint = endpoint
    }
}

public protocol EndpointType: Sendable {
    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }

    /// The HTTP method used in the request.
    var method: HTTPMethod { get }

    /// The type of HTTP task to be performed.
    var task: EndpointTask { get }

    /// The headers to be used in the request.
    var headers: HTTPHeader? { get }

    /// The type of validation to perform on the request. Default is `.none`.
    var validationType: ValidationType { get }
}

public extension EndpointType {
    /// The type of validation to perform on the request. Default is `.none`.
    var validationType: ValidationType { .none }

    func eraseToAnyEndpoint() -> AnyEndpoint { .init(self) }
}
