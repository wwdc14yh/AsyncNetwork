import Alamofire
import Foundation

public enum ResponseKind: Sendable, CustomDebugStringConvertible {
    case dataResponse(AFDataResponse<Data>)
    case downloadResponse(AFDownloadResponse<Data>)
    case none

    public var statusCode: Int? {
        response?.statusCode
    }

    public var response: HTTPURLResponse? {
        switch self {
        case let .dataResponse(response): return response.response
        case let .downloadResponse(response): return response.response
        case .none: return nil
        }
    }

    public var urlRequest: URLRequest? {
        switch self {
        case let .dataResponse(response): return response.request
        case let .downloadResponse(response): return response.request
        case .none: return nil
        }
    }

    public var data: Data? {
        switch self {
        case let .dataResponse(response): return response.data
        case let .downloadResponse(response): return response.value
        case .none: return nil
        }
    }

    public var error: AFError? {
        switch self {
        case let .dataResponse(response): return response.error
        case let .downloadResponse(response): return response.error
        case .none: return nil
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .dataResponse(let aFDataResponse):
            return aFDataResponse.debugDescription
        case .downloadResponse(let aFDownloadResponse):
            return aFDownloadResponse.debugDescription
        case .none:
            return "Empty response."
        }
    }
}

protocol Requestable {
    func response() async -> ResponseKind
}

extension DataRequest: Requestable {
    func response() async -> ResponseKind {
        .dataResponse(await serializingData().response)
    }
}

extension DownloadRequest: Requestable {
    func response() async -> ResponseKind {
        .downloadResponse(await serializingData().response)
    }
}
