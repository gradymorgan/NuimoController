import Foundation

enum DefaultConfig {
    static let yaml = """
    # NuimoController Configuration
    nuimo:
      device_name: "Nuimo"
      auto_reconnect: true
      reconnect_interval_seconds: 5

    led:
      brightness: 180
      display_duration: 2.0
      onion_skinning: false

    actions:
      rotate_clockwise:
        action: scroll
        direction: down
        speed: 1.5

      rotate_counter_clockwise:
        action: scroll
        direction: up
        speed: 1.5

      button_press:
        action: keystroke
        key: space
        modifiers: []

      swipe_left:
        action: keystroke
        key: tab
        modifiers: [command, shift]
        led_pattern: "arrow_left"

      swipe_right:
        action: keystroke
        key: tab
        modifiers: [command]
        led_pattern: "arrow_right"

      swipe_up:
        action: keystroke
        key: up
        modifiers: [control]

      swipe_down:
        action: keystroke
        key: down
        modifiers: [control]

      touch_left:
        action: keystroke
        key: left
        modifiers: []

      touch_right:
        action: keystroke
        key: right
        modifiers: []

    led_patterns:
      arrow_left: |
        000010000
        000100000
        001000000
        010000000
        111111111
        010000000
        001000000
        000100000
        000010000
      arrow_right: |
        000010000
        000001000
        000000100
        000000010
        111111111
        000000010
        000000100
        000001000
        000010000
      check: |
        000000000
        000000010
        000000100
        000001000
        100010000
        010100000
        001000000
        000000000
        000000000
    """

    static let configDirectoryPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.config/nuimo"
    }()

    static let configFilePath: String = {
        "\(configDirectoryPath)/config.yaml"
    }()
}
