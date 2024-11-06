import Foundation

public struct FullbackPlugin: PluginType {
    public typealias Provider = AsyncNetworkProvider<AnyEndpoint>

    private let _provider: Provider

    public init(
        backupServer: URL,
        session: Session = AsyncNetworkProviderTypeDefaultImplementation.defaultAlamofireSession(),
        requestEndpointClosure: @escaping Provider.RequestEndpointClosure = AsyncNetworkProviderTypeDefaultImplementation.defaultEndpointMapping,
        requestClosure: @escaping Provider.RequestClosure = AsyncNetworkProviderTypeDefaultImplementation.defaultRequestMapping,
        plugins: [PluginType] = []
    ) {
        _provider = .init(baseURL: backupServer, session: session, requestEndpointClosure: requestEndpointClosure, requestClosure: requestClosure, plugins: plugins)
    }

    public func process(_ result: Result<Response, AsyncNetworkError>, endpoint: any EndpointType, configuration: RequestingConfiguration) async throws -> Response {
        do {
            return try result.get()
        } catch {
            return try await _provider.requestAsync(endpoint.eraseToAnyEndpoint(), requestToken: configuration.requestToken, progress: configuration.progress)
        }
    }
}
