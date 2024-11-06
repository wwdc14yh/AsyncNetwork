import Foundation
@testable import AsyncNetwork

struct RequestBody: EndpointType {
    var path: String
    
    var method: AsyncNetwork.HTTPMethod
    
    var task: AsyncNetwork.EndpointTask
    
    var headers: AsyncNetwork.HTTPHeader?
    
    init(path: String,
         method: AsyncNetwork.HTTPMethod,
         task: AsyncNetwork.EndpointTask,
         headers: AsyncNetwork.HTTPHeader? = nil) {
        self.path = path
        self.method = method
        self.task = task
        self.headers = headers
    }
}

extension RequestBody {
    static func get(department: Bool) -> Self {
        .init(path: "/get", method: .get, task: .requestParameters(parameters: ["department": department], encoding: URLEncoding.default))
    }
    
    static func post(customParameters: Parameters) -> Self {
        .init(path: "/post", method: .post, task: .requestParameters(parameters: customParameters, encoding: JSONEncoding.default))
    }
    
    static func uploadFromURL(_ fileURL: URL) -> Self {
        .init(path: "/post", method: .post, task: .uploadFile(fileURL))
    }
    
    static func uploadMultipartFormData(_ multipartFormData: [MultipartFormData], urlParameters: Parameters) -> Self {
        .init(path: "/post", method: .post, task: .uploadCompositeMultipart(multipartFormData, urlParameters: urlParameters))
    }
}

protocol TestableType {
    var statusCode: Int { get }
    var responseDelay: TimeInterval { get }
    func testData() async throws -> Data
}

extension TestableType {
    var statusCode: Int { 200 }
    var responseDelay: TimeInterval { 1500 }
}

struct TestableResponsePlugin: PluginType {
    func process(_ result: Result<Response, AsyncNetworkError>, endpoint: any EndpointType, configuration: RequestingConfiguration) async throws -> Response {
        guard let testableEndpoint = endpoint as? TestableType else {
            return try result.get()
        }
        try await Task.sleep(for: .milliseconds(testableEndpoint.responseDelay))
        let data = try await testableEndpoint.testData()
        return Response(responseKind: .none, statusCode: testableEndpoint.statusCode, data: data, request: nil, response: nil)
    }
}

extension Response {
    func mapJSON(failsOnEmptyData: Bool = true) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            if data.isEmpty && !failsOnEmptyData {
                return NSNull()
            }
            throw NSError()
        }
    }

    func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            // Key path was provided, try to parse string at key path
            guard let jsonDictionary = try mapJSON() as? NSDictionary,
                let string = jsonDictionary.value(forKeyPath: keyPath) as? String else {
                throw NSError()
            }
            return string
        } else {
            // Key path was not provided, parse entire response as string
            guard let string = String(data: data, encoding: .utf8) else {
                throw NSError()
            }
            return string
        }
    }
}

extension AsyncNetworkProviderType {
    func requestAsyncToResult(_ endpoint: Endpoint, requestToken: RequestToken? = nil, progress: ProgressAction? = nil) async -> Result<Response, AsyncNetworkError> {
        let result: Result<Response, AsyncNetworkError>
        do {
            result = try .success(await requestAsync(endpoint, requestToken: requestToken, progress: progress))
        } catch {
            result = .failure(error)
        }
        return result
    }
}

extension Bundle {
    static var test: Bundle {
        let bundle: Bundle
        #if SWIFT_PACKAGE
        bundle = Bundle.module
        #else
        bundle = Bundle(for: RequestBody.self)
        #endif

        return bundle
    }
}
