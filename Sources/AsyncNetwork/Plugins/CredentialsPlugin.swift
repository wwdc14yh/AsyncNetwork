import Foundation

/// Provides each request with optional URLCredentials.
public struct CredentialsPlugin: PluginType {
    public typealias CredentialClosure = @Sendable (EndpointType) -> URLCredential?
    
    let credentialClosure: CredentialClosure
    
    /// Initializes a CredentialsPlugin.
    public init(credentialClosure: @escaping CredentialClosure) {
        self.credentialClosure = credentialClosure
    }
    
    public func willSend(_ request: any RequestType, endpoint: any EndpointType, configuration: RequestingConfiguration) {
        if let credentials = credentialClosure(endpoint) {
            _ = request.authenticate(with: credentials)
        }
    }
}
