import Testing
import Foundation
@testable import NuimoController

struct EventDispatcherTests {

    @Test func dispatchesSwipeToExecutor() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        let registry = ActionRegistry()
        registry.updateFromConfig(config)
        let executor = MockActionExecutor()
        let dispatcher = EventDispatcher(actionRegistry: registry, actionExecutor: executor)

        dispatcher.dispatch(.swipeLeft)
        #expect(executor.lastAction != nil)
    }

    @Test func dispatchesButtonPressToExecutor() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        let registry = ActionRegistry()
        registry.updateFromConfig(config)
        let executor = MockActionExecutor()
        let dispatcher = EventDispatcher(actionRegistry: registry, actionExecutor: executor)

        dispatcher.dispatch(.buttonPress)
        // Button press maps to keystroke in default config
        guard case .keystroke = executor.lastAction else {
            Issue.record("Expected keystroke, got \(String(describing: executor.lastAction))")
            return
        }
    }

    @Test func unmappedEventDoesNotExecute() throws {
        let config = try ConfigLoader.parse(yaml: "actions: {}")
        let registry = ActionRegistry()
        registry.updateFromConfig(config)
        let executor = MockActionExecutor()
        let dispatcher = EventDispatcher(actionRegistry: registry, actionExecutor: executor)

        dispatcher.dispatch(.swipeLeft)
        #expect(executor.lastAction == nil)
    }
}

struct EncoderAccumulatorTests {

    @Test func singleDeltaFlushed() {
        let accumulator = EncoderAccumulator(windowInterval: 0.0)
        var flushed: NuimoEvent?
        accumulator.setFlushHandler { flushed = $0 }

        accumulator.accumulate(.rotateClockwise(delta: 5))
        accumulator.flush()

        #expect(flushed == .rotateClockwise(delta: 5))
    }

    @Test func multipleDeltasAccumulated() {
        let accumulator = EncoderAccumulator(windowInterval: 0.0)
        var flushed: NuimoEvent?
        accumulator.setFlushHandler { flushed = $0 }

        accumulator.accumulate(.rotateClockwise(delta: 3))
        accumulator.accumulate(.rotateClockwise(delta: 4))
        accumulator.accumulate(.rotateClockwise(delta: 2))
        accumulator.flush()

        #expect(flushed == .rotateClockwise(delta: 9))
    }

    @Test func mixedDirectionsNetOut() {
        let accumulator = EncoderAccumulator(windowInterval: 0.0)
        var flushed: NuimoEvent?
        accumulator.setFlushHandler { flushed = $0 }

        accumulator.accumulate(.rotateClockwise(delta: 10))
        accumulator.accumulate(.rotateCounterClockwise(delta: 3))
        accumulator.flush()

        #expect(flushed == .rotateClockwise(delta: 7))
    }

    @Test func zeroDeltaNotFlushed() {
        let accumulator = EncoderAccumulator(windowInterval: 0.0)
        var flushed: NuimoEvent?
        accumulator.setFlushHandler { flushed = $0 }

        accumulator.accumulate(.rotateClockwise(delta: 5))
        accumulator.accumulate(.rotateCounterClockwise(delta: 5))
        accumulator.flush()

        #expect(flushed == nil)
    }

    @Test func counterClockwiseAccumulation() {
        let accumulator = EncoderAccumulator(windowInterval: 0.0)
        var flushed: NuimoEvent?
        accumulator.setFlushHandler { flushed = $0 }

        accumulator.accumulate(.rotateCounterClockwise(delta: 8))
        accumulator.flush()

        #expect(flushed == .rotateCounterClockwise(delta: 8))
    }

    @Test func flushResetsAccumulator() {
        let accumulator = EncoderAccumulator(windowInterval: 0.0)
        var events = [NuimoEvent]()
        accumulator.setFlushHandler { events.append($0) }

        accumulator.accumulate(.rotateClockwise(delta: 5))
        accumulator.flush()
        accumulator.accumulate(.rotateClockwise(delta: 3))
        accumulator.flush()

        #expect(events.count == 2)
        #expect(events[0] == .rotateClockwise(delta: 5))
        #expect(events[1] == .rotateClockwise(delta: 3))
    }
}
