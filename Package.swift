// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YoutubePlayer",
    platforms: [.iOS(.v13)],
    products: [ .library(name: "YoutubePlayer", targets: ["YoutubePlayer"]) ],
    targets: [
        .target(name: "YoutubePlayer"),
        .testTarget(name: "youtube-ios-player-helperTests", dependencies: ["YoutubePlayer"]),
    ]
)
