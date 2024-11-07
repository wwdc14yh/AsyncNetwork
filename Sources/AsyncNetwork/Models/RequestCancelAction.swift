import Alamofire
import Foundation

public actor RequestToken: Sendable {
    public static var `default`: RequestToken { .init() }

    private weak var _request: Request?

    public var isCancelled: Bool { _request?.isCancelled ?? false }

    public var isSuspended: Bool { _request?.isSuspended ?? false }

    public var isResumed: Bool { _request?.isResumed ?? false }

    public init() {}

    public func cancel() async {
        guard !isCancelled else { return }
        _request?.cancel()
    }

    public func suspend() async {
        guard !isSuspended else { return }
        _request?.suspend()
    }

    public func resume() async {
        guard !isResumed else { return }
        _request?.resume()
    }

    func setReqeuest(_ request: Request) {
        _request = request
    }
}
