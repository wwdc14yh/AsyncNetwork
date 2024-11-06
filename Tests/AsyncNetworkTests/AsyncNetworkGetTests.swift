//
//  File.swift
//  AsyncNetwork
//
//  Created by y H on 2024/11/5.
//

import Testing
import Foundation
@testable import AsyncNetwork

struct TestingRequestMethod {
    let session = AsyncNetworkProvider<RequestBody>(baseURL: URL(string: "https://httpbin.org")!, plugins: [NetworkLoggerPlugin.verbose])

    @Test("Testing for get method")
    func getTest() async throws {
        let response = try await session.requestAsync(.get(department: false))
        try #require(response.request?.method == .get)
        #expect(response.statusCode == 200)
    }

    @Test("Testing for post method")
    func postTest() async throws {
        let response = try await session.requestAsync(.post(customParameters: ["age": 18, "name": "async.network"]))
        try #require(response.request?.method == .post)
        #expect(response.statusCode == 200)
    }
    
    @Test("Concurrency test")
    func concurrencyTest() async throws {
        async let first = session.requestAsync(.get(department: false))
        async let second = session.requestAsync(.post(customParameters: ["Concurrency": true]))
        let responses = try await (first, second)
        print(responses)
    }
}
