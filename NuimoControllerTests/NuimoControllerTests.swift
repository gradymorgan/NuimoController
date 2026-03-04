import Testing
import AppKit
@testable import NuimoController

@MainActor
struct AppDelegateTests {

    @Test func statusBarItemIsCreated() async throws {
        let delegate = AppDelegate()
        let notification = Notification(name: NSApplication.didFinishLaunchingNotification)
        delegate.applicationDidFinishLaunching(notification)
        #expect(delegate.currentStatusItem != nil)
        #expect(delegate.currentStatusItem?.button?.image != nil)
    }

    @Test func menuContainsExpectedItems() async throws {
        let delegate = AppDelegate()
        let menu = delegate.buildMenu()
        let titles = menu.items.map(\.title)
        #expect(titles.contains("Status: Disconnected"))
        #expect(titles.contains("Reconnect"))
        #expect(titles.contains("Reload Config"))
        #expect(titles.contains("Launch at Login"))
        #expect(titles.contains("Quit"))
    }

    @Test func menuHasSeparators() async throws {
        let delegate = AppDelegate()
        let menu = delegate.buildMenu()
        let separatorCount = menu.items.filter(\.isSeparatorItem).count
        #expect(separatorCount == 3)
    }

    @Test func statusMenuItemIsDisabled() async throws {
        let delegate = AppDelegate()
        let menu = delegate.buildMenu()
        let statusItem = menu.items.first { $0.tag == MenuItemTag.status.rawValue }
        #expect(statusItem != nil)
        #expect(statusItem?.isEnabled == false)
    }

    @Test func reconnectMenuItemHasCorrectAction() async throws {
        let delegate = AppDelegate()
        let menu = delegate.buildMenu()
        let item = menu.items.first { $0.title == "Reconnect" }
        #expect(item?.action == #selector(AppDelegate.reconnectClicked))
    }

    @Test func quitMenuItemHasCorrectAction() async throws {
        let delegate = AppDelegate()
        let menu = delegate.buildMenu()
        let item = menu.items.first { $0.title == "Quit" }
        #expect(item?.action == #selector(AppDelegate.quitClicked))
    }

    @Test func launchAtLoginMenuItemExists() async throws {
        let delegate = AppDelegate()
        let menu = delegate.buildMenu()
        let item = menu.items.first { $0.tag == MenuItemTag.launchAtLogin.rawValue }
        #expect(item != nil)
        #expect(item?.title == "Launch at Login")
    }
}

struct ModelTests {

    @Test func nuimoEventConfigKeys() {
        #expect(NuimoEvent.swipeLeft.configKey == "swipe_left")
        #expect(NuimoEvent.swipeRight.configKey == "swipe_right")
        #expect(NuimoEvent.swipeUp.configKey == "swipe_up")
        #expect(NuimoEvent.swipeDown.configKey == "swipe_down")
        #expect(NuimoEvent.buttonPress.configKey == "button_press")
        #expect(NuimoEvent.buttonRelease.configKey == "button_release")
        #expect(NuimoEvent.rotateClockwise(delta: 5).configKey == "rotate_clockwise")
        #expect(NuimoEvent.rotateCounterClockwise(delta: 5).configKey == "rotate_counter_clockwise")
        #expect(NuimoEvent.flyLeft.configKey == "fly_left")
        #expect(NuimoEvent.flyRight.configKey == "fly_right")
        #expect(NuimoEvent.proximity(distance: 128).configKey == "proximity")
        #expect(NuimoEvent.touchLeft.configKey == "touch_left")
        #expect(NuimoEvent.touchRight.configKey == "touch_right")
        #expect(NuimoEvent.touchTop.configKey == "touch_top")
        #expect(NuimoEvent.touchBottom.configKey == "touch_bottom")
    }

    @Test func nuimoEventHashEquality() {
        #expect(NuimoEvent.swipeLeft == NuimoEvent.swipeLeft)
        #expect(NuimoEvent.rotateClockwise(delta: 5) == NuimoEvent.rotateClockwise(delta: 5))
        #expect(NuimoEvent.rotateClockwise(delta: 5) != NuimoEvent.rotateClockwise(delta: 10))
    }

    @Test func scrollDirectionRawValues() {
        #expect(ScrollDirection(rawValue: "up") == .up)
        #expect(ScrollDirection(rawValue: "down") == .down)
        #expect(ScrollDirection(rawValue: "left") == .left)
        #expect(ScrollDirection(rawValue: "right") == .right)
    }

    @Test func mediaActionRawValues() {
        #expect(MediaAction(rawValue: "play_pause") == .playPause)
        #expect(MediaAction(rawValue: "next") == .next)
        #expect(MediaAction(rawValue: "prev") == .prev)
    }
}

struct ProtocolConformanceTests {

    @Test func protocolsCanBeMocked() {
        let _: any BLEManagerProtocol = MockBLEManager()
        let _: any EventDispatcherProtocol = MockEventDispatcher()
        let _: any ConfigLoaderProtocol = MockConfigLoader()
        let _: any ActionExecutorProtocol = MockActionExecutor()
        let _: any LEDControllerProtocol = MockLEDController()
    }
}
