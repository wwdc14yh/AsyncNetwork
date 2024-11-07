import Foundation

public struct NetworkLoggerPlugin: PluginType {
    public static var `default`: NetworkLoggerPlugin { NetworkLoggerPlugin(configuration: Configuration(logOptions: .default)) }
    public static var verbose: NetworkLoggerPlugin { NetworkLoggerPlugin(configuration: Configuration(logOptions: .verbose)) }

    let _configuration: Configuration

    /// Initializes a NetworkLoggerPlugin.
    public init(configuration: Configuration = Configuration()) {
        _configuration = configuration
    }

    public func willSend(_ request: any RequestType, endpoint: any EndpointType, configuration: RequestingConfiguration) {
        logNetworkRequest(request, endpoint: endpoint) {
            _configuration.output(endpoint, $0)
        }
    }

    public func didReceive(_ result: Result<Response, AsyncNetworkError>, endpoint: EndpointType, configuration: RequestingConfiguration) {
        switch result {
        case let .success(response):
            _configuration.output(endpoint, logNetworkResponse(response, endpoint: endpoint, isFromError: false))
        case let .failure(error):
            _configuration.output(endpoint, logNetworkError(error, endpoint: endpoint))
        }
    }
}

// MARK: - Configuration
public extension NetworkLoggerPlugin {
    struct Configuration: Sendable {
        public typealias OutputType = @Sendable (_ endpoint: EndpointType, _ items: [String]) -> Void

        public var formatter: Formatter
        public var output: OutputType
        public var logOptions: LogOptions

        /// The designated way to instantiate a Configuration.
        ///
        /// - Parameters:
        ///   - formatter: An object holding all formatter closures available for customization.
        ///   - output: A closure responsible for writing the given log entries into your log system.
        ///                    The default value writes entries to the debug console.
        ///   - logOptions: A set of options you can use to customize which request component is logged.
        public init(
            formatter: Formatter = Formatter(),
            output: @escaping OutputType = defaultOutput,
            logOptions: LogOptions = .default
        ) {
            self.formatter = formatter
            self.output = output
            self.logOptions = logOptions
        }

        public static func defaultOutput(endpoint: EndpointType, items: [String]) {
            for item in items {
                print(item, separator: ",", terminator: "\n")
            }
        }
    }
}

// MARK: - Configuration
public extension NetworkLoggerPlugin {
    struct LogOptions: OptionSet, Sendable {
        /// The request's method will be logged.
        public static let requestMethod = LogOptions(rawValue: 1 << 0)
        /// The request's body will be logged.
        public static let requestBody = LogOptions(rawValue: 1 << 1)
        /// The request's headers will be logged.
        public static let requestHeaders = LogOptions(rawValue: 1 << 2)
        /// The request will be logged in the cURL format.
        ///
        /// If this option is used, the following components will be logged regardless of their respective options being set:
        /// - request's method
        /// - request's headers
        /// - request's body.
        public static let formatRequestAscURL = LogOptions(rawValue: 1 << 3)
        /// The body of a response that is a success will be logged.
        public static let successResponseBody = LogOptions(rawValue: 1 << 4)
        /// The body of a response that is an error will be logged.
        public static let errorResponseBody = LogOptions(rawValue: 1 << 5)

        /// Aggregate options
        /// Only basic components will be logged.
        public static let `default`: LogOptions = [requestMethod, requestHeaders]
        /// All components will be logged.
        public static let verbose: LogOptions = [requestMethod, requestHeaders, requestBody,
                                                 successResponseBody, errorResponseBody]

        public let rawValue: Int

        public init(rawValue: Int) { self.rawValue = rawValue }
    }
}

// MARK: - Formatter
public extension NetworkLoggerPlugin.Configuration {
    struct Formatter: Sendable {
        public typealias DataFormatterType = @Sendable (Data) -> (String)
        public typealias EntryFormatterType = @Sendable (_ identifier: String, _ message: String, _ endpoint: EndpointType) -> String

        static let defaultEntryDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            return formatter
        }()

        public var entry: EntryFormatterType
        public var requestData: DataFormatterType
        public var responseData: DataFormatterType

