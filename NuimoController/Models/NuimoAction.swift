import CoreGraphics

enum ScrollDirection: String, Sendable {
    case up, down, left, right
}

enum MediaAction: String, Sendable {
    case playPause = "play_pause"
    case next
    case prev
}

enum NuimoAction: Sendable {
    case keystroke(key: CGKeyCode, modifiers: CGEventFlags)
    case scroll(direction: ScrollDirection, speed: Double)
    case shell(command: String)
    case brightness
    case volume
    case media(MediaAction)
    case launch(app: String)
    case none
}
