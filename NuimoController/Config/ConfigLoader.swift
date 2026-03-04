import Foundation
import Yams
import os.log
import Combine

final class ConfigLoader: ConfigLoaderProtocol, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "ConfigLoader")
    private let configPath: String
    private var fileWatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    private(set) var currentConfig: NuimoConfig = .default
    let configChanged = PassthroughSubject<NuimoConfig, Never>()

    init(configPath: String = DefaultConfig.configFilePath) {
        self.configPath = configPath
    }

    deinit {
        stopWatching()
    }

    func load() throws {
        createDefaultConfigIfNeeded()
        try reloadFromDisk()
        startWatching()
        logger.info("Config loaded: \(self.currentConfig.actions.count) action mappings")
    }

    /// Last error from a reload attempt (nil if last reload succeeded).
    private(set) var lastError: (any Error)?

    func reload() throws {
        try reloadFromDisk()
        logger.info("Config reloaded: \(self.currentConfig.actions.count) action mappings")
    }

    // MARK: - Private

    private func reloadFromDisk() throws {
        let yamlString: String
        do {
            yamlString = try String(contentsOfFile: configPath, encoding: .utf8)
        } catch {
            logger.error("Failed to read config file: \(error.localizedDescription)")
            throw ConfigError.fileNotFound(configPath)
        }

        do {
            let config = try Self.parse(yaml: yamlString)
            currentConfig = config
            lastError = nil
            configChanged.send(config)
        } catch {
            lastError = error
            logger.error("Failed to parse config: \(error.localizedDescription) — retaining last good config")
            throw error
        }
    }

    private func createDefaultConfigIfNeeded() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: configPath) else { return }

        do {
            try fm.createDirectory(atPath: DefaultConfig.configDirectoryPath, withIntermediateDirectories: true)
            try DefaultConfig.yaml.write(toFile: configPath, atomically: true, encoding: .utf8)
            logger.info("Created default config at \(self.configPath)")
        } catch {
            logger.warning("Could not create default config: \(error.localizedDescription)")
        }
    }

    // MARK: - File Watching

    private func startWatching() {
        stopWatching()

        fileDescriptor = open(configPath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            logger.warning("Could not open config file for watching")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.logger.info("Config file changed, reloading...")
            do {
                try self.reloadFromDisk()
            } catch {
                self.logger.error("Hot-reload failed: \(error.localizedDescription)")
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        source.resume()
        fileWatchSource = source
        logger.info("Watching config file for changes")
    }

    private func stopWatching() {
        fileWatchSource?.cancel()
        fileWatchSource = nil
    }

    // MARK: - YAML Parsing

    static func parse(yaml: String) throws -> NuimoConfig {
        guard let root = try Yams.load(yaml: yaml) as? [String: Any] else {
            throw ConfigError.invalidFormat("Root must be a YAML mapping")
        }

        let nuimoSection = root["nuimo"] as? [String: Any] ?? [:]
        let ledSection = root["led"] as? [String: Any] ?? [:]
        let actionsSection = root["actions"] as? [String: Any] ?? [:]
        let patternsSection = root["led_patterns"] as? [String: Any] ?? [:]

        var config = NuimoConfig.default

        // Nuimo settings
        if let name = nuimoSection["device_name"] as? String { config.deviceName = name }
        if let auto = nuimoSection["auto_reconnect"] as? Bool { config.autoReconnect = auto }
        if let interval = nuimoSection["reconnect_interval_seconds"] as? Double { config.reconnectIntervalSeconds = interval }
        if let interval = nuimoSection["reconnect_interval_seconds"] as? Int { config.reconnectIntervalSeconds = Double(interval) }

        // LED settings
        if let brightness = ledSection["brightness"] as? Int {
            config.ledBrightness = UInt8(clamping: brightness)
        }
        if let duration = ledSection["display_duration"] as? Double { config.ledDisplayDuration = duration }
        if let onion = ledSection["onion_skinning"] as? Bool { config.ledOnionSkinning = onion }

        // Actions
        for (eventKey, value) in actionsSection {
            guard let actionDict = value as? [String: Any] else { continue }
            guard let actionType = actionDict["action"] as? String else { continue }

            let modifiers: [String]
            if let mods = actionDict["modifiers"] as? [String] {
                modifiers = mods
            } else {
                modifiers = []
            }

            let actionConfig = ActionConfig(
                actionType: actionType,
                key: actionDict["key"] as? String,
                modifiers: modifiers,
                direction: actionDict["direction"] as? String,
                speed: (actionDict["speed"] as? Double) ?? (actionDict["speed"] as? Int).map(Double.init),
                command: actionDict["command"] as? String,
                mediaAction: actionDict["action_name"] as? String,
                appName: actionDict["app_name"] as? String,
                bundleId: actionDict["bundle_id"] as? String,
                ledPattern: actionDict["led_pattern"] as? String
            )
            config.actions[eventKey] = actionConfig
        }

        // LED patterns
        for (name, value) in patternsSection {
            if let pattern = value as? String {
                config.ledPatterns[name] = pattern
            }
        }

        return config
    }
}

enum ConfigError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path): return "Config file not found: \(path)"
        case .invalidFormat(let msg): return "Invalid config format: \(msg)"
        }
    }
}
