import Testing
import AppKit
@testable import NuimoController

@MainActor
struct StatusBarControllerTests {

    @Test func menuShowsConnectedStatus() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = StatusBarController(statusItem: statusItem)
        controller.updateConnectionState(.connected)
        let menu = controller.buildMenu()
        let status = menu.items.first { $0.tag == MenuItemTag.status.rawValue }
        #expect(status?.title == "Status: Connected")
    }

    @Test func menuShowsDisconnectedStatus() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = StatusBarController(statusItem: statusItem)
        controller.updateConnectionState(.disconnected)
        let menu = controller.buildMenu()
        let status = menu.items.first { $0.tag == MenuItemTag.status.rawValue }
        #expect(status?.title == "Status: Disconnected")
    }

    @Test func menuShowsScanningStatus() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = StatusBarController(statusItem: statusItem)
        controller.updateConnectionState(.scanning)
        let menu = controller.buildMenu()
        let status = menu.items.first { $0.tag == MenuItemTag.status.rawValue }
        #expect(status?.title == "Status: Scanning...")
    }

    @Test func menuShowsBattery() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = StatusBarController(statusItem: statusItem)
        controller.updateBattery(75)
        let menu = controller.buildMenu()
        let batteryItem = menu.items.first { $0.title.contains("Battery") }
        #expect(batteryItem?.title == "Battery: 75%")
    }

    @Test func menuShowsDeviceInfo() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = StatusBarController(statusItem: statusItem)
        controller.updateDeviceInfo(key: "firmware", value: "2.4.1")
        let menu = controller.buildMenu()
        let fwItem = menu.items.first { $0.title.contains("Firmware") }
        #expect(fwItem?.title == "Firmware: 2.4.1")
    }

    @Test func menuHasOpenConfigItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let controller = StatusBarController(statusItem: statusItem)
        let menu = controller.buildMenu()
        let openItem = menu.items.first { $0.title == "Open Config File" }
        #expect(openItem != nil)
    }
}

struct BatteryMonitorTests {

    @Test func initialLevel() {
        let monitor = BatteryMonitor()
        #expect(monitor.batteryLevel == 0)
    }

    @Test func updateLevel() {
        let monitor = BatteryMonitor()
        monitor.updateLevel(75)
        #expect(monitor.batteryLevel == 75)
        #expect(monitor.displayString == "75%")
    }

    @Test func lowBatteryDetection() {
        let monitor = BatteryMonitor()
        monitor.updateLevel(15)
        #expect(monitor.isLowBattery == true)

        monitor.updateLevel(16)
        #expect(monitor.isLowBattery == false)
    }

    @Test func callbackInvoked() {
        let monitor = BatteryMonitor()
        var received: UInt8?
        monitor.onBatteryUpdate = { level in received = level }
        monitor.updateLevel(50)
        #expect(received == 50)
    }
}
