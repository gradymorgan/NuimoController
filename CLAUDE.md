# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

NuimoController is a macOS menu-bar app that connects to a Nuimo wireless controller via Bluetooth and executes customizable actions (keystrokes, scroll, media keys, shell commands, app launch) based on device gestures. Configuration lives at `~/.config/nuimo/config.yaml` and hot-reloads on save.

## Build & Test Commands

```bash
# Build
xcodebuild -scheme NuimoController build

# Run all tests
xcodebuild -scheme NuimoController test

# Run a single test (Swift Testing)
xcodebuild -scheme NuimoController test -only-testing:NuimoControllerTests/EventDecoderTests
```

Tests use **Swift Testing** (not XCTest). The test target uses `nonisolated` default actor isolation.

## Architecture

```
Nuimo Hardware
  → BLEManager (CoreBluetooth discovery/connection)
  → EventDecoder (raw bytes → NuimoEvent enum)
  → EventDispatcher (routes events; EncoderAccumulator buffers rotation deltas over 20ms)
  → ActionRegistry (looks up NuimoEvent.configKey → NuimoAction via loaded config)
  → ActionExecutor (delegates to specialized executors: Keystroke, Scroll, Shell, Media, Launch)
  → LEDController (optional visual feedback on device, rate-limited at 50ms)
```

`AppDelegate` is the orchestrator that bootstraps and wires all components. Config changes broadcast via Combine `PassthroughSubject<NuimoConfig>`.

## Key Conventions

- **Protocol-driven**: Every major component has a protocol (`BLE/`, `Config/`, `Dispatch/`, `Actions/`, `LED/` all in `Protocols/`). Tests use mock implementations via protocol injection.
- **Concurrency**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` globally. BLE operations run on `userInitiated` dispatch queues.
- **Logging**: `os.log` with subsystem categories per component (e.g., "BLEManager", "EventDispatcher").
- **Config format**: YAML via Yams dependency. Events map through `NuimoEvent.configKey` strings. LED patterns are 9×9 grids of `0`/`1` packed into 11 bytes LSB-first.
- **Error resilience**: Config parse failures retain last good config. `ConfigError` thrown for invalid YAML.

## Dependencies

- **Yams** 5.4.0 (Swift YAML parser) via SPM

## BLE Characteristics

Four input characteristics decoded by `EventDecoder`:
- `0x1526` Gesture (fly/proximity)
- `0x1527` Touch (swipe/touch/longtouch × 4 directions)
- `0x1528` Encoder (rotation delta, signed Int16)
- `0x1529` Button (press/release)
