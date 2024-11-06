import Alamofire
import Foundation

struct RequestTypeWrapper: RequestType {
    private var _request: Request
    private var _urlRequest: URLRequest?

    var request: URLRequest? { _urlRequest }

    var sessionHeaders: HTTPHeader { (_request.delegate?.sessionConfiguration.httpAdditionalHeaders as? HTTPHeader) ?? [:] }

    init(request: Request, urlRequest: URLRequest?) {
        _request = request
        _urlRequest = urlRequest
    }

    func authenticate(username: String, password: String, persistence: URLCredential.Persistence) -> RequestTypeWrapper {
        let newRequest = _request.authenticate(username: username, password: password, persistence: persistence)
        return RequestTypeWrapper(request: newRequest, urlRequest: _urlRequest)
    }

    func authenticate(with credential: URLCredential) -> RequestTypeWrapper {
        let newRequest = _request.authenticate(with: credential)
        return RequestTypeWrapper(request: newRequest, urlRequest: _urlRequest)
    }

    func cURLDescription(calling handler: @Sendable @escaping (String) -> Void) -> RequestTypeWrapper {
        _request.cURLDescription(calling: handler)
        return self
    }
}
