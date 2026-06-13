import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case polish = "pl"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .polish:  return "Polski"
        case .english: return "English"
        }
    }
}

enum LKey {
    // Status
    case noConnection, off, coolingDown, ventilation, heating, almostReady, ready
    // Alarms
    case alarmDoorOpenHeating, alarmDoorSensor, alarmThermalCutoff
    case alarmInternalOverheat, alarmTempSensorShort, alarmTempSensorOpen
    // Door
    case doorOpen, doorClosed, doorOK
    // Alarm summary
    case noAlarms, alarmCount
    // Notifications
    case saunaReadyTitle, tempReached
    // Controls
    case targetTemperature, turnOffLight, turnOnLight, turnOffFan, startFanFor
    case fanLow, fanMedium, fanHigh, fanOff, fanLevelHelp, fanDurationHelp, minutesShort
    case start, stop
    // Diagnostics
    case diagSaunaType, diagSessionTime, diagFanDuration, diagFanLevel
    case diagFanRegister, diagHeatersActive, diagDoor, diagUptime, diagnostics
    case defaultValue, connecting, refreshedAt, targetShort
    // Settings
    case back, settings, device, ipAddress, port, refresh
    case everyHowManySeconds, secondsShort, saveSettings, forgetDevice, language
    // Discovery
    case searchingSauna, scanningSubtitle, foundDevices, scanning, scanAgain
    case hide, enterIPManually, portLabel, connect
    // Discovery status
    case detectingNetwork, cannotDetectNetwork, scanningSubnet
    case checkingHost, noDeviceFound, foundDeviceCount
}

final class Localizer: ObservableObject {
    static let shared = Localizer()

    private static let defaultsKey = "SaunaBarLanguage"

