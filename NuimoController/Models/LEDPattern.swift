import Foundation

struct LEDPattern: Sendable {
    let bitmap: [UInt8] // 11 bytes for 81 LEDs

    /// Parse a 9x9 grid string (rows of '0' and '1') into an 11-byte bitmap.
    /// Bits are packed LSB-first per byte, row-major order.
    init?(from gridString: String) {
        let rows = gridString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard rows.count == 9 else { return nil }
        guard rows.allSatisfy({ $0.count == 9 }) else { return nil }

        var bits = [Bool]()
        for row in rows {
            for char in row {
                guard char == "0" || char == "1" else { return nil }
                bits.append(char == "1")
            }
        }

        guard bits.count == 81 else { return nil }

        // Pack 81 bits into 11 bytes, LSB first per byte
        var bytes = [UInt8](repeating: 0, count: 11)
        for (index, isOn) in bits.enumerated() {
            if isOn {
                let byteIndex = index / 8
                let bitIndex = index % 8
                bytes[byteIndex] |= (1 << bitIndex)
            }
        }

        self.bitmap = bytes
    }

    init(bitmap: [UInt8]) {
        precondition(bitmap.count == 11)
        self.bitmap = bitmap
    }
}
