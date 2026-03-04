# NuimoController — macOS BLE-to-Input Bridge

## Overview

A headless macOS menu bar app (Swift) that connects to a Senic Nuimo BLE device, reads gesture/touch/rotation/button events, and translates them into configurable macOS inputs (keystrokes, scroll events, system actions) via a YAML config file.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  NuimoController (menu bar app)                     │
│                                                     │
│  ┌──────────────┐    ┌──────────────────────────┐   │
│  │ ConfigLoader  │───▶│  ActionRegistry           │   │
│  │ (YAML parse)  │    │  (event → action mapping) │   │
│  └──────────────┘    └──────────┬───────────────┘   │
│                                 │                    │
│  ┌──────────────┐    ┌──────────▼───────────────┐   │
│  │ BLEManager    │───▶│  EventDispatcher          │   │
│  │ (CoreBluetooth│    │  (decode + route)         │   │
│  │  scanning,    │    └──────────┬───────────────┘   │
│  │  connection,  │               │                    │
│  │  GATT read)   │    ┌──────────▼───────────────┐   │
│  └──────────────┘    │  ActionExecutor            │   │
│                      │  (CGEvent, NSWorkspace,    │   │
│  ┌──────────────┐    │   AppleScript bridge)      │   │
│  │ LEDController │    └──────────────────────────┘   │
│  │ (write to     │                                   │
│  │  LED char)    │    ┌──────────────────────────┐   │
│  └──────────────┘    │  StatusBarUI              │   │
│                      │  (connection state,        │   │
│                      │   config reload, quit)     │   │
│                      └──────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Key Components

| Component | Responsibility |
|---|---|
| **BLEManager** | Scan, connect, discover services/characteristics, subscribe to notifications, reconnect on disconnect |
| **EventDispatcher** | Decode raw BLE notification bytes into typed `NuimoEvent` values, route to ActionRegistry |
| **ConfigLoader** | Parse YAML config, validate, watch file for changes, hot-reload |
| **ActionRegistry** | Map `NuimoEvent` → `Action` based on current config |
| **ActionExecutor** | Execute macOS actions: keystroke simulation (CGEvent), scroll (CGEvent), AppleScript, shell commands |
| **LEDController** | Write 9×9 LED patterns to the Nuimo display (feedback on action) |
| **StatusBarUI** | Menu bar icon showing connection state, manual reconnect, config reload, quit |

---

## Config File Format

Location: `~/.config/nuimo/config.yaml`

```yaml
# NuimoController Configuration
nuimo:
  # Optional: specify device name or UUID to connect to a specific Nuimo
  # If omitted, connects to the first discovered Nuimo
  device_name: "Nuimo"
  # Reconnect automatically on disconnect
  auto_reconnect: true
  reconnect_interval_seconds: 5

# LED feedback settings
led:
  brightness: 180          # 0-255
  display_duration: 2.0    # seconds (0-25.5)
  onion_skinning: false

# Action mappings
actions:
  # Encoder (rotation ring)
  rotate_clockwise:
    action: scroll
    direction: down
    # Speed multiplier applied to the raw encoder delta
    speed: 1.5

  rotate_counter_clockwise:
    action: scroll
    direction: up
    speed: 1.5

  # Button
  button_press:
    action: keystroke
    key: space
    modifiers: []

  # Swipe gestures
  swipe_left:
    action: keystroke
    key: tab
    modifiers: [command, shift]
    # Optional LED feedback pattern (9x9 grid, 1=on 0=off, row-major)
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
    # Mission Control

  swipe_down:
    action: keystroke
    key: down
    modifiers: [control]
    # App Exposé

  # Touch gestures
  touch_left:
    action: keystroke
    key: left
    modifiers: []

  touch_right:
    action: keystroke
    key: right
    modifiers: []

  # Fly gestures
  fly_left:
    action: shell
    command: "osascript -e 'tell application \"Spotify\" to previous track'"

  fly_right:
    action: shell
    command: "osascript -e 'tell application \"Spotify\" to next track'"

  # Proximity
  proximity:
    action: brightness
    # Maps proximity distance (0-255) to screen brightness

# Built-in LED patterns (referenced by name above)
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
```

### Supported Action Types

