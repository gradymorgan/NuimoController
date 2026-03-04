import Foundation
import os.log

final class EncoderAccumulator: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "EncoderAccumulator")

    private let windowInterval: TimeInterval
    private var accumulatedDelta: Int16 = 0
    private var timer: Timer?
    private var onFlush: ((NuimoEvent) -> Void)?

    init(windowInterval: TimeInterval = 0.05) {
        self.windowInterval = windowInterval
    }

    func setFlushHandler(_ handler: @escaping (NuimoEvent) -> Void) {
        onFlush = handler
    }

    func accumulate(_ event: NuimoEvent) {
        switch event {
        case .rotateClockwise(let delta):
            accumulatedDelta += delta
            scheduleFlush()
        case .rotateCounterClockwise(let delta):
            accumulatedDelta -= delta
            scheduleFlush()
        default:
            break
        }
    }

    func flush() {
        timer?.invalidate()
        timer = nil

        guard accumulatedDelta != 0 else { return }

        let event: NuimoEvent
        if accumulatedDelta > 0 {
            event = .rotateClockwise(delta: accumulatedDelta)
        } else {
            event = .rotateCounterClockwise(delta: -accumulatedDelta)
        }

        accumulatedDelta = 0
        onFlush?(event)
    }

    private func scheduleFlush() {
        timer?.invalidate()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: self.windowInterval, repeats: false) { [weak self] _ in
                self?.flush()
            }
        }
    }
}
