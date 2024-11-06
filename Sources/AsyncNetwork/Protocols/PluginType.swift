import Foundation

/// A Moya Plugin receives callbacks to perform side effects wherever a request is sent or received.
///
/// for example, a plugin may be used to
///     - log network requests
///     - hide and show a network activity indicator
///     - inject additional information into a request
public protocol PluginType: Sendable {
    /// Called to modify a request before sending.
    func prepare(_ request: URLRequest, endpoint: EndpointType, configuration: RequestingConfiguration) async throws -> URLRequest

    /// Called immediately before a request is sent over the network (or stubbed).
    func willSend(_ request: RequestType, endpoint: EndpointType, configuration: RequestingConfiguration)

    /// Called after a response has been received, but before the MoyaProvider has invoked its completion handler.
    func didReceive(_ result: Result<Response, AsyncNetworkError>, endpoint: EndpointType, configuration: RequestingConfiguration)

    /// Called to modify a result before completion.
    func process(_ result: Result<Response, AsyncNetworkError>, endpoint: EndpointType, configuration: RequestingConfiguration) async throws -> Response
}

public extension PluginType {
    func prepare(_ request: URLRequest, endpoint: EndpointType, configuration: RequestingConfiguration) async throws -> URLRequest { request }
    func willSend(_ request: RequestType, endpoint: EndpointType, configuration: RequestingConfiguration) {}
    func didReceive(_ result: Result<Response, AsyncNetworkError>, endpoint: EndpointType, configuration: RequestingConfiguration) {}
    func process(_ result: Result<Response, AsyncNetworkError>, endpoint: EndpointType, configuration: RequestingConfiguration) async throws -> Response { try result.get() }
}

/// Request type used by `willSend` plugin function.
public protocol RequestType: Sendable {
    // Note:
    //
    // We use this protocol instead of the Alamofire request to avoid leaking that abstraction.
    // A plugin should not know about Alamofire at all.

    /// Retrieve an `NSURLRequest` representation.
    var request: URLRequest? { get }

    ///  Additional headers appended to the request when added to the session.
    var sessionHeaders: HTTPHeader { get }

    /// Authenticates the request with a username and password.
    func authenticate(username: String, password: String, persistence: URLCredential.Persistence) -> Self

    /// Authenticates the request with an `NSURLCredential` instance.
    func authenticate(with credential: URLCredential) -> Self

    /// cURL representation of the instance.
    ///
    /// - Returns: The cURL equivalent of the instance.
    func cURLDescription(calling handler: @Sendable @escaping (String) -> Void) -> Self
}