| Action Type | Parameters | Description |
|---|---|---|
| `keystroke` | `key`, `modifiers[]` | Simulate a key press via CGEvent |
| `scroll` | `direction` (up/down/left/right), `speed` | Simulate scroll wheel events |
| `shell` | `command` | Execute a shell command |
| `brightness` | — | Map continuous input to screen brightness |
| `volume` | — | Map continuous input to system volume |
| `media` | `action` (play_pause/next/prev) | Media key simulation |
| `launch` | `app_name` or `bundle_id` | Open an application |
| `none` | — | Explicitly disable an event |

### Modifier Keys

`command`, `shift`, `option`, `control`, `fn`

---

## BLE Protocol Reference (from spec)

### Service & Characteristic UUIDs

```swift
// Nuimo Service
let nuimoServiceUUID        = CBUUID(string: "F29B1525-CB19-40F3-BE5C-7241ECB82FD2")
let gestureCharUUID          = CBUUID(string: "F29B1526-CB19-40F3-BE5C-7241ECB82FD2")
let touchCharUUID            = CBUUID(string: "F29B1527-CB19-40F3-BE5C-7241ECB82FD2")
let encoderCharUUID          = CBUUID(string: "F29B1528-CB19-40F3-BE5C-7241ECB82FD2")
let buttonCharUUID           = CBUUID(string: "F29B1529-CB19-40F3-BE5C-7241ECB82FD2")
let gestureCalibrationUUID   = CBUUID(string: "F29B152C-CB19-40F3-BE5C-7241ECB82FD2")
let ledCharUUID              = CBUUID(string: "F29B152D-CB19-40F3-BE5C-7241ECB82FD2")

// Standard Services
let batteryServiceUUID       = CBUUID(string: "180F")
let batteryLevelCharUUID     = CBUUID(string: "2A19")
let deviceInfoServiceUUID    = CBUUID(string: "180A")
```

### Event Decoding

| Characteristic | Bytes | Decoding |
|---|---|---|
| Gesture (0x1526) | 2 bytes unsigned | byte[0]: 0=FlyLeft, 1=FlyRight, 4=Proximity; byte[1]: proximity distance (0-255) |
| Touch (0x1527) | 1 byte unsigned | 0-3=Swipe(L/R/U/D), 4-7=Touch(L/R/T/B), 8-11=LongTouch(L/R/T/B) |
| Encoder (0x1528) | 2 bytes signed (Int16) | >0=Clockwise, <0=CounterClockwise |
| Button (0x1529) | 1 byte unsigned | 0=Release, 1=Press |

### LED Matrix Write Format (0x152D)

13 bytes total:
- Bytes 0-10: LED bitmap (81 LEDs, row-major, LSB first per byte)
- Byte 10 upper bits: flags (bit5=onion skinning, bit6=play built-in animation)
- Byte 11: brightness (0-255)
- Byte 12: display duration (0-255 → 0-25.5 seconds, value × 0.1s)

---

## Development Phases

Each phase produces a working, testable increment. An AI agent should implement one phase at a time, run all tests, and verify before proceeding.

---

### Phase 1: Project Scaffolding & Menu Bar Shell

**Goal:** A macOS menu bar app that launches, shows a status icon, and quits cleanly.

**Tasks:**
1. Create a new Swift Package Manager project (executable target + test target)
2. Set up as a menu bar app (no dock icon): `LSUIElement = true` in Info.plist
3. Create `AppDelegate` with `NSStatusBar` item showing a Nuimo icon (use SF Symbol `circle.grid.3x3` or similar)
4. Menu items: "Status: Disconnected", separator, "Reconnect", "Reload Config", "Quit"
5. Add `os.log` logging subsystem `com.nuimo.controller`
6. Create stub protocols for all major components:
   - `BLEManagerProtocol`
   - `EventDispatcherProtocol`
   - `ConfigLoaderProtocol`
   - `ActionExecutorProtocol`
   - `LEDControllerProtocol`

**Unit Tests:**
- `AppDelegate` initializes status bar item
- Menu items are present and wired to correct selectors
- Stub protocols compile and can be mocked

**Integration Test (manual):**
- Build and run → menu bar icon appears
- Click "Quit" → app exits
- Verify no dock icon shown

