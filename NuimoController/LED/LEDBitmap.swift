import Foundation

struct LEDBitmap: Sendable {

    /// Build the 13-byte LED write payload.
    /// - Parameters:
    ///   - pattern: The 11-byte LED bitmap (81 LEDs)
    ///   - brightness: LED brightness 0-255
    ///   - duration: Display duration in seconds (0-25.5)
    ///   - onionSkinning: Enable onion skinning effect
    static func buildPayload(
        pattern: LEDPattern,
        brightness: UInt8,
        duration: Double,
        onionSkinning: Bool
    ) -> Data {
        var bytes = pattern.bitmap // 11 bytes

        // Set flags in byte 10 upper bits
        if onionSkinning {
            bytes[10] |= (1 << 4) // bit 5 (0-indexed bit 4)
        }

        // Byte 11: brightness
        bytes.append(brightness)

        // Byte 12: duration (value × 0.1s)
        let durationByte = UInt8(clamping: Int(duration * 10.0))
        bytes.append(durationByte)

        return Data(bytes)
    }
}
