import Testing
import CoreGraphics
import Carbon.HIToolbox
@testable import NuimoController

struct ActionRegistryTests {

    @Test func mapsKeystrokeAction() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        let registry = ActionRegistry()
        registry.updateFromConfig(config)

        let action = registry.action(for: .buttonPress)
        guard case .keystroke(let key, _) = action else {
            Issue.record("Expected keystroke action, got \(String(describing: action))")
            return
        }
        #expect(key == CGKeyCode(kVK_Space))
    }

    @Test func mapsScrollAction() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        let registry = ActionRegistry()
        registry.updateFromConfig(config)

        let action = registry.action(for: .rotateClockwise(delta: 5))
        guard case .scroll(let dir, let speed) = action else {
            Issue.record("Expected scroll action")
            return
        }
        #expect(dir == .down)
        #expect(speed == 1.5)
    }

    @Test func mapsSwipeWithModifiers() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        let registry = ActionRegistry()
        registry.updateFromConfig(config)

        let action = registry.action(for: .swipeLeft)
        guard case .keystroke(let key, let modifiers) = action else {
            Issue.record("Expected keystroke action")
            return
        }
        #expect(key == CGKeyCode(kVK_Tab))
        #expect(modifiers.contains(.maskCommand))
        #expect(modifiers.contains(.maskShift))
    }

    @Test func returnsNilForUnmappedEvent() throws {
        let config = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        let registry = ActionRegistry()
        registry.updateFromConfig(config)

        let action = registry.action(for: .flyLeft)
        #expect(action == nil)
    }

    @Test func updatesOnConfigChange() throws {
        let registry = ActionRegistry()

        // Start with default config
        let config1 = try ConfigLoader.parse(yaml: DefaultConfig.yaml)
        registry.updateFromConfig(config1)
        #expect(registry.action(for: .buttonPress) != nil)

        // Update with empty config
        let config2 = try ConfigLoader.parse(yaml: "actions: {}")
        registry.updateFromConfig(config2)
        #expect(registry.action(for: .buttonPress) == nil)
    }
}
