import Testing
import CoreBluetooth
@testable import NuimoController

struct BLEManagerTests {

    @Test func nuimoServiceUUIDIsCorrect() {
        #expect(NuimoUUID.nuimoService.uuidString == "F29B1525-CB19-40F3-BE5C-7241ECB82FD2")
    }

    @Test func allCharacteristicUUIDsAreDefined() {
        #expect(NuimoUUID.gestureChar.uuidString == "F29B1526-CB19-40F3-BE5C-7241ECB82FD2")
        #expect(NuimoUUID.touchChar.uuidString == "F29B1527-CB19-40F3-BE5C-7241ECB82FD2")
        #expect(NuimoUUID.encoderChar.uuidString == "F29B1528-CB19-40F3-BE5C-7241ECB82FD2")
        #expect(NuimoUUID.buttonChar.uuidString == "F29B1529-CB19-40F3-BE5C-7241ECB82FD2")
        #expect(NuimoUUID.ledChar.uuidString == "F29B152D-CB19-40F3-BE5C-7241ECB82FD2")
    }

    @Test func batteryServiceUUID() {
        #expect(NuimoUUID.batteryService.uuidString == "180F")
        #expect(NuimoUUID.batteryLevelChar.uuidString == "2A19")
    }

    @Test func deviceInfoServiceUUID() {
        #expect(NuimoUUID.deviceInfoService.uuidString == "180A")
        #expect(NuimoUUID.manufacturerName.uuidString == "2A29")
        #expect(NuimoUUID.modelNumber.uuidString == "2A24")
        #expect(NuimoUUID.firmwareRevision.uuidString == "2A26")
    }

    @Test func notifyCharacteristicsIncludeAllInputs() {
        let notify = NuimoUUID.notifyCharacteristics
        #expect(notify.contains(NuimoUUID.gestureChar))
        #expect(notify.contains(NuimoUUID.touchChar))
        #expect(notify.contains(NuimoUUID.encoderChar))
        #expect(notify.contains(NuimoUUID.buttonChar))
        #expect(notify.contains(NuimoUUID.batteryLevelChar))
    }

    @Test func stateTransitionsExist() {
        let states: [BLEManagerState] = [.idle, .scanning, .connecting, .discoveringServices, .connected, .disconnected]
        #expect(states.count == 6)
    }

    @Test func stateRawValues() {
        #expect(BLEManagerState.idle.rawValue == "idle")
        #expect(BLEManagerState.connected.rawValue == "connected")
        #expect(BLEManagerState.disconnected.rawValue == "disconnected")
    }
}