**Files:**
```
NuimoController/
├── Package.swift
├── Sources/
│   └── NuimoController/
│       ├── main.swift
│       ├── AppDelegate.swift
│       ├── Protocols/
│       │   ├── BLEManagerProtocol.swift
│       │   ├── EventDispatcherProtocol.swift
│       │   ├── ConfigLoaderProtocol.swift
│       │   ├── ActionExecutorProtocol.swift
│       │   └── LEDControllerProtocol.swift
│       └── Models/
│           ├── NuimoEvent.swift
│           └── NuimoAction.swift
└── Tests/
    └── NuimoControllerTests/
        ├── AppDelegateTests.swift
        └── ModelTests.swift
```

---

### Phase 2: Event Model & Config Loader

**Goal:** Parse the YAML config file into strongly-typed Swift models with validation and hot-reload.

**Tasks:**
1. Add `Yams` dependency (Swift YAML parser) to Package.swift
2. Define `NuimoEvent` enum covering all BLE events:
   ```swift
   enum NuimoEvent: Hashable {
       case rotateClockwise(delta: Int16)
       case rotateCounterClockwise(delta: Int16)
       case swipeLeft, swipeRight, swipeUp, swipeDown
       case touchLeft, touchRight, touchTop, touchBottom
       case longTouchLeft, longTouchRight, longTouchTop, longTouchBottom
       case flyLeft, flyRight
       case proximity(distance: UInt8)
       case buttonPress, buttonRelease
   }
   ```
3. Define `NuimoAction` enum:
   ```swift
   enum NuimoAction {
       case keystroke(key: CGKeyCode, modifiers: CGEventFlags)
       case scroll(direction: ScrollDirection, speed: Double)
       case shell(command: String)
       case brightness
       case volume
       case media(MediaAction)
       case launch(app: String)
       case none
   }
   ```
4. Implement `ConfigLoader`:
   - Read YAML from `~/.config/nuimo/config.yaml`
   - Parse into `NuimoConfig` struct
   - Validate all fields
   - Watch file with `DispatchSource.makeFileSystemObjectSource` for changes
   - Publish changes via Combine `PassthroughSubject` or delegate
5. Implement `ActionRegistry` mapping event types → actions
6. Create default config file if none exists

**Unit Tests:**
- Parse valid YAML config → correct `NuimoConfig`
- Parse config with missing optional fields → defaults applied
- Parse config with invalid action type → error reported, graceful fallback
- `ActionRegistry` returns correct action for each event type
- Modifier string parsing: "command" → `.maskCommand`, etc.
- Key name parsing: "space" → `kVK_Space`, "tab" → `kVK_Tab`, etc.
- LED pattern parsing: string grid → `[UInt8]` bitmap

**Integration Test (manual):**
- Place config at `~/.config/nuimo/config.yaml`
- Run app → verify log shows "Config loaded: X action mappings"
- Edit config file while running → verify log shows "Config reloaded"
- Place invalid YAML → verify error logged, previous config retained

**Files (new/modified):**
```
Sources/NuimoController/
├── Models/
│   ├── NuimoEvent.swift       (updated)
│   ├── NuimoAction.swift      (updated)
│   ├── NuimoConfig.swift      (new)
│   └── LEDPattern.swift       (new)
├── Config/
│   ├── ConfigLoader.swift     (new)
│   ├── ActionRegistry.swift   (new)
│   ├── KeyCodeMap.swift       (new — maps string names to CGKeyCode)
│   └── DefaultConfig.swift    (new — embedded default YAML)
Tests/
├── ConfigLoaderTests.swift    (new)
├── ActionRegistryTests.swift  (new)
├── KeyCodeMapTests.swift      (new)
└── LEDPatternTests.swift      (new)
```

---

### Phase 3: BLE Manager — Scanning & Connection

**Goal:** Scan for Nuimo devices, connect, discover services/characteristics, handle disconnection and reconnection.

**Tasks:**
1. Implement `BLEManager` conforming to `CBCentralManagerDelegate` and `CBPeripheralDelegate`
2. State machine:
   ```
   .idle → .scanning → .connecting → .discoveringServices → .connected
                                                               ↓
                                                         .disconnected → .scanning (if auto_reconnect)
   ```
