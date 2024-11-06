//
//  Test.swift
//  AsyncNetwork
//
//  Created by y H on 2024/11/6.
//

import Testing
import Foundation
@testable import AsyncNetwork

struct Test {
    @Test
    func fallbackSeriver() async throws {
        let v1 = URL(string: "https://httpbin.v1.org")!
        let v2 = URL(string: "https://httpbin.v2.org")!
        let hb = URL(string: "https://httpbin.org")!
        let session = AsyncNetworkProvider<RequestBody>(baseURL: v1,
                                                        plugins: [FullbackPlugin(backupServer: v2),
                                                                  FullbackPlugin(backupServer: hb)])

        let response = try await session.requestAsync(.get(department: false))
        #expect(response.request?.url?.host() == hb.host())
    }

    @Test
    func mockDataTesting() async throws {
        let session = AsyncNetworkProvider<MockDataAPI>(baseURL: URL(string: "http://127.0.0.1.org")!,
                                                        plugins: [TestableResponsePlugin(),
                                                                  NetworkLoggerPlugin.verbose])
        let response1 = try await session.requestAsync(.test1)
        try #require(response1.mapString() == "{\"age\": 20, \"name\": \"John\"}")

        let response2 = await session.requestAsyncToResult(.test2)
        let isFailure = if case .failure = response2 { true } else { false }
        try #require(isFailure)

        let response3 = try await session.requestAsync(.test3)
        try #require(response3.statusCode == 201)
    }
}

enum MockDataAPI: EndpointType, TestableType {
    case test1, test2, test3

    var path: String {
        String(describing: self)
    }

    var method: AsyncNetwork.HTTPMethod { .post }

    var task: AsyncNetwork.EndpointTask { .requestPlain }

    var headers: AsyncNetwork.HTTPHeader? { nil }

    var statusCode: Int {
        switch self {
        case .test1: return 200
        case .test2: return 404
        case .test3: return 201
        }
    }

    var responseDelay: TimeInterval {
        switch self {
        case .test1:
            return 1000
        case .test2:
            return 10000
        case .test3:
            return 0
        }
    }

    func testData() async throws -> Data {
        switch self {
        case .test1:
            return "{\"age\": 20, \"name\": \"John\"}".data(using: .utf8)!
        case .test2:
            throw NSError(domain: NSURLErrorDomain, code: statusCode)
        case .test3:
            try await Task.sleep(for: .milliseconds(500))
            return Data()
        }
    }
}
