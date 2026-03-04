import Testing
import AppKit
@testable import NuimoController

@MainActor
struct SleepWakeHandlerTests {

    @Test func sleepCallbackInvoked() {
        let handler = SleepWakeHandler()
        var sleepCalled = false
        handler.onSleep = { sleepCalled = true }
        handler.startObserving()

        NotificationCenter.default.post(
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        // The handler uses NSWorkspace.shared.notificationCenter, not default.
        // Post on the correct center:
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        #expect(sleepCalled == true)
        #expect(handler.isSleeping == true)
    }

    @Test func wakeCallbackInvoked() {
        let handler = SleepWakeHandler()
        var wakeCalled = false
        handler.onWake = { wakeCalled = true }
        handler.startObserving()

        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        #expect(wakeCalled == true)
        #expect(handler.isSleeping == false)
    }

    @Test func sleepThenWakeSequence() {
        let handler = SleepWakeHandler()
        var events: [String] = []
        handler.onSleep = { events.append("sleep") }
        handler.onWake = { events.append("wake") }
        handler.startObserving()

        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        #expect(handler.isSleeping == true)

        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        #expect(handler.isSleeping == false)
        #expect(events == ["sleep", "wake"])
    }

    @Test func stopObservingPreventsCallbacks() {
        let handler = SleepWakeHandler()
        var called = false
        handler.onSleep = { called = true }
        handler.startObserving()
        handler.stopObserving()

        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        #expect(called == false)
    }
}
