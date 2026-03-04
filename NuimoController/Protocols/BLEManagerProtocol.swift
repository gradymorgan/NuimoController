import Foundation

protocol BLEManagerProtocol: AnyObject, Sendable {
    func startScanning()
    func stopScanning()
    func reconnect()
}
