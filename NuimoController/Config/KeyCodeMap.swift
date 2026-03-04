import CoreGraphics
import Carbon.HIToolbox

struct KeyCodeMap: Sendable {

    static let keyNameToCode: [String: CGKeyCode] = [
        // Letters
        "a": CGKeyCode(kVK_ANSI_A), "b": CGKeyCode(kVK_ANSI_B), "c": CGKeyCode(kVK_ANSI_C),
        "d": CGKeyCode(kVK_ANSI_D), "e": CGKeyCode(kVK_ANSI_E), "f": CGKeyCode(kVK_ANSI_F),
        "g": CGKeyCode(kVK_ANSI_G), "h": CGKeyCode(kVK_ANSI_H), "i": CGKeyCode(kVK_ANSI_I),
        "j": CGKeyCode(kVK_ANSI_J), "k": CGKeyCode(kVK_ANSI_K), "l": CGKeyCode(kVK_ANSI_L),
        "m": CGKeyCode(kVK_ANSI_M), "n": CGKeyCode(kVK_ANSI_N), "o": CGKeyCode(kVK_ANSI_O),
        "p": CGKeyCode(kVK_ANSI_P), "q": CGKeyCode(kVK_ANSI_Q), "r": CGKeyCode(kVK_ANSI_R),
        "s": CGKeyCode(kVK_ANSI_S), "t": CGKeyCode(kVK_ANSI_T), "u": CGKeyCode(kVK_ANSI_U),
        "v": CGKeyCode(kVK_ANSI_V), "w": CGKeyCode(kVK_ANSI_W), "x": CGKeyCode(kVK_ANSI_X),
        "y": CGKeyCode(kVK_ANSI_Y), "z": CGKeyCode(kVK_ANSI_Z),

        // Numbers
        "0": CGKeyCode(kVK_ANSI_0), "1": CGKeyCode(kVK_ANSI_1), "2": CGKeyCode(kVK_ANSI_2),
        "3": CGKeyCode(kVK_ANSI_3), "4": CGKeyCode(kVK_ANSI_4), "5": CGKeyCode(kVK_ANSI_5),
        "6": CGKeyCode(kVK_ANSI_6), "7": CGKeyCode(kVK_ANSI_7), "8": CGKeyCode(kVK_ANSI_8),
        "9": CGKeyCode(kVK_ANSI_9),

        // Special keys
        "space": CGKeyCode(kVK_Space),
        "return": CGKeyCode(kVK_Return), "enter": CGKeyCode(kVK_Return),
        "tab": CGKeyCode(kVK_Tab),
        "escape": CGKeyCode(kVK_Escape), "esc": CGKeyCode(kVK_Escape),
        "delete": CGKeyCode(kVK_Delete), "backspace": CGKeyCode(kVK_Delete),
        "forward_delete": CGKeyCode(kVK_ForwardDelete),

        // Arrow keys
        "up": CGKeyCode(kVK_UpArrow),
        "down": CGKeyCode(kVK_DownArrow),
        "left": CGKeyCode(kVK_LeftArrow),
        "right": CGKeyCode(kVK_RightArrow),

        // Function keys
        "f1": CGKeyCode(kVK_F1), "f2": CGKeyCode(kVK_F2), "f3": CGKeyCode(kVK_F3),
        "f4": CGKeyCode(kVK_F4), "f5": CGKeyCode(kVK_F5), "f6": CGKeyCode(kVK_F6),
        "f7": CGKeyCode(kVK_F7), "f8": CGKeyCode(kVK_F8), "f9": CGKeyCode(kVK_F9),
        "f10": CGKeyCode(kVK_F10), "f11": CGKeyCode(kVK_F11), "f12": CGKeyCode(kVK_F12),

        // Navigation
        "home": CGKeyCode(kVK_Home),
        "end": CGKeyCode(kVK_End),
        "page_up": CGKeyCode(kVK_PageUp),
        "page_down": CGKeyCode(kVK_PageDown),

        // Punctuation
        "minus": CGKeyCode(kVK_ANSI_Minus),
        "equal": CGKeyCode(kVK_ANSI_Equal),
        "left_bracket": CGKeyCode(kVK_ANSI_LeftBracket),
        "right_bracket": CGKeyCode(kVK_ANSI_RightBracket),
        "backslash": CGKeyCode(kVK_ANSI_Backslash),
        "semicolon": CGKeyCode(kVK_ANSI_Semicolon),
        "quote": CGKeyCode(kVK_ANSI_Quote),
        "comma": CGKeyCode(kVK_ANSI_Comma),
        "period": CGKeyCode(kVK_ANSI_Period),
        "slash": CGKeyCode(kVK_ANSI_Slash),
        "grave": CGKeyCode(kVK_ANSI_Grave),
    ]

    static let modifierNameToFlag: [String: CGEventFlags] = [
        "command": .maskCommand,
        "shift": .maskShift,
        "option": .maskAlternate,
        "control": .maskControl,
        "fn": .maskSecondaryFn,
    ]

    static func keyCode(for name: String) -> CGKeyCode? {
        keyNameToCode[name.lowercased()]
    }

    static func modifierFlags(for names: [String]) -> CGEventFlags {
        var flags = CGEventFlags()
        for name in names {
            if let flag = modifierNameToFlag[name.lowercased()] {
                flags.insert(flag)
            }
        }
        return flags
    }
}
