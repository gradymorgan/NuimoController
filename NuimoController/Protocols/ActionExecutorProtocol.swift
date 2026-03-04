import Foundation

protocol ActionExecutorProtocol: AnyObject, Sendable {
    func execute(_ action: NuimoAction)
}
