// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CinemaTVKit",
    defaultLocalization: "en",
    platforms: [
        .iOS("27.0"),
        // macOS listado para permitir `swift test` no host e preparar o
        // futuro target macOS do redesign. 27.0 porque o DS usa
        // AsyncImage(request:)/asyncImageURLSession, APIs de macOS 27.
        .macOS("27.0")
    ],
    products: [
        .library(name: "CinemaTVCore", targets: ["CinemaTVCore"]),
        .library(name: "CinemaTVDesignSystem", targets: ["CinemaTVDesignSystem"])
    ],
    targets: [
        // Domínio, networking (TMDBClient), persistência (SwiftData) e stores.
        // Sem UIKit: compartilhável com widget hoje e macOS/visionOS no futuro.
        .target(
            name: "CinemaTVCore",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        // Tokens + componentes SwiftUI puros, dirigidos por size classes.
        .target(
            name: "CinemaTVDesignSystem",
            dependencies: ["CinemaTVCore"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self)
            ]
        ),
        .testTarget(
            name: "CinemaTVCoreTests",
            dependencies: ["CinemaTVCore"]
        )
    ]
)
