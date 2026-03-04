import Testing
import Foundation
@testable import NuimoController

struct LEDBitmapTests {

    @Test func payloadIs13Bytes() {
        let pattern = LEDPattern(bitmap: [UInt8](repeating: 0, count: 11))
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 180, duration: 2.0, onionSkinning: false)
        #expect(payload.count == 13)
    }

    @Test func brightnessInByte11() {
        let pattern = LEDPattern(bitmap: [UInt8](repeating: 0, count: 11))
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 180, duration: 2.0, onionSkinning: false)
        #expect(payload[11] == 180)
    }

    @Test func brightnessMaxValue() {
        let pattern = LEDPattern(bitmap: [UInt8](repeating: 0, count: 11))
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 255, duration: 0, onionSkinning: false)
        #expect(payload[11] == 255)
    }

    @Test func durationInByte12() {
        let pattern = LEDPattern(bitmap: [UInt8](repeating: 0, count: 11))
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 180, duration: 2.0, onionSkinning: false)
        #expect(payload[12] == 20) // 2.0 * 10
    }

    @Test func durationZero() {
        let pattern = LEDPattern(bitmap: [UInt8](repeating: 0, count: 11))
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 0, duration: 0.0, onionSkinning: false)
        #expect(payload[12] == 0)
    }

    @Test func durationMax() {
        let pattern = LEDPattern(bitmap: [UInt8](repeating: 0, count: 11))
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 0, duration: 25.5, onionSkinning: false)
        #expect(payload[12] == 255)
    }

    @Test func onionSkinningSetsBit4InByte10() {
        let pattern = LEDPattern(bitmap: [UInt8](repeating: 0, count: 11))
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 0, duration: 0, onionSkinning: true)
        #expect(payload[10] & (1 << 4) != 0)
    }

    @Test func noOnionSkinningBit4Clear() {
        let pattern = LEDPattern(bitmap: [UInt8](repeating: 0, count: 11))
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 0, duration: 0, onionSkinning: false)
        #expect(payload[10] & (1 << 4) == 0)
    }

    @Test func onionSkinningPreservesLEDBit() {
        // Byte 10 bit 0 is the 81st LED — onion skinning should not clear it
        var bitmap = [UInt8](repeating: 0, count: 11)
        bitmap[10] = 0x01 // 81st LED on
        let pattern = LEDPattern(bitmap: bitmap)
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 0, duration: 0, onionSkinning: true)
        #expect(payload[10] & 0x01 != 0) // LED still on
        #expect(payload[10] & (1 << 4) != 0) // Onion skinning also set
    }

    @Test func bitmapDataPreservedInPayload() {
        var bitmap = [UInt8](repeating: 0, count: 11)
        bitmap[0] = 0xFF
        bitmap[5] = 0xAB
        let pattern = LEDPattern(bitmap: bitmap)
        let payload = LEDBitmap.buildPayload(pattern: pattern, brightness: 100, duration: 1.0, onionSkinning: false)
        #expect(payload[0] == 0xFF)
        #expect(payload[5] == 0xAB)
    }
}

struct LEDRateLimiterTests {

    @Test func firstWriteAllowed() {
        let limiter = LEDRateLimiter(minimumInterval: 1.0)
        #expect(limiter.shouldAllow() == true)
    }

    @Test func rapidWriteBlocked() {
        let limiter = LEDRateLimiter(minimumInterval: 1.0)
        _ = limiter.shouldAllow()
        #expect(limiter.shouldAllow() == false)
    }

    @Test func resetAllowsWrite() {
        let limiter = LEDRateLimiter(minimumInterval: 1.0)
        _ = limiter.shouldAllow()
        limiter.reset()
        #expect(limiter.shouldAllow() == true)
    }

    @Test func zeroIntervalAlwaysAllows() {
        let limiter = LEDRateLimiter(minimumInterval: 0)
        #expect(limiter.shouldAllow() == true)
        #expect(limiter.shouldAllow() == true)
    }
}

struct LEDPatternLibraryTests {

    @Test func allBuiltinPatternsAreValid() {
        for (name, patternString) in LEDPatternLibrary.allPatterns {
            let pattern = LEDPattern(from: patternString)
            #expect(pattern != nil, "Pattern '\(name)' failed to parse")
        }
    }

    @Test func volumeBarLevel0() {
        let bar = LEDPatternLibrary.volumeBar(level: 0)
        let pattern = LEDPattern(from: bar)
        #expect(pattern != nil)
    }

    @Test func volumeBarLevel8() {
        let bar = LEDPatternLibrary.volumeBar(level: 8)
        let pattern = LEDPattern(from: bar)
        #expect(pattern != nil)
    }
}