3. Scan filtered by `nuimoServiceUUID`
4. On connect, discover all 3 services (Device Info, Battery, Nuimo)
5. Discover characteristics for each service
6. Store references to all needed characteristics
7. Handle `CBCentralManager` authorization states
8. Implement reconnection with configurable backoff
9. Publish connection state changes to UI (StatusBarUI updates)
10. Add entitlement: `com.apple.security.device.bluetooth`

**Unit Tests (with mock CBCentralManager/CBPeripheral):**
- State transitions: idle → scanning on `start()`
- Filters scan by correct service UUID
- Handles `poweredOff` state gracefully
- Reconnects after disconnect when `auto_reconnect` is true
- Does not reconnect when `auto_reconnect` is false
- Discovery finds all expected characteristics
- Handles discovery failure (missing characteristic) gracefully

**Integration Test (manual — requires physical Nuimo):**
- Run app → verify "Scanning..." in menu bar tooltip
- Power on Nuimo → verify connection established, menu shows "Connected"
- Power off Nuimo → verify "Disconnected", then auto-reconnect attempts
- Toggle Mac Bluetooth off/on → verify recovery

**Files:**
```
Sources/NuimoController/
├── BLE/
│   ├── BLEManager.swift             (new)
│   ├── BLEManagerState.swift        (new)
│   └── NuimoCharacteristics.swift   (new — stores discovered char refs)
├── AppDelegate.swift                (updated — wire BLEManager)
Tests/
├── BLEManagerTests.swift            (new)
├── Mocks/
│   ├── MockCBCentralManager.swift   (new)
│   └── MockCBPeripheral.swift       (new)
```

---

### Phase 4: BLE Notification Handling & Event Dispatch

**Goal:** Subscribe to Nuimo characteristic notifications, decode raw bytes into `NuimoEvent`, and route to the action system.

**Tasks:**
1. Subscribe to notifications for: Gesture, Touch, Encoder, Button, Battery
2. Implement `EventDecoder` — stateless byte-to-event decoder:
   - Gesture char: 2 bytes → `.flyLeft`, `.flyRight`, or `.proximity(distance:)`
   - Touch char: 1 byte → appropriate swipe/touch/longTouch case
   - Encoder char: 2 bytes (Int16 little-endian) → `.rotateClockwise(delta:)` or `.rotateCounterClockwise(delta:)`
   - Button char: 1 byte → `.buttonPress` or `.buttonRelease`
3. Implement `EventDispatcher`:
   - Receive decoded events
   - Look up action in `ActionRegistry`
   - Forward to `ActionExecutor`
   - For encoder: accumulate/debounce rapid rotation events
4. Handle encoder smoothing:
   - Accumulate deltas within a time window (e.g., 50ms)
   - Apply speed multiplier from config
   - Emit aggregated scroll events

**Unit Tests:**
- Decode gesture bytes `[0x00, 0x00]` → `.flyLeft`
- Decode gesture bytes `[0x01, 0x00]` → `.flyRight`
- Decode gesture bytes `[0x04, 0x80]` → `.proximity(distance: 128)`
- Decode touch byte `0x00` → `.swipeLeft`
- Decode touch byte `0x07` → `.touchBottom`
- Decode touch byte `0x0B` → `.longTouchBottom`
- Decode encoder bytes `[0x05, 0x00]` (little-endian +5) → `.rotateClockwise(delta: 5)`
- Decode encoder bytes `[0xFB, 0xFF]` (little-endian -5) → `.rotateCounterClockwise(delta: 5)`
- Decode button byte `0x01` → `.buttonPress`
- Decode button byte `0x00` → `.buttonRelease`
- EventDispatcher routes swipeLeft → correct action from registry
- Encoder accumulation: 3 rapid deltas within window → single aggregated event
- Unknown/out-of-range bytes → logged warning, no crash

**Integration Test (manual — requires Nuimo):**
- Run app with config that maps all events to `shell: "echo EVENT_NAME >> /tmp/nuimo.log"`
- Interact with Nuimo (rotate, swipe, tap, press button, wave hand)
- Check `/tmp/nuimo.log` for correct events
- Verify no missed events, no duplicates, correct order

