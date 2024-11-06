// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "AsyncNetwork",
                      platforms: [
                          .macOS(.v10_15),
                          .iOS(.v13),
                          .tvOS(.v12),
                          .watchOS(.v4),
                      ],
                      products: [
                          .library(name: "AsyncNetwork",
                                   targets: ["AsyncNetwork"]),
                      ],
                      dependencies: [
                          .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0")),
                      ],
                      targets: [
                          .target(name: "AsyncNetwork",
                                  dependencies: [
                                      .product(name: "Alamofire", package: "Alamofire"),
                                  ]),
                          .testTarget(name: "AsyncNetworkTests",
                                      dependencies: ["AsyncNetwork"],
                                      resources: [.process("Resources")]),
                      ],
                      swiftLanguageModes: [.v6])
