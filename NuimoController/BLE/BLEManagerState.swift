import Foundation

enum BLEManagerState: String, Sendable {
    case idle
    case scanning
    case connecting
    case discoveringServices
    case connected
    case disconnected
}
