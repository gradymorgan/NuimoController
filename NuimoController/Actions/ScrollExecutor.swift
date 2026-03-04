import CoreGraphics
import os.log

protocol ScrollPoster: Sendable {
    func postScroll(deltaX: Int32, deltaY: Int32)
}

struct SystemScrollPoster: ScrollPoster {
    func postScroll(deltaX: Int32, deltaY: Int32) {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0) else { return }
        event.post(tap: .cgSessionEventTap)
    }
}

struct ScrollExecutor: Sendable {
    private static let logger = Logger(subsystem: "com.nuimo.controller", category: "ScrollExecutor")

    let poster: any ScrollPoster

    init(poster: any ScrollPoster = SystemScrollPoster()) {
        self.poster = poster
    }

    func execute(direction: ScrollDirection, speed: Double, rawDelta: Int16 = 10) {
        let scaledDelta = Int32(Double(rawDelta) * speed)

        let deltaX: Int32
        let deltaY: Int32

        switch direction {
        case .up:    deltaX = 0; deltaY = scaledDelta
        case .down:  deltaX = 0; deltaY = -scaledDelta
        case .left:  deltaX = scaledDelta; deltaY = 0
        case .right: deltaX = -scaledDelta; deltaY = 0
        }

        Self.logger.info("Posting scroll: dx=\(deltaX), dy=\(deltaY)")
        poster.postScroll(deltaX: deltaX, deltaY: deltaY)
    }
}