**Files:**
```
Sources/NuimoController/
├── BLE/
│   ├── EventDecoder.swift       (new)
│   └── BLEManager.swift         (updated — subscribe + forward)
├── Dispatch/
│   ├── EventDispatcher.swift    (new)
│   └── EncoderAccumulator.swift (new)
Tests/
├── EventDecoderTests.swift      (new)
├── EventDispatcherTests.swift   (new)
├── EncoderAccumulatorTests.swift (new)
```

---

### Phase 5: Action Executor — Keystrokes & Scroll

**Goal:** Simulate macOS input events from decoded Nuimo actions.

**Tasks:**
1. Implement `KeystrokeExecutor`:
   - Use `CGEvent` to simulate key down + key up
   - Support all modifier combinations
   - Map config key names to `CGKeyCode` values (comprehensive map)
2. Implement `ScrollExecutor`:
   - Use `CGEvent(scrollWheelEvent2:...)` for smooth scrolling
   - Apply speed multiplier and direction from config
   - Support both vertical and horizontal scroll
3. Implement `ShellExecutor`:
   - Run commands via `Process` (async, non-blocking)
   - Timeout after 5 seconds
   - Log stdout/stderr
4. Implement `MediaKeyExecutor`:
   - Simulate media key events (play/pause, next, previous) via `CGEvent` with `NX_KEYTYPE_*`
5. Implement `LaunchExecutor`:
   - Use `NSWorkspace.shared.open` for app launching
6. Wire all executors into `ActionExecutor` facade
7. **Accessibility permissions**: The app needs Accessibility access for CGEvent posting. Detect permission state and prompt user.

**Unit Tests (with mock CGEvent posting):**
- Keystroke action posts correct keyCode and modifier flags
- Scroll action posts correct scroll direction and delta
- Shell action invokes Process with correct command
- Media key action posts correct NX key type
- Launch action calls NSWorkspace with correct bundle ID
- Missing accessibility permissions → user prompted (test the detection logic)

**Integration Test (manual):**
- Map button_press → keystroke space. Open a text editor. Press Nuimo button → space typed.
- Map rotate → scroll. Open a long web page. Rotate ring → page scrolls.
- Map swipe_right → Cmd+Tab. Have 2 apps open. Swipe → app switches.
- Map swipe_up → Ctrl+Up. Swipe up → Mission Control opens.
- Map fly_right → shell osascript Spotify next. Play Spotify. Fly right → next track.

**Files:**
```
Sources/NuimoController/
├── Actions/
│   ├── ActionExecutor.swift       (new — facade)
│   ├── KeystrokeExecutor.swift    (new)
│   ├── ScrollExecutor.swift       (new)
│   ├── ShellExecutor.swift        (new)
│   ├── MediaKeyExecutor.swift     (new)
│   ├── LaunchExecutor.swift       (new)
│   └── AccessibilityHelper.swift  (new)
├── Config/
│   └── KeyCodeMap.swift           (updated — comprehensive mapping)
Tests/
├── KeystrokeExecutorTests.swift   (new)
├── ScrollExecutorTests.swift      (new)
├── ShellExecutorTests.swift       (new)
├── Mocks/
│   └── MockEventPoster.swift      (new — mock CGEvent posting)
```

---

### Phase 6: LED Feedback

**Goal:** Write visual feedback patterns to the Nuimo's 9×9 LED matrix when actions are triggered.

**Tasks:**
1. Implement `LEDController`:
   - Convert 9×9 pattern string to 11-byte bitmap (81 bits, LSB-first per byte)
   - Set brightness byte from config
   - Set duration byte from config (value = seconds × 10)
   - Set flags byte (onion skinning)
   - Write 13-byte payload to LED characteristic
2. Built-in pattern library: arrows, check, X, play, pause, volume bars, brightness bars, numbers 0-9
3. Trigger LED write after action execution (non-blocking)
4. Rate-limit LED writes (min 50ms between writes to avoid BLE congestion)

**Unit Tests:**
- Pattern string "111111111\n..." → correct 11-byte bitmap
- Single LED at position (0,0) → bit 0 of byte 0 set
- Single LED at position (8,8) → bit 0 of byte 10 set (81st LED = bit 1 of byte 10 per spec)
- Brightness 180 → byte 11 = 0xB4
- Duration 2.0s → byte 12 = 20
- Onion skinning flag set correctly in byte 10 upper bits
- Rate limiter drops writes within 50ms window

