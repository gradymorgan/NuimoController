import Foundation
import os.log

struct ShellExecutor: Sendable {
    private static let logger = Logger(subsystem: "com.nuimo.controller", category: "ShellExecutor")
    private static let timeout: TimeInterval = 5.0

    func execute(command: String) {
        Self.logger.info("Executing shell: \(command)")

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", command]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                try process.run()

                // Timeout
                DispatchQueue.global().asyncAfter(deadline: .now() + Self.timeout) {
                    if process.isRunning {
                        Self.logger.warning("Shell command timed out, terminating")
                        process.terminate()
                    }
                }

                process.waitUntilExit()

                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()

                if !outData.isEmpty, let out = String(data: outData, encoding: .utf8) {
                    Self.logger.debug("stdout: \(out.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
                if !errData.isEmpty, let err = String(data: errData, encoding: .utf8) {
                    Self.logger.warning("stderr: \(err.trimmingCharacters(in: .whitespacesAndNewlines))")
                }

                if process.terminationStatus != 0 {
                    Self.logger.warning("Shell command exited with status \(process.terminationStatus)")
                }
            } catch {
                Self.logger.error("Failed to run shell command: \(error.localizedDescription)")
            }
        }
    }
}
