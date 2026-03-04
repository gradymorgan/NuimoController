import Foundation

protocol EventDispatcherProtocol: AnyObject, Sendable {
    func dispatch(_ event: NuimoEvent)
}
