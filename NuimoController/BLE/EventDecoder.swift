import Foundation
import CoreBluetooth
import os.log

struct EventDecoder: Sendable {
    private static let logger = Logger(subsystem: "com.nuimo.controller", category: "EventDecoder")

    static func decode(data: Data, characteristicUUID: CBUUID) -> NuimoEvent? {
        switch characteristicUUID {
        case NuimoUUID.gestureChar:
            return decodeGesture(data)
        case NuimoUUID.touchChar:
            return decodeTouch(data)
        case NuimoUUID.encoderChar:
            return decodeEncoder(data)
        case NuimoUUID.buttonChar:
            return decodeButton(data)
        default:
            logger.warning("Unknown characteristic UUID: \(characteristicUUID)")
            return nil
        }
    }

    // MARK: - Gesture (0x1526) — 2 bytes unsigned
    // byte[0]: 0=FlyLeft, 1=FlyRight, 4=Proximity
    // byte[1]: proximity distance (0-255)

    private static func decodeGesture(_ data: Data) -> NuimoEvent? {
        guard data.count >= 2 else {
            logger.warning("Gesture data too short: \(data.count) bytes")
            return nil
        }

        let gestureType = data[0]
        switch gestureType {
        case 0: return .flyLeft
        case 1: return .flyRight
        case 4: return .proximity(distance: data[1])
        default:
            logger.warning("Unknown gesture type: \(gestureType)")
            return nil
        }
    }

    // MARK: - Touch (0x1527) — 1 byte unsigned
    // 0-3=Swipe(L/R/U/D), 4-7=Touch(L/R/T/B), 8-11=LongTouch(L/R/T/B)

    private static func decodeTouch(_ data: Data) -> NuimoEvent? {
        guard data.count >= 1 else {
            logger.warning("Touch data too short")
            return nil
        }

        switch data[0] {
        case 0: return .swipeLeft
        case 1: return .swipeRight
        case 2: return .swipeUp
        case 3: return .swipeDown
        case 4: return .touchLeft
        case 5: return .touchRight
        case 6: return .touchTop
        case 7: return .touchBottom
        case 8: return .longTouchLeft
        case 9: return .longTouchRight
        case 10: return .longTouchTop
        case 11: return .longTouchBottom
        default:
            logger.warning("Unknown touch value: \(data[0])")
            return nil
        }
    }

    // MARK: - Encoder (0x1528) — 2 bytes signed Int16 little-endian
    // >0 = Clockwise, <0 = CounterClockwise

    private static func decodeEncoder(_ data: Data) -> NuimoEvent? {
        guard data.count >= 2 else {
            logger.warning("Encoder data too short: \(data.count) bytes")
            return nil
        }

        let value = Int16(littleEndian: data.withUnsafeBytes { $0.load(as: Int16.self) })

        if value > 0 {
            return .rotateClockwise(delta: value)
        } else if value < 0 {
            return .rotateCounterClockwise(delta: -value)
        }
        return nil // delta of 0 = no rotation
    }

    // MARK: - Button (0x1529) — 1 byte unsigned
    // 0=Release, 1=Press

    private static func decodeButton(_ data: Data) -> NuimoEvent? {
        guard data.count >= 1 else {
            logger.warning("Button data too short")
            return nil
        }

        switch data[0] {
        case 0: return .buttonRelease
        case 1: return .buttonPress
        default:
            logger.warning("Unknown button value: \(data[0])")
            return nil
        }
    }
}
