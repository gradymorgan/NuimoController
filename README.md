# NuimoController

A macOS menu-bar app that connects to a [Nuimo](https://senic.com) wireless controller via Bluetooth and executes customizable actions based on device gestures.

## Features

- **Bluetooth connectivity** — automatic discovery and connection to Nuimo devices
- **Gesture support** — button press, rotation, swipe, touch, long touch, fly, and proximity
- **Customizable actions** — keystrokes, scroll, media keys, shell commands, and app launch
- **Hot-reload config** — edit `~/.config/nuimo/config.yaml` and changes apply instantly
- **LED feedback** — display 9x9 pixel patterns on the Nuimo's LED matrix

## Requirements

- macOS
- A Nuimo wireless controller
- Bluetooth enabled

## Installation

```bash
git clone <repo-url>
cd NuimoController
xcodebuild -scheme NuimoController build
```

## Configuration

Create `~/.config/nuimo/config.yaml` to map gestures to actions:

```yaml
# Example config
button_press:
  type: keystroke
  key: space

rotate_right:
  type: scroll
  direction: up

swipe_left:
  type: media
  action: previous_track

swipe_right:
  type: media
  action: next_track

long_touch_left:
  type: shell
  command: "open -a Safari"

long_touch_right:
  type: launch
  app: "Music"
```

Config parse failures retain the last good config, so a typo won't break your setup.

## Architecture

```
Nuimo Hardware
  → BLEManager          (CoreBluetooth discovery/connection)
  → EventDecoder        (raw bytes → NuimoEvent)
  → EventDispatcher     (routes events; buffers rotation deltas)
  → ActionRegistry      (maps events → actions via config)
  → ActionExecutor      (keystroke, scroll, shell, media, launch)
  → LEDController       (visual feedback on device)
```

## Dependencies

- [Yams](https://github.com/jpsim/Yams) 5.4.0 — Swift YAML parser (via SPM)

## License

See [LICENSE](LICENSE) for details.
