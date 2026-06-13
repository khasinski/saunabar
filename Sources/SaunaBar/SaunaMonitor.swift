import SwiftUI
import UserNotifications

enum SaunaStatus: Equatable {
    case unknown, idle, cooling, ventilating, warming, almostReady, ready

    init(temp: Int, target: Int, sessionActive: Bool, fanActive: Bool) {
        guard sessionActive else {
            if fanActive {
                self = .ventilating
            } else if temp >= 30 {
                self = .cooling
            } else {
                self = .idle
            }
            return
        }

        if temp >= target {
            self = .ready
        } else if temp >= max(30, target - 5) {
            self = .almostReady
        } else if temp >= 30 {
            self = .warming
        } else {
            self = .warming
        }
    }

    var label: String {
        switch self {
        case .unknown:     return "Brak połączenia"
        case .idle:        return "Wyłączona"
        case .cooling:     return "Stygnie"
        case .ventilating: return "Wentylacja"
        case .warming:     return "Nagrzewanie…"
        case .almostReady: return "Prawie gotowa"
        case .ready:       return "Gotowa! 🧖"
        }
    }

    var icon: String {
        switch self {
        case .unknown:     return "thermometer.slash"
        case .idle:        return "power"
        case .cooling:     return "thermometer.medium"
        case .ventilating: return "fan.fill"
        case .warming:     return "thermometer.medium"
        case .almostReady: return "thermometer.high"
        case .ready:       return "flame.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .unknown, .idle: return .secondary
        case .cooling:        return .blue
        case .ventilating:    return .cyan
        case .warming:        return .orange
        case .almostReady:    return Color(red: 1, green: 0.45, blue: 0)
        case .ready:          return .red
        }
    }

    var gradientTop: Color {
        switch self {
        case .unknown:     return Color(white: 0.4)
        case .idle:        return Color(white: 0.34)
        case .cooling:     return Color(red: 0.28, green: 0.50, blue: 0.78)
        case .ventilating: return Color(red: 0.16, green: 0.55, blue: 0.62)
        case .warming:     return Color(red: 0.96, green: 0.58, blue: 0.10)
        case .almostReady: return Color(red: 0.94, green: 0.34, blue: 0.05)
        case .ready:       return Color(red: 0.76, green: 0.10, blue: 0.05)
        }
    }

    var gradientBottom: Color {
        switch self {
        case .unknown:     return Color(white: 0.25)
        case .idle:        return Color(white: 0.22)
        case .cooling:     return Color(red: 0.18, green: 0.36, blue: 0.62)
        case .ventilating: return Color(red: 0.10, green: 0.36, blue: 0.44)
        case .warming:     return Color(red: 0.88, green: 0.38, blue: 0.00)
        case .almostReady: return Color(red: 0.78, green: 0.18, blue: 0.00)
        case .ready:       return Color(red: 0.52, green: 0.04, blue: 0.00)
        }
    }

    var dotColor: Color {
        switch self {
        case .unknown:     return .red
        case .idle:        return .secondary
        case .cooling:     return .blue
        case .ventilating: return .cyan
        case .warming:     return .yellow
        case .almostReady: return .orange
        case .ready:       return .green
        }
    }
}

enum SaunaAlarm: CaseIterable, Identifiable {
    case doorOpenDuringHeating
    case doorSensor
    case thermalCutoff
    case internalOverheat
    case tempSensorShort
    case tempSensorOpen

    var id: Self { self }

    var label: String {
        switch self {
        case .doorOpenDuringHeating: return "Drzwi otwarte podczas grzania"
        case .doorSensor:            return "Czujnik drzwi"
        case .thermalCutoff:         return "Termik"
        case .internalOverheat:      return "Przegrzanie wewnętrzne"
        case .tempSensorShort:       return "Zwarcie czujnika temperatury"
        case .tempSensorOpen:        return "Brak czujnika temperatury"
        }
    }
}

class SaunaMonitor: ObservableObject {
    @Published var temperature: Int?  = nil
    @Published var lastUpdated: Date? = nil
    @Published var isConnected        = false

    @Published var heaterOn:   Bool = false
    @Published var targetTemp: Int  = 65
    @Published var lightOn:    Bool = false
    @Published var fanSpeed:   Int  = 0
    @Published var fanLevel:   Int  = 2
    @Published var requestedFanSpeed: Int = 0
    @Published var fanDuration: Int = 15
    @Published var fanRemainingSeconds: Int = 0
    @Published var saunaType: Int = 0
    @Published var saunaDuration: Int = 0
    @Published var deviceUptime: UInt32 = 0
    @Published var heaterElementsActive: Int = 0
    @Published var doorOpen: Bool = false
    @Published var alarms: [SaunaAlarm] = []

