import Foundation

// MARK: - AccessTokenAuthorizable

/// A protocol for controlling the behavior of `AccessTokenPlugin`.
public protocol AccessTokenAuthorizable {
    /// Represents the authorization header to use for requests.
    var authorizationType: AuthorizationType? { get }
}

// MARK: - AuthorizationType

/// An enum representing the header to use with an `AccessTokenPlugin`
public enum AuthorizationType {
    /// The `"Basic"` header.
    case basic

    /// The `"Bearer"` header.
    case bearer

    /// Custom header implementation.
    case custom(String)

    public var value: String {
        switch self {
        case .basic: return "Basic"
        case .bearer: return "Bearer"
        case let .custom(customValue): return customValue
        }
    }
}

public struct AccessTokenPlugin: PluginType {
    public typealias TokenClosure = @Sendable (EndpointType) async throws -> String

    /// A closure returning the access token to be applied in the header.
    public let tokenClosure: TokenClosure

    /**
     Initialize a new `AccessTokenPlugin`.

     - parameters:
     - tokenClosure: A closure returning the token to be applied in the pattern `Authorization: <AuthorizationType> <token>`
     */
    public init(tokenClosure: @escaping TokenClosure) {
        self.tokenClosure = tokenClosure
    }

    public func prepare(_ request: URLRequest, endpoint: any EndpointType, configuration: RequestingConfiguration) async throws -> URLRequest {
        guard let authorizable = endpoint as? AccessTokenAuthorizable,
              let authorizationType = authorizable.authorizationType else { return request }
        let token = try await tokenClosure(endpoint)
        var request = request
        let authValue = authorizationType.value + " " + token
        request.addValue(authValue, forHTTPHeaderField: "Authorization")
        return request
    }
}
