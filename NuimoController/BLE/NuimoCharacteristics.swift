import CoreBluetooth

enum NuimoUUID {
    // Nuimo Service
    static let nuimoService        = CBUUID(string: "F29B1525-CB19-40F3-BE5C-7241ECB82FD2")
    static let gestureChar         = CBUUID(string: "F29B1526-CB19-40F3-BE5C-7241ECB82FD2")
    static let touchChar           = CBUUID(string: "F29B1527-CB19-40F3-BE5C-7241ECB82FD2")
    static let encoderChar         = CBUUID(string: "F29B1528-CB19-40F3-BE5C-7241ECB82FD2")
    static let buttonChar          = CBUUID(string: "F29B1529-CB19-40F3-BE5C-7241ECB82FD2")
    static let gestureCalibration  = CBUUID(string: "F29B152C-CB19-40F3-BE5C-7241ECB82FD2")
    static let ledChar             = CBUUID(string: "F29B152D-CB19-40F3-BE5C-7241ECB82FD2")

    // Standard Services
    static let batteryService      = CBUUID(string: "180F")
    static let batteryLevelChar    = CBUUID(string: "2A19")
    static let deviceInfoService   = CBUUID(string: "180A")

    // Device Info Characteristics
    static let manufacturerName    = CBUUID(string: "2A29")
    static let modelNumber         = CBUUID(string: "2A24")
    static let hardwareRevision    = CBUUID(string: "2A27")
    static let firmwareRevision    = CBUUID(string: "2A26")

    /// All services to discover
    static let allServices: [CBUUID] = [nuimoService, batteryService, deviceInfoService]

    /// Characteristics to subscribe to notifications
    static let notifyCharacteristics: [CBUUID] = [gestureChar, touchChar, encoderChar, buttonChar, batteryLevelChar]

    /// Characteristics to read once (device info)
    static let readOnceCharacteristics: [CBUUID] = [manufacturerName, modelNumber, hardwareRevision, firmwareRevision]
}
