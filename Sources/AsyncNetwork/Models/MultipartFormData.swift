//
//  MultipartFormData.swift
//  AsyncNetworkSession
//
//  Created by y H on 2024/11/2.
//

import Alamofire
import Foundation

public struct MultipartFormData: Sendable, Hashable {
    /// Method to provide the form data.
    public enum FormDataProvider: Hashable, @unchecked Sendable {
        case data(Foundation.Data)
        case file(URL)
        case stream(InputStream, UInt64)
    }
    
    /// The method being used for providing form data.
    public let provider: FormDataProvider

    /// The name.
    public let name: String

    /// The file name.
    public let fileName: String?

    /// The MIME type
    public let mimeType: String?
    
    public init(provider: FormDataProvider, name: String, fileName: String?, mimeType: String?) {
        self.provider = provider
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
