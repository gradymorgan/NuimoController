import Testing
import Foundation
@testable import NuimoController

struct LEDPatternTests {

    @Test func parseValidPattern() {
        let grid = """
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        """
        let pattern = LEDPattern(from: grid)
        #expect(pattern != nil)
        #expect(pattern?.bitmap == [UInt8](repeating: 0, count: 11))
    }

    @Test func parseAllOnesPattern() {
        let grid = """
        111111111
        111111111
        111111111
        111111111
        111111111
        111111111
        111111111
        111111111
        111111111
        """
        let pattern = LEDPattern(from: grid)
        #expect(pattern != nil)
        // 81 bits all set: first 10 bytes = 0xFF, byte 10 has bit 0 set = 0x01
        if let bitmap = pattern?.bitmap {
            for i in 0..<10 { #expect(bitmap[i] == 0xFF) }
            #expect(bitmap[10] == 0x01) // Only bit 0 (the 81st LED)
        }
    }

    @Test func parseSingleLEDTopLeft() {
        let grid = """
        100000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        """
        let pattern = LEDPattern(from: grid)
        #expect(pattern != nil)
        #expect(pattern?.bitmap[0] == 0x01) // bit 0 of byte 0
    }

    @Test func parseSingleLEDPosition8() {
        // Position (0,8) = index 8 = bit 0 of byte 1
        let grid = """
        000000001
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        """
        let pattern = LEDPattern(from: grid)
        #expect(pattern != nil)
        #expect(pattern?.bitmap[0] == 0x00)
        #expect(pattern?.bitmap[1] == 0x01) // bit 0 of byte 1
    }

    @Test func parseSingleLEDBottomRight() {
        // Position (8,8) = index 80 = bit 0 of byte 10
        let grid = """
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000001
        """
        let pattern = LEDPattern(from: grid)
        #expect(pattern != nil)
        #expect(pattern?.bitmap[10] == 0x01) // bit 0 of byte 10
    }

    @Test func invalidPatternWrongRowCount() {
        let grid = """
        000000000
        000000000
        """
        #expect(LEDPattern(from: grid) == nil)
    }

    @Test func invalidPatternWrongColumnCount() {
        let grid = """
        00000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        """
        #expect(LEDPattern(from: grid) == nil)
    }

    @Test func invalidPatternBadCharacter() {
        let grid = """
        00000000X
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        000000000
        """
        #expect(LEDPattern(from: grid) == nil)
    }

    @Test func arrowLeftPatternFromConfig() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        let patternString = config.ledPatterns["arrow_left"]
        #expect(patternString != nil)
        let pattern = LEDPattern(from: patternString!)
        #expect(pattern != nil)
    }
}
