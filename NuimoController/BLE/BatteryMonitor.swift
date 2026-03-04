import Foundation
import os.log

final class BatteryMonitor: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "BatteryMonitor")

    private(set) var batteryLevel: UInt8 = 0
    private(set) var isLowBattery: Bool = false

    static let lowBatteryThreshold: UInt8 = 15

    var onBatteryUpdate: ((UInt8) -> Void)?

    func updateLevel(_ level: UInt8) {
        batteryLevel = level
        isLowBattery = level <= Self.lowBatteryThreshold
        logger.info("Battery: \(level)%\(self.isLowBattery ? " (LOW)" : "")")
        onBatteryUpdate?(level)
    }

    var displayString: String {
        "\(batteryLevel)%"
    }
}