**Integration Test (manual — requires Nuimo):**
- Swipe right → right arrow appears on Nuimo LED matrix
- Rotate clockwise → brightness/volume bar pattern shown
- Button press → check mark shown
- Rapid actions → no BLE write errors, smooth transitions

**Files:**
```
Sources/NuimoController/
├── LED/
│   ├── LEDController.swift      (new)
│   ├── LEDBitmap.swift          (new — pattern → bytes conversion)
│   ├── LEDPatternLibrary.swift  (new — built-in patterns)
│   └── LEDRateLimiter.swift     (new)
Tests/
├── LEDBitmapTests.swift         (new)
├── LEDControllerTests.swift     (new)
├── LEDRateLimiterTests.swift    (new)
```

---

### Phase 7: Status Bar UI Polish & Battery Monitoring

**Goal:** Finalize the menu bar UI with connection details, battery level, and user-facing features.

**Tasks:**
1. Update status bar icon to reflect connection state:
   - Disconnected: gray icon
   - Scanning: pulsing/animated icon
   - Connected: solid icon
   - Connected + low battery: icon with warning badge
2. Show battery percentage in menu (subscribe to battery characteristic notifications)
3. Show device info in menu (manufacturer, model/color, firmware version)
4. "Reload Config" triggers `ConfigLoader.reload()` and shows success/error in menu
5. Add "Open Config File" menu item → opens YAML in default editor
6. Add "Create Default Config" if no config file exists
7. Optional: system notification on connect/disconnect

**Unit Tests:**
- Battery level decode: byte 75 → "75%"
- Status icon updates on state change
- Menu item titles update with device info

**Integration Test (manual):**
- Connect Nuimo → battery level shows in menu
- Menu shows firmware version, device color
- "Open Config File" opens in editor
- Low battery → icon changes

**Files:**
```
Sources/NuimoController/
├── UI/
│   ├── StatusBarController.swift  (new — extracted from AppDelegate)
│   └── MenuBuilder.swift          (new)
├── BLE/
│   └── BatteryMonitor.swift       (new)
├── AppDelegate.swift              (updated — simplified)
Tests/
├── StatusBarControllerTests.swift (new)
├── BatteryMonitorTests.swift      (new)
```

---

### Phase 8: Robustness, Error Handling & Launch at Login

**Goal:** Production hardening, launch-at-login, and comprehensive error handling.

**Tasks:**
1. Add `SMAppService` (macOS 13+) for launch-at-login, with toggle in menu
2. Comprehensive error handling:
   - BLE errors: log, update UI, auto-retry
   - Config parse errors: show alert, retain last good config
   - Action execution errors: log, show brief menu bar notification
   - Accessibility permission missing: show guide dialog
3. Graceful degradation: if one characteristic fails, continue with others
4. Add `os.signpost` for performance profiling of event pipeline latency
5. Handle macOS sleep/wake: pause scanning on sleep, resume on wake
6. Memory leak audit: ensure no retain cycles in BLE delegate chains
7. Add `--verbose` CLI flag for debug logging
8. Add `--config PATH` CLI flag for custom config location

**Unit Tests:**
- Sleep/wake notifications trigger correct BLE state transitions
- Error in one characteristic doesn't prevent others from working
- Launch-at-login toggle persists setting
- CLI argument parsing

**Integration Test (manual):**
- Close and reopen laptop lid → reconnects after wake
- Corrupt config file → error shown, old config still works
- Remove accessibility permission → app detects and prompts
- Add to login items → app launches on restart

**Files:**
```
Sources/NuimoController/
├── App/
│   ├── LaunchAtLogin.swift      (new)
│   ├── SleepWakeHandler.swift   (new)
│   └── CLIParser.swift          (new)
├── AppDelegate.swift            (updated)
Tests/
├── SleepWakeHandlerTests.swift  (new)
├── CLIParserTests.swift         (new)
```

---

## Final Project Structure

