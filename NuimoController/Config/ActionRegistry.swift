import Foundation
import os.log

final class ActionRegistry: Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "ActionRegistry")

    nonisolated(unsafe) private var actionMap: [String: NuimoAction] = [:]
    nonisolated(unsafe) private var ledPatternMap: [String: String] = [:]

    func updateFromConfig(_ config: NuimoConfig) {
        var newMap = [String: NuimoAction]()

        for (eventKey, actionConfig) in config.actions {
            if let action = buildAction(from: actionConfig, eventKey: eventKey) {
                newMap[eventKey] = action
            }
        }

        actionMap = newMap
        ledPatternMap = config.ledPatterns
        logger.info("ActionRegistry updated: \(newMap.count) mappings")
    }

    func action(for event: NuimoEvent) -> NuimoAction? {
        guard let key = event.configKey else { return nil }
        return actionMap[key]
    }

    func ledPatternName(for event: NuimoEvent) -> String? {
        guard let key = event.configKey else { return nil }
        guard let actionConfig = actionMap[key] else { return nil }
        // The LED pattern is stored during config parsing — we need the original ActionConfig.
        // For now, return nil. LED pattern lookup will be done via config directly.
        return nil
    }

    func ledPattern(named name: String) -> String? {
        ledPatternMap[name]
    }

    // MARK: - Private

    private func buildAction(from config: ActionConfig, eventKey: String) -> NuimoAction? {
        switch config.actionType {
        case "keystroke":
            guard let keyName = config.key,
                  let keyCode = KeyCodeMap.keyCode(for: keyName) else {
                logger.warning("Invalid key '\(config.key ?? "nil")' for event '\(eventKey)'")
                return nil
            }
            let flags = KeyCodeMap.modifierFlags(for: config.modifiers)
            return .keystroke(key: keyCode, modifiers: flags)

        case "scroll":
            guard let directionStr = config.direction,
                  let direction = ScrollDirection(rawValue: directionStr) else {
                logger.warning("Invalid scroll direction for event '\(eventKey)'")
                return nil
            }
            return .scroll(direction: direction, speed: config.speed ?? 1.0)

        case "shell":
            guard let command = config.command else {
                logger.warning("Missing command for shell action on event '\(eventKey)'")
                return nil
            }
            return .shell(command: command)

        case "brightness":
            return .brightness

        case "volume":
            return .volume

        case "media":
            guard let actionName = config.mediaAction,
                  let mediaAction = MediaAction(rawValue: actionName) else {
                logger.warning("Invalid media action for event '\(eventKey)'")
                return nil
            }
            return .media(mediaAction)

        case "launch":
            if let app = config.appName ?? config.bundleId {
                return .launch(app: app)
            }
            logger.warning("Missing app_name or bundle_id for launch action on event '\(eventKey)'")
            return nil

        case "none":
            return NuimoAction.none

        default:
            logger.warning("Unknown action type '\(config.actionType)' for event '\(eventKey)'")
            return nil
        }
    }
}
