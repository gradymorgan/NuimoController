import CoreGraphics
import os.log

struct MediaKeyExecutor: Sendable {
    private static let logger = Logger(subsystem: "com.nuimo.controller", category: "MediaKeyExecutor")

    // NX key types for media keys
    private static let NX_KEYTYPE_PLAY: UInt32 = 16
    private static let NX_KEYTYPE_NEXT: UInt32 = 17
    private static let NX_KEYTYPE_PREVIOUS: UInt32 = 18

    func execute(action: MediaAction) {
        let keyType: UInt32
        switch action {
        case .playPause: keyType = Self.NX_KEYTYPE_PLAY
        case .next: keyType = Self.NX_KEYTYPE_NEXT
        case .prev: keyType = Self.NX_KEYTYPE_PREVIOUS
        }

        Self.logger.info("Posting media key: \(action.rawValue)")
        postMediaKey(keyType: keyType, keyDown: true)
        postMediaKey(keyType: keyType, keyDown: false)
    }

    private func postMediaKey(keyType: UInt32, keyDown: Bool) {
        let flags: UInt32 = keyDown ? 0x000A00 : 0x000B00
        let data = Int64((Int64(keyType) << 16) | Int64(flags))

        let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(flags)),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int(data),
            data2: -1
        )

        guard let cgEvent = event?.cgEvent else { return }
        cgEvent.post(tap: .cghidEventTap)
    }
}

import AppKit
