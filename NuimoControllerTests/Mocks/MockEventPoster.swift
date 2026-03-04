import CoreGraphics
@testable import NuimoController

final class MockEventPoster: EventPoster, @unchecked Sendable {
    struct PostedKey {
        let keyCode: CGKeyCode
        let modifiers: CGEventFlags
        let keyDown: Bool
    }

    var postedKeys: [PostedKey] = []

    func post(keyCode: CGKeyCode, modifiers: CGEventFlags, keyDown: Bool) {
        postedKeys.append(PostedKey(keyCode: keyCode, modifiers: modifiers, keyDown: keyDown))
    }
}

final class MockScrollPoster: ScrollPoster, @unchecked Sendable {
    struct PostedScroll {
        let deltaX: Int32
        let deltaY: Int32
    }

    var postedScrolls: [PostedScroll] = []

    func postScroll(deltaX: Int32, deltaY: Int32) {
        postedScrolls.append(PostedScroll(deltaX: deltaX, deltaY: deltaY))
    }
}
