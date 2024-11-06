import Foundation

public struct Response: Sendable, CustomDebugStringConvertible, Equatable {
    public let responseKind: ResponseKind

    /// The status code of the response.
    public let statusCode: Int

    /// The response raw data.
    public let data: Data

    /// The original URLRequest for the response.
    public let request: URLRequest?

    /// The HTTPURLResponse object.
    public let response: HTTPURLResponse?

    /// A text description of the `Response`.
    public var description: String {
        "Status Code: \(statusCode), Data Length: \(data.count)"
    }

    /// A text description of the `Response`. Suitable for debugging.
    public var debugDescription: String { description }

    public init(responseKind: ResponseKind, statusCode: Int, data: Data, request: URLRequest?, response: HTTPURLResponse?) {
        self.responseKind = responseKind
        self.statusCode = statusCode
        self.data = data
        self.request = request
        self.response = response
    }

    init(_ responseKind: ResponseKind) throws(AsyncNetworkError) {
        guard let statusCode = responseKind.statusCode, let data = responseKind.data else {
            if let error = responseKind.error {
                throw .underlying(error, nil)
            } else {
                throw .unexpectedErrorCaptured
            }
        }
        if let error = responseKind.error { throw .underlying(error, .init(responseKind: responseKind, statusCode: statusCode, data: data, request: responseKind.urlRequest, response: responseKind.response)) }
        self.init(responseKind: responseKind, statusCode: statusCode, data: data, request: responseKind.urlRequest, response: responseKind.response)
    }

    public static func == (lhs: Response, rhs: Response) -> Bool {
        lhs.statusCode == rhs.statusCode
            && lhs.data == rhs.data
            && lhs.response == rhs.response
    }
}
