import Foundation
import CoreBluetooth
import os.log

final class EventDispatcher: EventDispatcherProtocol, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "EventDispatcher")

    private let actionRegistry: ActionRegistry
    private let actionExecutor: any ActionExecutorProtocol
    private let encoderAccumulator: EncoderAccumulator

    init(actionRegistry: ActionRegistry, actionExecutor: any ActionExecutorProtocol) {
        self.actionRegistry = actionRegistry
        self.actionExecutor = actionExecutor
        self.encoderAccumulator = EncoderAccumulator()

        encoderAccumulator.setFlushHandler { [weak self] event in
            self?.executeAction(for: event)
        }
    }

    func dispatch(_ event: NuimoEvent) {
        logger.debug("Dispatching event: \(String(describing: event))")

        switch event {
        case .rotateClockwise, .rotateCounterClockwise:
            encoderAccumulator.accumulate(event)
        default:
            executeAction(for: event)
        }
    }

    func handleBLEData(_ data: Data, characteristicUUID: CBUUID) {
        guard let event = EventDecoder.decode(data: data, characteristicUUID: characteristicUUID) else {
            return
        }
        dispatch(event)
    }

    private func executeAction(for event: NuimoEvent) {
        guard let action = actionRegistry.action(for: event) else {
            logger.debug("No action mapped for event: \(String(describing: event))")
            return
        }
        logger.info("Executing action for \(event.configKey ?? "unknown")")
        actionExecutor.execute(action)
    }
}
