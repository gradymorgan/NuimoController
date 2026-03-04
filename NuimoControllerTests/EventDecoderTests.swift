import Testing
import Foundation
import CoreBluetooth
@testable import NuimoController

struct EventDecoderTests {

    // MARK: - Gesture characteristic

    @Test func decodeFlyLeft() {
        let data = Data([0x00, 0x00])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.gestureChar)
        #expect(event == .flyLeft)
    }

    @Test func decodeFlyRight() {
        let data = Data([0x01, 0x00])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.gestureChar)
        #expect(event == .flyRight)
    }

    @Test func decodeProximity() {
        let data = Data([0x04, 0x80])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.gestureChar)
        #expect(event == .proximity(distance: 128))
    }

    @Test func decodeProximityZero() {
        let data = Data([0x04, 0x00])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.gestureChar)
        #expect(event == .proximity(distance: 0))
    }

    @Test func decodeProximityMax() {
        let data = Data([0x04, 0xFF])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.gestureChar)
        #expect(event == .proximity(distance: 255))
    }

    @Test func decodeUnknownGestureReturnsNil() {
        let data = Data([0x05, 0x00])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.gestureChar)
        #expect(event == nil)
    }

    // MARK: - Touch characteristic

    @Test func decodeSwipeLeft() {
        let data = Data([0x00])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.touchChar)
        #expect(event == .swipeLeft)
    }

    @Test func decodeSwipeRight() {
        let data = Data([0x01])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.touchChar)
        #expect(event == .swipeRight)
    }

    @Test func decodeSwipeUp() {
        let data = Data([0x02])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.touchChar)
        #expect(event == .swipeUp)
    }

    @Test func decodeSwipeDown() {
        let data = Data([0x03])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.touchChar)
        #expect(event == .swipeDown)
    }

    @Test func decodeTouchBottom() {
        let data = Data([0x07])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.touchChar)
        #expect(event == .touchBottom)
    }

    @Test func decodeLongTouchBottom() {
        let data = Data([0x0B])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.touchChar)
        #expect(event == .longTouchBottom)
    }

    @Test func decodeAllTouchValues() {
        let expected: [UInt8: NuimoEvent] = [
            0: .swipeLeft, 1: .swipeRight, 2: .swipeUp, 3: .swipeDown,
            4: .touchLeft, 5: .touchRight, 6: .touchTop, 7: .touchBottom,
            8: .longTouchLeft, 9: .longTouchRight, 10: .longTouchTop, 11: .longTouchBottom,
        ]
        for (byte, expectedEvent) in expected {
            let event = EventDecoder.decode(data: Data([byte]), characteristicUUID: NuimoUUID.touchChar)
            #expect(event == expectedEvent)
        }
    }

    // MARK: - Encoder characteristic

    @Test func decodeEncoderClockwise() {
        // +5 in little-endian Int16: [0x05, 0x00]
        let data = Data([0x05, 0x00])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.encoderChar)
        #expect(event == .rotateClockwise(delta: 5))
    }

    @Test func decodeEncoderCounterClockwise() {
        // -5 in little-endian Int16: [0xFB, 0xFF]
        let data = Data([0xFB, 0xFF])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.encoderChar)
        #expect(event == .rotateCounterClockwise(delta: 5))
    }

    @Test func decodeEncoderZeroReturnsNil() {
        let data = Data([0x00, 0x00])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.encoderChar)
        #expect(event == nil)
    }

    // MARK: - Button characteristic

    @Test func decodeButtonPress() {
        let data = Data([0x01])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.buttonChar)
        #expect(event == .buttonPress)
    }

    @Test func decodeButtonRelease() {
        let data = Data([0x00])
        let event = EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.buttonChar)
        #expect(event == .buttonRelease)
    }

    // MARK: - Edge cases

    @Test func emptyDataReturnsNil() {
        let data = Data()
        #expect(EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.gestureChar) == nil)
        #expect(EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.touchChar) == nil)
        #expect(EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.encoderChar) == nil)
        #expect(EventDecoder.decode(data: data, characteristicUUID: NuimoUUID.buttonChar) == nil)
    }

    @Test func unknownCharacteristicReturnsNil() {
        let data = Data([0x01])
        let event = EventDecoder.decode(data: data, characteristicUUID: CBUUID(string: "FFFF"))
        #expect(event == nil)
    }
}
