import Foundation

/// Network activity change notification type.
public enum NetworkActivityChangeType {
    case began, ended
}

public struct NetworkActivityPlugin: PluginType {
    public typealias NetworkActivityClosure = @Sendable (_ change: NetworkActivityChangeType, _ endpoint: EndpointType) -> Void

    let networkActivityClosure: NetworkActivityClosure

    /// Initializes a NetworkActivityPlugin.
    public init(networkActivityClosure: @escaping NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    /// Called by the provider as soon as the request is about to start
    public func willSend(_ request: RequestType, endpoint: EndpointType, configuration: RequestingConfiguration) {
        networkActivityClosure(.began, endpoint)
    }

    /// Called by the provider as soon as a response arrives, even if the request is canceled.
    public func didReceive(_ result: Result<Response, AsyncNetworkError>, endpoint: any EndpointType, configuration: RequestingConfiguration) {
        networkActivityClosure(.ended, endpoint)
    }
}
