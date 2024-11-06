import Foundation

public struct RequestingConfiguration: Sendable {
    public let requestToken: RequestToken?
    public let progress: ProgressAction?

    init(_ requestToken: RequestToken?, _ progress: ProgressAction?) {
        self.requestToken = requestToken
        self.progress = progress
    }
}
