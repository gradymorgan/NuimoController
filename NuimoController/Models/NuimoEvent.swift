import Foundation

enum NuimoEvent: Hashable, Sendable {
    case rotateClockwise(delta: Int16)
    case rotateCounterClockwise(delta: Int16)
    case swipeLeft, swipeRight, swipeUp, swipeDown
    case touchLeft, touchRight, touchTop, touchBottom
    case longTouchLeft, longTouchRight, longTouchTop, longTouchBottom
    case flyLeft, flyRight
    case proximity(distance: UInt8)
    case buttonPress, buttonRelease
}

extension NuimoEvent {
    /// The config key used in YAML action mappings for discrete events.
    var configKey: String? {
        switch self {
        case .rotateClockwise: return "rotate_clockwise"
        case .rotateCounterClockwise: return "rotate_counter_clockwise"
        case .swipeLeft: return "swipe_left"
        case .swipeRight: return "swipe_right"
        case .swipeUp: return "swipe_up"
        case .swipeDown: return "swipe_down"
        case .touchLeft: return "touch_left"
        case .touchRight: return "touch_right"
        case .touchTop: return "touch_top"
        case .touchBottom: return "touch_bottom"
        case .longTouchLeft: return "long_touch_left"
        case .longTouchRight: return "long_touch_right"
        case .longTouchTop: return "long_touch_top"
        case .longTouchBottom: return "long_touch_bottom"
        case .flyLeft: return "fly_left"
        case .flyRight: return "fly_right"
        case .proximity: return "proximity"
        case .buttonPress: return "button_press"
        case .buttonRelease: return "button_release"
        }
    }
}
