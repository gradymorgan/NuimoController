import Foundation

final class LEDRateLimiter: @unchecked Sendable {
    private let minimumInterval: TimeInterval
    private var lastWriteTime: Date = .distantPast

    init(minimumInterval: TimeInterval = 0.05) {
        self.minimumInterval = minimumInterval
    }

    /// Returns true if the write should proceed, false if rate-limited.
    func shouldAllow() -> Bool {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastWriteTime)
        if elapsed >= minimumInterval {
            lastWriteTime = now
            return true
        }
        return false
    }

    func reset() {
        lastWriteTime = .distantPast
    }
}
