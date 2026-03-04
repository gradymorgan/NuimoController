import Foundation

struct NuimoConfig: Sendable {
    var deviceName: String
    var autoReconnect: Bool
    var reconnectIntervalSeconds: Double

    var ledBrightness: UInt8
    var ledDisplayDuration: Double
    var ledOnionSkinning: Bool

    var actions: [String: ActionConfig]
    var ledPatterns: [String: String]

    static let `default` = NuimoConfig(
        deviceName: "Nuimo",
        autoReconnect: true,
        reconnectIntervalSeconds: 5,
        ledBrightness: 180,
        ledDisplayDuration: 2.0,
        ledOnionSkinning: false,
        actions: [:],
        ledPatterns: [:]
    )
}

struct ActionConfig: Sendable {
    var actionType: String
    var key: String?
    var modifiers: [String]
    var direction: String?
    var speed: Double?
    var command: String?
    var mediaAction: String?
    var appName: String?
    var bundleId: String?
    var ledPattern: String?

    init(
        actionType: String,
        key: String? = nil,
        modifiers: [String] = [],
        direction: String? = nil,
        speed: Double? = nil,
        command: String? = nil,
        mediaAction: String? = nil,
        appName: String? = nil,
        bundleId: String? = nil,
        ledPattern: String? = nil
    ) {
        self.actionType = actionType
        self.key = key
        self.modifiers = modifiers
        self.direction = direction
        self.speed = speed
        self.command = command
        self.mediaAction = mediaAction
        self.appName = appName
        self.bundleId = bundleId
        self.ledPattern = ledPattern
    }
}
