//
//  File.swift
//  AsyncNetworkProvider
//
//  Created by y H on 2024/11/3.
//

import Alamofire
import Foundation

public typealias ProgressHandler = Alamofire.Request.ProgressHandler

public struct ProgressAction: Sendable {
    let queue: DispatchQueue
    let handler: ProgressHandler
    
    public init(queue: DispatchQueue = .main, handler: @escaping ProgressHandler) {
        self.queue = queue
        self.handler = handler
    }
}
