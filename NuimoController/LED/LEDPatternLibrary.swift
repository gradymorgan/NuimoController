import Foundation

enum LEDPatternLibrary {
    static let arrowLeft = """
    000010000
    000100000
    001000000
    010000000
    111111111
    010000000
    001000000
    000100000
    000010000
    """

    static let arrowRight = """
    000010000
    000001000
    000000100
    000000010
    111111111
    000000010
    000000100
    000001000
    000010000
    """

    static let arrowUp = """
    000010000
    000111000
    001010100
    010010010
    000010000
    000010000
    000010000
    000010000
    000010000
    """

    static let arrowDown = """
    000010000
    000010000
    000010000
    000010000
    000010000
    010010010
    001010100
    000111000
    000010000
    """

    static let check = """
    000000000
    000000010
    000000100
    000001000
    100010000
    010100000
    001000000
    000000000
    000000000
    """

    static let cross = """
    100000001
    010000010
    001000100
    000101000
    000010000
    000101000
    001000100
    010000010
    100000001
    """

    static let play = """
    000000000
    001000000
    001100000
    001110000
    001111000
    001110000
    001100000
    001000000
    000000000
    """

    static let pause = """
    000000000
    001001000
    001001000
    001001000
    001001000
    001001000
    001001000
    001001000
    000000000
    """

    // Volume bars (levels 0-8)
    static func volumeBar(level: Int) -> String {
        let clamped = max(0, min(8, level))
        var rows = [String]()
        for row in 0..<9 {
            let threshold = 8 - row
            if threshold < clamped {
                rows.append("000010000")
            } else if threshold == clamped {
                rows.append("000010000")
            } else {
                rows.append("000000000")
            }
        }
        return rows.joined(separator: "\n")
    }

    // Brightness bar (similar to volume)
    static func brightnessBar(level: Int) -> String {
        volumeBar(level: level) // Same visual for now
    }

    static let allPatterns: [String: String] = [
        "arrow_left": arrowLeft,
        "arrow_right": arrowRight,
        "arrow_up": arrowUp,
        "arrow_down": arrowDown,
        "check": check,
        "cross": cross,
        "play": play,
        "pause": pause,
    ]
}
