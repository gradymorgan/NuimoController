import Foundation
import os.log

final class ActionExecutor: ActionExecutorProtocol, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "ActionExecutor")

    let keystrokeExecutor: KeystrokeExecutor
    let scrollExecutor: ScrollExecutor
    let shellExecutor: ShellExecutor
    let mediaKeyExecutor: MediaKeyExecutor
    let launchExecutor: LaunchExecutor

    init(
        keystrokeExecutor: KeystrokeExecutor = KeystrokeExecutor(),
        scrollExecutor: ScrollExecutor = ScrollExecutor(),
        shellExecutor: ShellExecutor = ShellExecutor(),
        mediaKeyExecutor: MediaKeyExecutor = MediaKeyExecutor(),
        launchExecutor: LaunchExecutor = LaunchExecutor()
    ) {
        self.keystrokeExecutor = keystrokeExecutor
        self.scrollExecutor = scrollExecutor
        self.shellExecutor = shellExecutor
        self.mediaKeyExecutor = mediaKeyExecutor
        self.launchExecutor = launchExecutor
    }

    func execute(_ action: NuimoAction, rawDelta: Int16) {
        switch action {
        case .scroll(let direction, let speed):
            AccessibilityHelper.promptIfNeeded()
            scrollExecutor.execute(direction: direction, speed: speed, rawDelta: rawDelta)
        default:
            execute(action)
        }
    }

    func execute(_ action: NuimoAction) {
        switch action {
        case .keystroke(let key, let modifiers):
            AccessibilityHelper.promptIfNeeded()
            keystrokeExecutor.execute(keyCode: key, modifiers: modifiers)

        case .scroll(let direction, let speed):
            AccessibilityHelper.promptIfNeeded()
            scrollExecutor.execute(direction: direction, speed: speed)

        case .shell(let command):
            shellExecutor.execute(command: command)

        case .brightness:
            logger.info("Brightness action (not yet implemented)")

        case .volume:
            logger.info("Volume action (not yet implemented)")

        case .media(let mediaAction):
            mediaKeyExecutor.execute(action: mediaAction)

        case .launch(let app):
            launchExecutor.execute(app: app)

        case .none:
            break
        }
    }
}
