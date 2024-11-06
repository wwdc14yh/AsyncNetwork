//
//  Test.swift
//  AsyncNetwork
//
//  Created by y H on 2024/11/6.
//

import Testing
import Foundation
@testable import AsyncNetwork

struct UploadTests {
    let session = AsyncNetworkProvider<RequestBody>(baseURL: URL(string: "https://httpbin.org")!, plugins: [NetworkLoggerPlugin.verbose])
    
    @Test
    func uploadFromURL() async throws {
        let testFileURL = Bundle.test.url(forResource: "test_file", withExtension: "json")!
        _ = try await session.requestAsync(.uploadFromURL(testFileURL))
    }
    
    @Test
    func uploadingMultipartForm() async throws {
        let fileURLs = [Bundle.test.url(forResource: "rainbow", withExtension: "jpg")!, Bundle.test.url(forResource: "unicorn", withExtension: "png")!]
        let uploadFiles = fileURLs.enumerated().map { MultipartFormData(provider: .file($0.element), name: "name_\($0.offset)", fileName: "fileName_\($0.offset)", mimeType: nil)}
        _ = try await session.requestAsync(.uploadMultipartFormData(uploadFiles, urlParameters: ["t": "a"]))
    }

}
