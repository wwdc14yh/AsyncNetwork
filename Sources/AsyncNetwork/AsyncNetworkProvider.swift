// The Swift Programming Language
// https://docs.swift.org/swift-book

import Alamofire
import Foundation

public typealias Session = Alamofire.Session

public struct AsyncNetworkProvider<Endpoint: EndpointType>: AsyncNetworkProviderType {
    /// Closure that defines the endpoints for the provider.
    public typealias RequestEndpointClosure = @Sendable (any AsyncNetworkProviderType, Endpoint) throws -> RequestEndpoint

    /// Closure that resolves an `RequestEndpoint` into a `RequestResult`.
    public typealias RequestClosure = @Sendable (RequestEndpoint) async throws(AsyncNetworkError) -> URLRequest

    public let baseURL: URL?
    public let session: Session

    /// A list of plugins.
    /// e.g. for logging, network activity indicator or credentials.
    public let plugins: [PluginType]

    /// A closure responsible for mapping a `EndpointType` to an `RequestEndpoint`.
    let requestEndpointClosure: RequestEndpointClosure

    /// A closure deciding if and what request should be performed.
    let requestClosure: RequestClosure

    public init(
        baseURL: URL?,
        session: Session = AsyncNetworkProviderTypeDefaultImplementation.defaultAlamofireSession(),
        requestEndpointClosure: @escaping RequestEndpointClosure = AsyncNetworkProviderTypeDefaultImplementation.defaultEndpointMapping,
        requestClosure: @escaping RequestClosure = AsyncNetworkProviderTypeDefaultImplementation.defaultRequestMapping,
        plugins: [PluginType] = []
    ) {
        self.baseURL = baseURL
        self.session = session
        self.requestEndpointClosure = requestEndpointClosure
        self.requestClosure = requestClosure
        self.plugins = plugins
    }

    public func requestAsync(_ endpoint: Endpoint, requestToken: RequestToken? = nil, progress: ProgressAction? = nil) async throws(AsyncNetworkError) -> Response {
        let _requestEndpoint: RequestEndpoint
        do {
            _requestEndpoint = try requestEndpoint(endpoint)
        } catch let error as AsyncNetworkError {
            throw error
        } catch {
            throw .underlying(error, nil)
        }
        
        let requestingConfiguration = RequestingConfiguration(requestToken, progress)
        if let requestToken, await requestToken.isCancelled {
            let failureResult: Result<Response, AsyncNetworkError> = .failure(.cancelled)
            plugins.forEach { $0.didReceive(failureResult, endpoint: endpoint, configuration: requestingConfiguration) }
            return try await buildPluginsResponse(failureResult, endpoint: endpoint, configuration: requestingConfiguration)
        }

        let urlRequest = try await requestClosure(_requestEndpoint)

        return try await performRequestData(endpoint, requestToken: requestToken, request: urlRequest, progress: progress)
    }

    func requestEndpoint(_ token: Endpoint) throws -> RequestEndpoint {
        try requestEndpointClosure(self, token)
    }
    
}
