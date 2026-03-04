import Foundation

protocol ActionExecutorProtocol: AnyObject, Sendable {
    func execute(_ action: NuimoAction)
    func execute(_ action: NuimoAction, rawDelta: Int16)
}
