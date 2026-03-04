import Foundation

protocol LEDControllerProtocol: AnyObject, Sendable {
    func showPattern(_ pattern: String, brightness: UInt8, duration: Double)
}
