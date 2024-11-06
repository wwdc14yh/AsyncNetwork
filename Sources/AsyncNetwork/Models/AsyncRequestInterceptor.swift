import Alamofire
import Foundation

final class AsyncRequestInterceptor: RequestInterceptor {
    typealias TransformURLRequest = @Sendable (URLRequest) async throws -> URLRequest
    
    @AsynchronousActor
    var prepare: TransformURLRequest?

    @AsynchronousActor
    var willSend: (@Sendable (URLRequest) -> Void)?

    init(prepare: TransformURLRequest? = nil, willSend: (@Sendable (URLRequest) -> Void)? = nil) {
        self.prepare = prepare
        self.willSend = willSend
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping @Sendable (_ result: Result<URLRequest, any Error>) -> Void) {
        Task {
            do {
                let request = try await prepare?(urlRequest) ?? urlRequest
                await _willSend(request)
                completion(.success(request))
            } catch {
                completion(.failure(error))
            }
        }
    }

    @AsynchronousActor
    func setWillSend(_ willSend: @escaping @Sendable (URLRequest) -> Void) {
        self.willSend = willSend
    }
    
    @AsynchronousActor
    private func _willSend(_ request: URLRequest) {
        willSend?(request)
    }
}
