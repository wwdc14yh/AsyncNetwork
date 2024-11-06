import Alamofire
import Foundation

public protocol AsyncNetworkProviderType: Sendable {
    associatedtype Endpoint: EndpointType
    var baseURL: URL? { get }
    var session: Session { get }

    func requestAsync(_ endpoint: Endpoint, requestToken: RequestToken?, progress: ProgressAction?) async throws(AsyncNetworkError) -> Response
}

public enum AsyncNetworkProviderTypeDefaultImplementation {
    public static func defaultEndpointMapping(for provider: any AsyncNetworkProviderType, endpoint: any EndpointType) throws -> RequestEndpoint {
        guard let baseURL = provider.baseURL else {
            throw AsyncNetworkError.invalidURL
        }
        let fullURL =
            if #available(macOS 13.0, *) {
                baseURL.appending(path: endpoint.path)
            } else {
                baseURL.appendingPathComponent(endpoint.path, isDirectory: false)
            }
        return RequestEndpoint(url: fullURL.absoluteString,
                               method: endpoint.method,
                               task: endpoint.task,
                               httpHeaderFields: endpoint.headers)
    }

    public static func defaultRequestMapping(_ requestEndpoint: RequestEndpoint) async throws(AsyncNetworkError) -> URLRequest {
        try requestEndpoint.urlRequest()
    }

    public static func defaultAlamofireSession() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        return Session(configuration: configuration)
    }
}