        /// The designated way to instantiate a Formatter.
        ///
        /// - Parameters:
        ///   - entry: The closure formatting a message into a new log entry.
        ///   - requestData: The closure converting HTTP request's body into a String.
        ///     The default value assumes the body's data is an utf8 String.
        ///   - responseData: The closure converting HTTP response's body into a String.
        ///     The default value assumes the body's data is an utf8 String.
        public init(
            entry: @escaping EntryFormatterType = defaultEntryFormatter,
            requestData: @escaping DataFormatterType = defaultDataFormatter,
            responseData: @escaping DataFormatterType = defaultDataFormatter
        ) {
            self.entry = entry
            self.requestData = requestData
            self.responseData = responseData
        }

        public static func defaultDataFormatter(_ data: Data) -> String {
            return String(data: data, encoding: .utf8) ?? "## Cannot map data to String ##"
        }

        public static func defaultEntryFormatter(identifier: String, message: String, endpoint: EndpointType) -> String {
            let date = defaultEntryDateFormatter.string(from: Date())
            return "AsyncNetwork_Logger: [\(date)] \(identifier): \(message)"
        }
    }
}

extension NetworkLoggerPlugin {
    private func logNetworkRequest(_ request: RequestType, endpoint: EndpointType, completion: @Sendable @escaping ([String]) -> Void) {
        // cURL formatting
        if _configuration.logOptions.contains(.formatRequestAscURL) {
            _ = request.cURLDescription { output in
                completion([self._configuration.formatter.entry("Request", output, endpoint)])
            }
            return
        }

        // Request presence check
        guard let httpRequest = request.request else {
            completion([_configuration.formatter.entry("Request", "(invalid request)", endpoint)])
            return
        }

        // Adding log entries for each given log option
        var output = [String]()

        output.append(_configuration.formatter.entry("Request", httpRequest.description, endpoint))

        if _configuration.logOptions.contains(.requestHeaders) {
            var allHeaders = request.sessionHeaders
            if let httpRequestHeaders = httpRequest.allHTTPHeaderFields {
                allHeaders.merge(httpRequestHeaders) { $1 }
            }
            output.append(_configuration.formatter.entry("Request Headers", allHeaders.description, endpoint))
        }

        if _configuration.logOptions.contains(.requestBody) {
            if let bodyStream = httpRequest.httpBodyStream {
                output.append(_configuration.formatter.entry("Request Body Stream", bodyStream.description, endpoint))
            }

            if let body = httpRequest.httpBody {
                let stringOutput = _configuration.formatter.requestData(body)
                output.append(_configuration.formatter.entry("Request Body", stringOutput, endpoint))
            }
        }

        if _configuration.logOptions.contains(.requestMethod),
           let httpMethod = httpRequest.httpMethod {
            output.append(_configuration.formatter.entry("HTTP Request Method", httpMethod, endpoint))
        }

        completion(output)
    }

    private func logNetworkResponse(_ response: Response, endpoint: EndpointType, isFromError: Bool) -> [String] {
        // Adding log entries for each given log option
        var output = [String]()

        // Response presence check
        if let httpResponse = response.response {
            output.append(_configuration.formatter.entry("Response", httpResponse.description, endpoint))
        } else {
            output.append(_configuration.formatter.entry("Response", "Received empty network response for \(endpoint).", endpoint))
        }

        if (isFromError && _configuration.logOptions.contains(.errorResponseBody))
            || _configuration.logOptions.contains(.successResponseBody) {
            let stringOutput = _configuration.formatter.responseData(response.data)
            output.append(_configuration.formatter.entry("Response Body", stringOutput, endpoint))
        }

        return output
    }

    func logNetworkError(_ error: AsyncNetworkError, endpoint: EndpointType) -> [String] {
        // Some errors will still have a response, like errors due to Alamofire's HTTP code validation.
        if let response = error.response {
            return logNetworkResponse(response, endpoint: endpoint, isFromError: true)
        }

        // Errors without an HTTPURLResponse are those due to connectivity, time-out and such.
        return [_configuration.formatter.entry("Error", "Error calling \(endpoint) : \(error)", endpoint)]
    }
}
