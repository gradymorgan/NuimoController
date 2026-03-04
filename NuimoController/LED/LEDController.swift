import Foundation
import os.log

final class LEDController: LEDControllerProtocol, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "LEDController")

    private let bleManager: BLEManager
    private let rateLimiter: LEDRateLimiter
    private var defaultBrightness: UInt8 = 180
    private var defaultDuration: Double = 2.0
    private var onionSkinning: Bool = false

    init(bleManager: BLEManager, rateLimiter: LEDRateLimiter = LEDRateLimiter()) {
        self.bleManager = bleManager
        self.rateLimiter = rateLimiter
    }

    func updateSettings(brightness: UInt8, duration: Double, onionSkinning: Bool) {
        self.defaultBrightness = brightness
        self.defaultDuration = duration
        self.onionSkinning = onionSkinning
    }

    func showPattern(_ patternString: String, brightness: UInt8, duration: Double) {
        guard rateLimiter.shouldAllow() else {
            logger.debug("LED write rate-limited")
            return
        }

        guard let pattern = LEDPattern(from: patternString) else {
            logger.warning("Invalid LED pattern string")
            return
        }

        let payload = LEDBitmap.buildPayload(
            pattern: pattern,
            brightness: brightness,
            duration: duration,
            onionSkinning: onionSkinning
        )

        bleManager.writeLEDData(payload)
        logger.debug("LED pattern written (\(payload.count) bytes)")
    }

    func showPattern(named name: String) {
        let patternString: String
        if let builtin = LEDPatternLibrary.allPatterns[name] {
            patternString = builtin
        } else {
            logger.warning("Unknown LED pattern: \(name)")
            return
        }

        showPattern(patternString, brightness: defaultBrightness, duration: defaultDuration)
    }
}
