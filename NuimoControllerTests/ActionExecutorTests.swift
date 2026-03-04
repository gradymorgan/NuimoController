import Testing
import CoreGraphics
import Carbon.HIToolbox
@testable import NuimoController

struct KeystrokeExecutorTests {

    @Test func postsKeyDownAndKeyUp() {
        let poster = MockEventPoster()
        let executor = KeystrokeExecutor(poster: poster)

        executor.execute(keyCode: CGKeyCode(kVK_Space), modifiers: [])

        #expect(poster.postedKeys.count == 2)
        #expect(poster.postedKeys[0].keyDown == true)
        #expect(poster.postedKeys[1].keyDown == false)
        #expect(poster.postedKeys[0].keyCode == CGKeyCode(kVK_Space))
    }

    @Test func postsCorrectModifiers() {
        let poster = MockEventPoster()
        let executor = KeystrokeExecutor(poster: poster)

        let mods: CGEventFlags = [.maskCommand, .maskShift]
        executor.execute(keyCode: CGKeyCode(kVK_Tab), modifiers: mods)

        #expect(poster.postedKeys[0].modifiers.contains(.maskCommand))
        #expect(poster.postedKeys[0].modifiers.contains(.maskShift))
    }
}

struct ScrollExecutorTests {

    @Test func scrollDown() {
        let poster = MockScrollPoster()
        let executor = ScrollExecutor(poster: poster)

        executor.execute(direction: .down, speed: 1.0)

        #expect(poster.postedScrolls.count == 1)
        #expect(poster.postedScrolls[0].deltaY < 0) // Negative = down
        #expect(poster.postedScrolls[0].deltaX == 0)
    }

    @Test func scrollUp() {
        let poster = MockScrollPoster()
        let executor = ScrollExecutor(poster: poster)

        executor.execute(direction: .up, speed: 1.0)

        #expect(poster.postedScrolls.count == 1)
        #expect(poster.postedScrolls[0].deltaY > 0) // Positive = up
    }

    @Test func scrollWithSpeedMultiplier() {
        let poster = MockScrollPoster()
        let executor = ScrollExecutor(poster: poster)

        executor.execute(direction: .down, speed: 2.0, rawDelta: 10)

        #expect(poster.postedScrolls[0].deltaY == -20) // 10 * 2.0
    }

    @Test func scrollLeft() {
        let poster = MockScrollPoster()
        let executor = ScrollExecutor(poster: poster)

        executor.execute(direction: .left, speed: 1.0)

        #expect(poster.postedScrolls[0].deltaX > 0)
        #expect(poster.postedScrolls[0].deltaY == 0)
    }

    @Test func scrollRight() {
        let poster = MockScrollPoster()
        let executor = ScrollExecutor(poster: poster)

        executor.execute(direction: .right, speed: 1.0)

        #expect(poster.postedScrolls[0].deltaX < 0)
    }
}

struct ShellExecutorTests {

    @Test func executorDoesNotCrash() {
        let executor = ShellExecutor()
        // Just verify it doesn't throw/crash
        executor.execute(command: "echo test")
    }
}

struct ActionExecutorFacadeTests {

    @Test func executesKeystrokeAction() {
        let poster = MockEventPoster()
        let keystrokeExec = KeystrokeExecutor(poster: poster)
        let executor = ActionExecutor(keystrokeExecutor: keystrokeExec)

        executor.execute(.keystroke(key: CGKeyCode(kVK_Space), modifiers: []))
        #expect(poster.postedKeys.count == 2)
    }

    @Test func executesScrollAction() {
        let scrollPoster = MockScrollPoster()
        let scrollExec = ScrollExecutor(poster: scrollPoster)
        let executor = ActionExecutor(scrollExecutor: scrollExec)

        executor.execute(.scroll(direction: .down, speed: 1.5))
        #expect(scrollPoster.postedScrolls.count == 1)
    }

    @Test func executesNoneAction() {
        let executor = ActionExecutor()
        // Should not crash or produce side effects
        executor.execute(NuimoAction.none)
    }
}