```
NuimoController/
├── Package.swift
├── Sources/
│   └── NuimoController/
│       ├── main.swift
│       ├── AppDelegate.swift
│       ├── Protocols/
│       │   ├── BLEManagerProtocol.swift
│       │   ├── EventDispatcherProtocol.swift
│       │   ├── ConfigLoaderProtocol.swift
│       │   ├── ActionExecutorProtocol.swift
│       │   └── LEDControllerProtocol.swift
│       ├── Models/
│       │   ├── NuimoEvent.swift
│       │   ├── NuimoAction.swift
│       │   ├── NuimoConfig.swift
│       │   └── LEDPattern.swift
│       ├── BLE/
│       │   ├── BLEManager.swift
│       │   ├── BLEManagerState.swift
│       │   ├── NuimoCharacteristics.swift
│       │   ├── EventDecoder.swift
│       │   └── BatteryMonitor.swift
│       ├── Config/
│       │   ├── ConfigLoader.swift
│       │   ├── ActionRegistry.swift
│       │   ├── KeyCodeMap.swift
│       │   └── DefaultConfig.swift
│       ├── Dispatch/
│       │   ├── EventDispatcher.swift
│       │   └── EncoderAccumulator.swift
│       ├── Actions/
│       │   ├── ActionExecutor.swift
│       │   ├── KeystrokeExecutor.swift
│       │   ├── ScrollExecutor.swift
│       │   ├── ShellExecutor.swift
│       │   ├── MediaKeyExecutor.swift
│       │   ├── LaunchExecutor.swift
│       │   └── AccessibilityHelper.swift
│       ├── LED/
│       │   ├── LEDController.swift
│       │   ├── LEDBitmap.swift
│       │   ├── LEDPatternLibrary.swift
│       │   └── LEDRateLimiter.swift
│       ├── UI/
│       │   ├── StatusBarController.swift
│       │   └── MenuBuilder.swift
│       └── App/
│           ├── LaunchAtLogin.swift
│           ├── SleepWakeHandler.swift
│           └── CLIParser.swift
└── Tests/
    └── NuimoControllerTests/
        ├── ModelTests.swift
        ├── ConfigLoaderTests.swift
        ├── ActionRegistryTests.swift
        ├── KeyCodeMapTests.swift
        ├── LEDPatternTests.swift
        ├── BLEManagerTests.swift
        ├── EventDecoderTests.swift
        ├── EventDispatcherTests.swift
        ├── EncoderAccumulatorTests.swift
        ├── KeystrokeExecutorTests.swift
        ├── ScrollExecutorTests.swift
        ├── ShellExecutorTests.swift
        ├── LEDBitmapTests.swift
        ├── LEDControllerTests.swift
        ├── LEDRateLimiterTests.swift
        ├── StatusBarControllerTests.swift
        ├── BatteryMonitorTests.swift
        ├── SleepWakeHandlerTests.swift
        ├── CLIParserTests.swift
        └── Mocks/
            ├── MockCBCentralManager.swift
            ├── MockCBPeripheral.swift
            └── MockEventPoster.swift
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| [Yams](https://github.com/jpsim/Yams) | ~> 5.0 | YAML parsing |

No other external dependencies. Uses only Apple frameworks: CoreBluetooth, AppKit, CoreGraphics, Combine, ServiceManagement.

---

## macOS Permissions Required

| Permission | How | Why |
|---|---|---|
| Bluetooth | `Info.plist`: `NSBluetoothAlwaysUsageDescription` | BLE communication with Nuimo |
| Accessibility | System Settings → Privacy → Accessibility | CGEvent posting for keystrokes/scroll |
| Automation (optional) | Per-app prompt | If using AppleScript shell commands |

---

## Agent Instructions

When implementing each phase:

1. **Read this spec first** for context on the full architecture
2. **Implement only the current phase** — don't jump ahead
3. **Write tests before or alongside implementation** (TDD encouraged)
4. **Run all tests** before marking a phase complete: `swift test`
5. **Each phase must compile and all tests must pass** before proceeding
6. **Use protocol-oriented design** — all components communicate through protocols for testability
7. **Use dependency injection** — no singletons except `AppDelegate`
8. **Log generously** with `os.log` — this is a background app, logs are the primary debugging tool
9. **Keep the BLE spec values in a single constants file** (`NuimoCharacteristics.swift`) — don't scatter UUIDs
10. **The config format is the user-facing API** — validate thoroughly, fail gracefully, provide clear error messages