    @Published var language: AppLanguage {
        didSet {
            guard oldValue != language else { return }
            UserDefaults.standard.set(language.rawValue, forKey: Self.defaultsKey)
        }
    }

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.defaultsKey),
           let lang = AppLanguage(rawValue: stored) {
            language = lang
        } else {
            // First launch: follow the system language, defaulting to English.
            let preferred = Locale.preferredLanguages.first ?? "en"
            language = preferred.hasPrefix("pl") ? .polish : .english
        }
    }

    func t(_ key: LKey, _ args: CVarArg...) -> String {
        let table = language == .english ? Self.en : Self.pl
        let format = table[key] ?? "\(key)"
        return args.isEmpty ? format : String(format: format, arguments: args)
    }

    private static let pl: [LKey: String] = [
        .noConnection: "Brak połączenia",
        .off: "Wyłączona",
        .coolingDown: "Stygnie",
        .ventilation: "Wentylacja",
        .heating: "Nagrzewanie…",
        .almostReady: "Prawie gotowa",
        .ready: "Gotowa! 🧖",

        .alarmDoorOpenHeating: "Drzwi otwarte podczas grzania",
        .alarmDoorSensor: "Czujnik drzwi",
        .alarmThermalCutoff: "Termik",
        .alarmInternalOverheat: "Przegrzanie wewnętrzne",
        .alarmTempSensorShort: "Zwarcie czujnika temperatury",
        .alarmTempSensorOpen: "Brak czujnika temperatury",

        .doorOpen: "Drzwi otwarte",
        .doorClosed: "Drzwi zamknięte",
        .doorOK: "Drzwi OK",

        .noAlarms: "Brak alarmów",
        .alarmCount: "%d alarm",

        .saunaReadyTitle: "Sauna gotowa! 🧖",
        .tempReached: "Temperatura osiągnęła %d°C",

        .targetTemperature: "Temperatura docelowa",
        .turnOffLight: "Wyłącz światło",
        .turnOnLight: "Włącz światło",
        .turnOffFan: "Wyłącz wentylator",
        .startFanFor: "Uruchom wentylator na %d min",
        .fanLow: "Wentylator niski",
        .fanMedium: "Wentylator średni",
        .fanHigh: "Wentylator wysoki",
        .fanOff: "Wentylator wyłączony",
        .fanLevelHelp: "Poziom wentylatora: %d",
        .fanDurationHelp: "Czas wentylatora: %d min",
        .minutesShort: "%d min",
        .start: "Start",
        .stop: "Stop",

        .diagSaunaType: "Typ sauny",
        .diagSessionTime: "Czas sesji",
        .diagFanDuration: "Czas wentylatora",
        .diagFanLevel: "Poziom wentylatora",
        .diagFanRegister: "Rejestr wentylatora",
        .diagHeatersActive: "Grzałki aktywne",
        .diagDoor: "Drzwi",
        .diagUptime: "Uptime",
        .diagnostics: "Diagnostyka",
        .defaultValue: "Domyślnie",
        .connecting: "Łączenie…",
        .refreshedAt: "Odświeżono o %@",
        .targetShort: "Cel %@",

        .back: "Wróć",
        .settings: "Ustawienia",
        .device: "Urządzenie",
        .ipAddress: "Adres IP",
        .port: "Port",
        .refresh: "Odświeżanie",
        .everyHowManySeconds: "Co ile sekund",
        .secondsShort: "%d s",
        .saveSettings: "Zapisz ustawienia",
        .forgetDevice: "Zapomnij urządzenie",
        .language: "Język",

        .searchingSauna: "Szukanie sauny",
        .scanningSubtitle: "Skanowanie sieci lokalnej w poszukiwaniu\nurządzenia Saunum",
        .foundDevices: "Znalezione urządzenia",
        .scanning: "Skanowanie…",
        .scanAgain: "Skanuj ponownie",
        .hide: "Ukryj",
        .enterIPManually: "Podaj IP ręcznie",
        .portLabel: "Port %d",
        .connect: "Połącz",

        .detectingNetwork: "Wykrywam sieć…",
        .cannotDetectNetwork: "Nie można wykryć sieci lokalnej",
        .scanningSubnet: "Skanuję %@.1–254…",
        .checkingHost: "Sprawdzam %@…",
        .noDeviceFound: "Nie znaleziono urządzenia Saunum",
        .foundDeviceCount: "Znaleziono %d urządzenie(a)",
    ]

    private static let en: [LKey: String] = [
        .noConnection: "No connection",
        .off: "Off",
        .coolingDown: "Cooling down",
        .ventilation: "Ventilation",
        .heating: "Heating…",
        .almostReady: "Almost ready",
        .ready: "Ready! 🧖",

        .alarmDoorOpenHeating: "Door open while heating",
        .alarmDoorSensor: "Door sensor",
        .alarmThermalCutoff: "Thermal cutoff",
        .alarmInternalOverheat: "Internal overheat",
        .alarmTempSensorShort: "Temperature sensor short",
        .alarmTempSensorOpen: "Temperature sensor missing",

        .doorOpen: "Door open",
        .doorClosed: "Door closed",
        .doorOK: "Door OK",

        .noAlarms: "No alarms",
        .alarmCount: "%d alarm",

        .saunaReadyTitle: "Sauna ready! 🧖",
        .tempReached: "Temperature reached %d°C",

        .targetTemperature: "Target temperature",
        .turnOffLight: "Turn off light",
        .turnOnLight: "Turn on light",
        .turnOffFan: "Turn off fan",
        .startFanFor: "Run fan for %d min",
        .fanLow: "Fan low",
        .fanMedium: "Fan medium",
        .fanHigh: "Fan high",
        .fanOff: "Fan off",
        .fanLevelHelp: "Fan level: %d",
        .fanDurationHelp: "Fan duration: %d min",
        .minutesShort: "%d min",
        .start: "Start",
        .stop: "Stop",

        .diagSaunaType: "Sauna type",
        .diagSessionTime: "Session time",
        .diagFanDuration: "Fan duration",
        .diagFanLevel: "Fan level",
        .diagFanRegister: "Fan register",
        .diagHeatersActive: "Active heaters",
        .diagDoor: "Door",
        .diagUptime: "Uptime",
        .diagnostics: "Diagnostics",
        .defaultValue: "Default",
        .connecting: "Connecting…",
        .refreshedAt: "Refreshed at %@",
        .targetShort: "Target %@",

        .back: "Back",
        .settings: "Settings",
        .device: "Device",
        .ipAddress: "IP address",
        .port: "Port",
        .refresh: "Refresh",
        .everyHowManySeconds: "Every (seconds)",
        .secondsShort: "%d s",
        .saveSettings: "Save settings",
        .forgetDevice: "Forget device",
        .language: "Language",

        .searchingSauna: "Searching for sauna",
        .scanningSubtitle: "Scanning the local network\nfor a Saunum device",
        .foundDevices: "Found devices",
        .scanning: "Scanning…",
        .scanAgain: "Scan again",
        .hide: "Hide",
        .enterIPManually: "Enter IP manually",
        .portLabel: "Port %d",
        .connect: "Connect",

        .detectingNetwork: "Detecting network…",
        .cannotDetectNetwork: "Cannot detect local network",
        .scanningSubnet: "Scanning %@.1–254…",
        .checkingHost: "Checking %@…",
        .noDeviceFound: "No Saunum device found",
        .foundDeviceCount: "Found %d device(s)",
    ]
}
