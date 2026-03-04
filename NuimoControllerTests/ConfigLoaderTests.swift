import Testing
import Foundation
@testable import NuimoController

struct ConfigLoaderTests {

    @Test func parseValidConfig() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        #expect(config.deviceName == "Nuimo")
        #expect(config.autoReconnect == true)
        #expect(config.reconnectIntervalSeconds == 5)
        #expect(config.ledBrightness == 180)
        #expect(config.ledDisplayDuration == 2.0)
        #expect(config.ledOnionSkinning == false)
        #expect(config.actions.count > 0)
    }

    @Test func parseDefaultActions() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        #expect(config.actions["rotate_clockwise"]?.actionType == "scroll")
        #expect(config.actions["rotate_clockwise"]?.direction == "down")
        #expect(config.actions["rotate_clockwise"]?.speed == 1.5)
        #expect(config.actions["button_press"]?.actionType == "keystroke")
        #expect(config.actions["button_press"]?.key == "space")
        #expect(config.actions["swipe_left"]?.modifiers == ["command", "shift"])
        #expect(config.actions["swipe_left"]?.ledPattern == "arrow_left")
    }

    @Test func parseLEDPatterns() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        #expect(config.ledPatterns["arrow_left"] != nil)
        #expect(config.ledPatterns["arrow_right"] != nil)
        #expect(config.ledPatterns["check"] != nil)
    }

    @Test func parseMissingOptionalFields() throws {
        let yaml = """
        nuimo:
          device_name: "Test"
        actions: {}
        """
        let config = try ConfigLoader.parse(yaml: yaml)
        #expect(config.deviceName == "Test")
        #expect(config.autoReconnect == true)  // default
        #expect(config.ledBrightness == 180)   // default
    }

    @Test func parseEmptyYaml() throws {
        let yaml = "{}"
        let config = try ConfigLoader.parse(yaml: yaml)
        #expect(config.deviceName == "Nuimo")  // all defaults
        #expect(config.actions.isEmpty)
    }

    @Test func parseInvalidYamlThrows() {
        #expect(throws: (any Error).self) {
            _ = try ConfigLoader.parse(yaml: "not: [valid: yaml: {{{")
        }
    }

    @Test func parseAutoReconnectFalse() throws {
        let yaml = """
        nuimo:
          auto_reconnect: false
        """
        let config = try ConfigLoader.parse(yaml: yaml)
        #expect(config.autoReconnect == false)
    }

    @Test func loadFromTempFile() throws {
        let tmpDir = NSTemporaryDirectory() + "nuimo_test_\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        let path = tmpDir + "/config.yaml"
        try DefaultConfig.yaml.write(toFile: path, atomically: true, encoding: .utf8)

        let loader = ConfigLoader(configPath: path)
        try loader.load()
        #expect(loader.currentConfig.actions.count > 0)
    }

    @Test func corruptConfigRetainsLastGood() throws {
        let tmpDir = NSTemporaryDirectory() + "nuimo_test_\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        let path = tmpDir + "/config.yaml"
        try DefaultConfig.yaml.write(toFile: path, atomically: true, encoding: .utf8)

        let loader = ConfigLoader(configPath: path)
        try loader.load()
        let goodActionCount = loader.currentConfig.actions.count
        #expect(goodActionCount > 0)
        #expect(loader.lastError == nil)

        // Corrupt the file
        try "not: [valid: yaml: {{{".write(toFile: path, atomically: true, encoding: .utf8)

        // Reload should fail but retain the good config
        #expect(throws: (any Error).self) {
            try loader.reload()
        }
        #expect(loader.currentConfig.actions.count == goodActionCount)
        #expect(loader.lastError != nil)
    }
}
