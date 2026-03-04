import CoreBluetooth
import os.log
import os.signpost
import Combine

protocol BLEManagerDelegate: AnyObject, Sendable {
    func bleManager(_ manager: BLEManager, didChangeState state: BLEManagerState)
    func bleManager(_ manager: BLEManager, didReceiveData data: Data, forCharacteristic uuid: CBUUID)
    func bleManager(_ manager: BLEManager, didReadDeviceInfo key: String, value: String)
    func bleManager(_ manager: BLEManager, didUpdateBattery level: UInt8)
}

final class BLEManager: NSObject, BLEManagerProtocol, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.nuimo.controller", category: "BLEManager")

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var discoveredCharacteristics: [CBUUID: CBCharacteristic] = [:]

    private(set) var state: BLEManagerState = .idle {
        didSet {
            logger.info("BLE state: \(self.state.rawValue)")
            delegate?.bleManager(self, didChangeState: state)
        }
    }

    weak var delegate: (any BLEManagerDelegate)?

    var autoReconnect: Bool = true
    var reconnectInterval: TimeInterval = 5.0
    var deviceNameFilter: String?

    private var reconnectTimer: Timer?
    static let signpostLog = OSLog(subsystem: "com.nuimo.controller", category: .pointsOfInterest)
    private var paused: Bool = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .global(qos: .userInitiated))
    }

    // For testing: inject a mock CBCentralManager
    init(centralManager: CBCentralManager) {
        super.init()
        self.centralManager = centralManager
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            logger.warning("Cannot scan: Bluetooth not powered on (state: \(self.centralManager.state.rawValue))")
            return
        }
        state = .scanning
        // Scan without service filter — Nuimo may not advertise its custom
        // service UUID; we filter by device name in didDiscover instead.
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        logger.info("Scanning for Nuimo devices...")
    }

    func stopScanning() {
        centralManager.stopScan()
        if state == .scanning { state = .idle }
    }

    func reconnect() {
        cancelReconnectTimer()
        disconnect()
        startScanning()
    }

    func disconnect() {
        if let peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        peripheral = nil
        discoveredCharacteristics.removeAll()
    }

    func writeLEDData(_ data: Data) {
        guard let char = discoveredCharacteristics[NuimoUUID.ledChar],
              let peripheral else {
            logger.warning("Cannot write LED: not connected or characteristic not found")
            return
        }
        peripheral.writeValue(data, for: char, type: .withoutResponse)
    }

    // MARK: - Sleep/Wake

    func pauseForSleep() {
        paused = true
        cancelReconnectTimer()
        stopScanning()
        logger.info("BLE paused for sleep")
    }

    func resumeAfterWake() {
        paused = false
        logger.info("BLE resumed after wake")
        if state == .disconnected || state == .idle {
            startScanning()
        }
    }

    // MARK: - Reconnection

    private func scheduleReconnect() {
        guard autoReconnect, !paused else { return }
        cancelReconnectTimer()
        logger.info("Scheduling reconnect in \(self.reconnectInterval)s")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: self.reconnectInterval, repeats: false) { [weak self] _ in
                self?.startScanning()
            }
        }
    }

    private func cancelReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("Central manager state: \(central.state.rawValue)")
        switch central.state {
        case .poweredOn:
            if state == .idle || state == .disconnected {
                startScanning()
            }
        case .poweredOff:
            state = .disconnected
        default:
            break
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? "Unknown"
        let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map(\.uuidString) ?? []
        logger.info("Discovered: \(name) (RSSI: \(RSSI), services: \(serviceUUIDs))")

        if let filter = deviceNameFilter, !filter.isEmpty {
            guard name.localizedCaseInsensitiveContains(filter) else { return }
        }

        centralManager.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        state = .connecting
        centralManager.connect(peripheral, options: nil)
        logger.info("Connecting to \(name)...")
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to \(peripheral.name ?? "Unknown")")
        state = .discoveringServices
        peripheral.discoverServices(NuimoUUID.allServices)
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        logger.error("Failed to connect: \(error?.localizedDescription ?? "unknown")")
        state = .disconnected
        scheduleReconnect()
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        logger.info("Disconnected from \(peripheral.name ?? "Unknown")")
        self.peripheral = nil
        discoveredCharacteristics.removeAll()
        state = .disconnected
        scheduleReconnect()
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error {
            logger.error("Service discovery error: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }
        for service in services {
            logger.info("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error {
            logger.error("Characteristic discovery error for service \(service.uuid): \(error.localizedDescription) — continuing with other services")
            // Don't return — continue with whatever characteristics were found
        }

        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            logger.info("Discovered characteristic: \(char.uuid)")
            discoveredCharacteristics[char.uuid] = char

            // Subscribe to notifications
            if NuimoUUID.notifyCharacteristics.contains(char.uuid) {
                peripheral.setNotifyValue(true, for: char)
            }

            // Read device info
            if NuimoUUID.readOnceCharacteristics.contains(char.uuid) {
                peripheral.readValue(for: char)
            }
        }

        // Check if we have all the essentials
        let hasNuimoChars = NuimoUUID.notifyCharacteristics.allSatisfy { uuid in
            // Battery might be in a different service, don't require all
            uuid == NuimoUUID.batteryLevelChar || discoveredCharacteristics[uuid] != nil
        }
        if hasNuimoChars && state == .discoveringServices {
            state = .connected
        }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error {
            logger.error("Value update error for \(characteristic.uuid): \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else { return }

        // Handle device info reads
        if NuimoUUID.readOnceCharacteristics.contains(characteristic.uuid) {
            if let value = String(data: data, encoding: .utf8) {
                let key: String
                switch characteristic.uuid {
                case NuimoUUID.manufacturerName: key = "manufacturer"
                case NuimoUUID.modelNumber: key = "model"
                case NuimoUUID.hardwareRevision: key = "hardware"
                case NuimoUUID.firmwareRevision: key = "firmware"
                default: key = "unknown"
                }
                delegate?.bleManager(self, didReadDeviceInfo: key, value: value)
            }
            return
        }

        // Handle battery
        if characteristic.uuid == NuimoUUID.batteryLevelChar {
            if let level = data.first {
                delegate?.bleManager(self, didUpdateBattery: level)
            }
            return
        }

        // Forward other data to delegate for event decoding
        let signpostID = OSSignpostID(log: Self.signpostLog)
        os_signpost(.begin, log: Self.signpostLog, name: "EventPipeline", signpostID: signpostID, "char=%{public}@", characteristic.uuid.uuidString)
        delegate?.bleManager(self, didReceiveData: data, forCharacteristic: characteristic.uuid)
        os_signpost(.end, log: Self.signpostLog, name: "EventPipeline", signpostID: signpostID)
    }
}