    @Published var config: SaunaConfig? = nil

    private var isLoading = false
    private var tempWriteWork: DispatchWorkItem?
    private var fanCountdownTimer: Timer?

    private var client: ModbusClient?
    private var timer: Timer?

    // Notification state: true after notifying, reset when a new heating cycle starts.
    private var readyNotified = false
    // Suppress notification if sauna was already hot when the app launched.
    private var isFirstFetch = true

    var saunaStatus: SaunaStatus {
        temperature.map {
            SaunaStatus(temp: $0, target: targetTemp, sessionActive: heaterOn, fanActive: fanIsActive)
        } ?? .unknown
    }

    var labelText: String      { temperature.map { "\($0)°" } ?? "--°" }
    var statusIcon: String     { saunaStatus.icon }
    var statusColor: Color     { saunaStatus.iconColor }
    var tempString: String     { temperature.map { "\($0)" } ?? "--" }
    var targetString: String   { "\(targetTemp)°C" }
    var doorString: String     { doorOpen ? "Drzwi otwarte" : "Drzwi zamknięte" }
    var heaterElementsString: String { "\(heaterElementsActive)" }
    var displayedFanSpeed: Int { fanIsActive ? max(requestedFanSpeed, fanSpeed) : fanSpeed }
    var uptimeString: String {
        let seconds = Int(deviceUptime)
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
    var alarmSummary: String {
        alarms.isEmpty ? "Brak alarmów" : "\(alarms.count) alarm"
    }
    var fanIsActive: Bool      { fanSpeed > 0 || fanRemainingSeconds > 0 }
    var fanRemainingString: String {
        let minutes = fanRemainingSeconds / 60
        let seconds = fanRemainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var heatProgress: Double {
        guard let temperature else { return 0 }
        return min(Double(temperature) / Double(max(targetTemp, 1)), 1.0)
    }

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        if let saved = SaunaConfig.load() {
            startMonitoring(saved)
        }
    }

    func apply(config: SaunaConfig) {
        try? config.save()
        startMonitoring(config)
    }

    func forget() {
        timer?.invalidate()
        fanCountdownTimer?.invalidate()
        timer = nil
        fanCountdownTimer = nil
        client = nil
        config = nil
        temperature = nil
        lastUpdated = nil
        isConnected = false
        heaterOn = false
        lightOn = false
        fanSpeed = 0
        fanLevel = 2
        requestedFanSpeed = 0
        fanDuration = 15
        fanRemainingSeconds = 0
        saunaType = 0
        saunaDuration = 0
        deviceUptime = 0
        heaterElementsActive = 0
        doorOpen = false
        alarms = []
        SaunaConfig.delete()
    }

    private func startMonitoring(_ cfg: SaunaConfig) {
        config = cfg
        client = ModbusClient(host: cfg.host, port: cfg.port)
        fetch()
        let interval = TimeInterval(max(5, cfg.refreshInterval))
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.fetch() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func fetch() {
        guard let client, !isLoading else { return }
        isLoading = true

        client.readRegisters(start: 0, count: 7) { [weak self] result in
            if case .success(let regs) = result, regs.count >= 7 {
                DispatchQueue.main.async {
                    guard let self else { return }
                    let newHeaterOn = regs[0] == 1
                    // Heater turned off → reset notification for next cycle.
                    if self.heaterOn && !newHeaterOn { self.readyNotified = false }
                    self.heaterOn  = newHeaterOn
                    self.saunaType = Int(regs[1])
                    self.saunaDuration = Int(regs[2])
                    let t = Int(regs[4])
                    if t > 0 { self.targetTemp = t }
                    let fanMinutes = Int(regs[3])
                    if fanMinutes > 0 { self.fanDuration = fanMinutes }
                    let currentFanSpeed = max(0, min(3, Int(regs[5])))
                    self.fanSpeed = currentFanSpeed
                    if currentFanSpeed > 0 { self.fanLevel = currentFanSpeed }
                    self.lightOn = regs[6] == 1
                }
            }
        }

        client.readRegisters(start: 100, count: 5) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let regs) where regs.count >= 5:
                    self.temperature = Int(regs[0])
                    self.deviceUptime = UInt32(regs[1]) << 16 | UInt32(regs[2])
                    self.heaterElementsActive = Int(regs[3])
                    self.doorOpen = regs[4] != 0
                    self.lastUpdated = Date()
                    self.isConnected = true
                    self.checkReadyNotification()
                default:
                    self.isConnected = false
                }
            }
        }

        client.readRegisters(start: 200, count: 6) { [weak self] result in
            guard case .success(let regs) = result, regs.count >= 6 else { return }
            DispatchQueue.main.async {
                self?.alarms = SaunaAlarm.allCases.enumerated().compactMap { index, alarm in
                    regs[index] == 0 ? nil : alarm
                }
            }
        }
    }

    func setHeater(_ on: Bool) {
        guard let client else { return }
        if !on { readyNotified = false }  // reset so next heat-up will notify
        heaterOn = on
        client.writeRegister(addr: 0, value: on ? 1 : 0) { [weak self] success in
            if !success { DispatchQueue.main.async { self?.heaterOn = !on } }
        }
    }

    func adjustTargetTemp(_ delta: Int) {
        guard let client else { return }
        let newTarget = max(40, min(100, targetTemp + delta))
        // Target raised above current temp → sauna needs to heat more, allow another notification.
        if let temp = temperature, newTarget > temp { readyNotified = false }
        targetTemp = newTarget
        tempWriteWork?.cancel()
        let val = UInt16(targetTemp)
        let work = DispatchWorkItem {
            client.writeRegister(addr: 4, value: val) { _ in }
        }
        tempWriteWork = work
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func setFanLevel(_ speed: Int) {
        fanLevel = max(1, min(3, speed))
    }

    func startFan() {
        requestedFanSpeed = fanLevel
        startFanCountdown(minutes: fanDuration)
        setFanSpeed(fanLevel)
    }

    func stopFan() {
        requestedFanSpeed = 0
        stopFanCountdown()
        setFanSpeed(0)
    }

    private func setFanSpeed(_ speed: Int) {
        guard let client else { return }
        let newSpeed = max(0, min(3, speed))
        let oldSpeed = fanSpeed
        fanSpeed = newSpeed

        let writeSpeed = {
            client.writeRegister(addr: 5, value: UInt16(newSpeed)) { [weak self] success in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if !success {
                        self.fanSpeed = oldSpeed
                        self.requestedFanSpeed = oldSpeed
                        if newSpeed > 0 { self.stopFanCountdown() }
                        return
                    }
                    self.refreshAfterControllerValidation()
                }
            }
        }

        if newSpeed > 0, fanDuration == 0 {
            fanDuration = 15
            client.writeRegister(addr: 3, value: 15) { success in
                if success {
                    writeSpeed()
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.fanSpeed = oldSpeed
                        self?.requestedFanSpeed = oldSpeed
                        self?.stopFanCountdown()
                    }
                }
            }
        } else {
            writeSpeed()
        }
    }

    func setFanDuration(_ minutes: Int) {
        guard let client else { return }
        let newDuration = max(0, min(30, minutes))
        let oldDuration = fanDuration
        fanDuration = newDuration
        client.writeRegister(addr: 3, value: UInt16(newDuration)) { [weak self] success in
            DispatchQueue.main.async {
                guard let self else { return }
                if !success {
                    self.fanDuration = oldDuration
                    return
                }
                self.refreshAfterControllerValidation()
            }
        }
    }

    func setLight(_ on: Bool) {
        guard let client else { return }
        lightOn = on
        client.writeRegister(addr: 6, value: on ? 1 : 0) { [weak self] success in
            DispatchQueue.main.async {
                guard let self else { return }
                if !success {
                    self.lightOn = !on
                    return
                }
                self.refreshAfterControllerValidation()
            }
        }
    }

    private func refreshAfterControllerValidation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.fetch()
        }
    }

    private func startFanCountdown(minutes: Int) {
        fanCountdownTimer?.invalidate()
        fanRemainingSeconds = max(1, minutes) * 60
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            DispatchQueue.main.async {
                guard let self else {
                    timer.invalidate()
                    return
                }
                guard self.fanRemainingSeconds > 0 else {
                    timer.invalidate()
                    self.fanCountdownTimer = nil
                    return
                }
                self.fanRemainingSeconds -= 1
                if self.fanRemainingSeconds == 0 {
                    timer.invalidate()
                    self.fanCountdownTimer = nil
                    self.fanSpeed = 0
                    self.requestedFanSpeed = 0
                }
            }
        }
        fanCountdownTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopFanCountdown() {
        fanCountdownTimer?.invalidate()
        fanCountdownTimer = nil
        fanRemainingSeconds = 0
        requestedFanSpeed = 0
    }

    // MARK: - Notifications

    private func checkReadyNotification() {
        guard heaterOn, let temp = temperature else { return }

        if isFirstFetch {
            isFirstFetch = false
            // Already hot on launch — mark as notified so we don't spam immediately.
            if temp >= targetTemp { readyNotified = true }
            return
        }

        if temp >= targetTemp && !readyNotified {
            readyNotified = true
            sendReadyNotification(temp: temp)
        }
    }

    private func sendReadyNotification(temp: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Sauna gotowa! 🧖"
        content.body  = "Temperatura osiągnęła \(temp)°C"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "sauna-ready", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
