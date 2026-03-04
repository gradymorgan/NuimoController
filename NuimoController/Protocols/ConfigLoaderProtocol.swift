import Foundation

protocol ConfigLoaderProtocol: AnyObject, Sendable {
    func load() throws
    func reload() throws
}
