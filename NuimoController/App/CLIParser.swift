import Foundation
import os.log

struct CLIOptions {
    var verbose: Bool = false
    var configPath: String? = nil
}

enum CLIParser {
    static func parse(_ arguments: [String] = CommandLine.arguments) -> CLIOptions {
        var options = CLIOptions()
        var i = 1 // skip executable path
        while i < arguments.count {
            switch arguments[i] {
            case "--verbose", "-v":
                options.verbose = true
            case "--config", "-c":
                i += 1
                if i < arguments.count {
                    options.configPath = arguments[i]
                }
            default:
                break
            }
            i += 1
        }
        return options
    }
}
