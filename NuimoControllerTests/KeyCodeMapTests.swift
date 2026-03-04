import Testing
import CoreGraphics
import Carbon.HIToolbox
@testable import NuimoController

struct KeyCodeMapTests {

    @Test func spaceKeyCode() {
        #expect(KeyCodeMap.keyCode(for: "space") == CGKeyCode(kVK_Space))
    }

    @Test func tabKeyCode() {
        #expect(KeyCodeMap.keyCode(for: "tab") == CGKeyCode(kVK_Tab))
    }

    @Test func arrowKeys() {
        #expect(KeyCodeMap.keyCode(for: "up") == CGKeyCode(kVK_UpArrow))
        #expect(KeyCodeMap.keyCode(for: "down") == CGKeyCode(kVK_DownArrow))
        #expect(KeyCodeMap.keyCode(for: "left") == CGKeyCode(kVK_LeftArrow))
        #expect(KeyCodeMap.keyCode(for: "right") == CGKeyCode(kVK_RightArrow))
    }

    @Test func letterKeys() {
        #expect(KeyCodeMap.keyCode(for: "a") == CGKeyCode(kVK_ANSI_A))
        #expect(KeyCodeMap.keyCode(for: "z") == CGKeyCode(kVK_ANSI_Z))
    }

    @Test func caseInsensitive() {
        #expect(KeyCodeMap.keyCode(for: "Space") == CGKeyCode(kVK_Space))
        #expect(KeyCodeMap.keyCode(for: "TAB") == CGKeyCode(kVK_Tab))
    }

    @Test func unknownKeyReturnsNil() {
        #expect(KeyCodeMap.keyCode(for: "nonexistent") == nil)
    }

    @Test func commandModifier() {
        let flags = KeyCodeMap.modifierFlags(for: ["command"])
        #expect(flags.contains(.maskCommand))
    }

    @Test func multipleModifiers() {
        let flags = KeyCodeMap.modifierFlags(for: ["command", "shift"])
        #expect(flags.contains(.maskCommand))
        #expect(flags.contains(.maskShift))
    }

    @Test func allModifiers() {
        let flags = KeyCodeMap.modifierFlags(for: ["command", "shift", "option", "control", "fn"])
        #expect(flags.contains(.maskCommand))
        #expect(flags.contains(.maskShift))
        #expect(flags.contains(.maskAlternate))
        #expect(flags.contains(.maskControl))
        #expect(flags.contains(.maskSecondaryFn))
    }

    @Test func emptyModifiers() {
        let flags = KeyCodeMap.modifierFlags(for: [])
        #expect(flags == CGEventFlags())
    }
}
