import SwiftUI

struct SaunaView: View {
    @EnvironmentObject var monitor: SaunaMonitor
    @ObservedObject private var loc = Localizer.shared
    @State private var showSettings = false

    var body: some View {
        ZStack {
            mainView
                .opacity(showSettings ? 0 : 1)

            if showSettings {
                SettingsView { withAnimation(.spring(duration: 0.25)) { showSettings = false } }
                    .environmentObject(monitor)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(width: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.spring(duration: 0.25), value: showSettings)
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            heroSection
            Divider()
            controlSection
            Divider()
            footerSection
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack {
            gradient

            VStack(spacing: 14) {
                statusBadge

                temperatureDisplay

                heroStatsRow

                heatBar
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
        }
    }

    private var gradient: some View {
        LinearGradient(
            stops: [
                .init(color: monitor.saunaStatus.gradientTop,    location: 0),
                .init(color: monitor.saunaStatus.gradientBottom, location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.8), value: monitor.saunaStatus)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(monitor.saunaStatus.dotColor)
                .frame(width: 6, height: 6)
            Text(monitor.saunaStatus.label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.18))
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }

    private var temperatureDisplay: some View {
        HStack(alignment: .top, spacing: 2) {
            Text(monitor.tempString)
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.5), value: monitor.temperature)

            Text("°C")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 12)
        }
    }

    private var heroStatsRow: some View {
        HStack(spacing: 14) {
            Label {
                Text(monitor.targetString)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.5), value: monitor.targetTemp)
            } icon: {
                Image(systemName: "scope")
            }

            Label {
                Text(monitor.alarms.isEmpty ? doorShortLabel : monitor.alarmSummary)
            } icon: {
                Image(systemName: monitor.alarms.isEmpty ? doorIcon : "exclamationmark.triangle.fill")
            }
        }
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.85))
    }

    private var doorShortLabel: String {
        monitor.doorOpen ? loc.t(.doorOpen) : loc.t(.doorOK)
    }

    private var doorIcon: String {
        monitor.doorOpen ? "door.left.hand.open" : "door.left.hand.closed"
    }

    private var heatBar: some View {
        VStack(alignment: .leading, spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.18))
                    Capsule()
                        .fill(.white.opacity(0.85))
                        .frame(width: max(geo.size.width * monitor.heatProgress, 6))
                        .animation(.spring(duration: 0.7), value: monitor.heatProgress)
                }
            }
            .frame(height: 4)

            HStack {
                Text("0°")
                Spacer()
                Text(loc.t(.targetShort, monitor.targetString))
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Control

    private var controlSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                targetTemperatureControl
                Spacer()
                powerButton
            }

            HStack(spacing: 8) {
                lightButton
                fanRunButton
                fanLevelMenu
                fanDurationMenu
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.background)
    }

    private var targetTemperatureControl: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(loc.t(.targetTemperature))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                stepperButton(systemName: "minus") { monitor.adjustTargetTemp(-1) }

                Text("\(monitor.targetTemp)°C")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .frame(minWidth: 60)
                    .multilineTextAlignment(.center)

                stepperButton(systemName: "plus") { monitor.adjustTargetTemp(1) }
            }
        }
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var powerButton: some View {
        Button(action: { monitor.setHeater(!monitor.heaterOn) }) {
            Image(systemName: "power")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(monitor.heaterOn ? .white : .secondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(monitor.heaterOn
                        ? Color.red
                        : Color.secondary.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }

    private var lightButton: some View {
        Button(action: { monitor.setLight(!monitor.lightOn) }) {
            Image(systemName: monitor.lightOn ? "lightbulb.fill" : "lightbulb")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(monitor.lightOn ? .yellow : .secondary)
                .frame(width: 36, height: 32)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(monitor.lightOn ? loc.t(.turnOffLight) : loc.t(.turnOnLight))
    }

    private var fanRunButton: some View {
        Button(action: {
            monitor.fanIsActive ? monitor.stopFan() : monitor.startFan()
        }) {
            Label(fanRunLabel, systemImage: monitor.fanIsActive ? "fan.fill" : "fan")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(monitor.fanIsActive ? .white : .primary)
                .frame(width: 74, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(monitor.fanIsActive ? Color.accentColor : Color.secondary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .help(monitor.fanIsActive ? loc.t(.turnOffFan) : loc.t(.startFanFor, monitor.fanDuration))
    }

    private var fanRunLabel: String {
        monitor.fanIsActive && monitor.fanRemainingSeconds > 0
            ? monitor.fanRemainingString
            : (monitor.fanIsActive ? loc.t(.stop) : loc.t(.start))
    }

    private var fanLevelMenu: some View {
        Menu {
            ForEach(1...3, id: \.self) { speed in
                Button(fanLabel(for: speed)) {
                    monitor.setFanLevel(speed)
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "wind")
                Text("\(monitor.fanLevel)")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 42, height: 32)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 42, height: 32)
        .help(loc.t(.fanLevelHelp, monitor.fanLevel))
    }

    private var fanDurationMenu: some View {
        Menu {
            ForEach([5, 10, 15, 30], id: \.self) { minutes in
                Button(loc.t(.minutesShort, minutes)) {
                    monitor.setFanDuration(minutes)
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "timer")
                Text("\(monitor.fanDuration)")
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 48, height: 32)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 48, height: 32)
        .help(loc.t(.fanDurationHelp, monitor.fanDuration))
    }

    private func fanLabel(for speed: Int) -> String {
        switch speed {
        case 1: return loc.t(.fanLow)
        case 2: return loc.t(.fanMedium)
        case 3: return loc.t(.fanHigh)
        default: return loc.t(.fanOff)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text(footerLabel)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            diagnosticsMenu

            Button(action: { withAnimation(.spring(duration: 0.25)) { showSettings = true } }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button(action: { monitor.fetch() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background)
    }

    private var diagnosticsMenu: some View {
        Menu {
            diagnosticRow(loc.t(.diagSaunaType), "\(monitor.saunaType)")
            diagnosticRow(loc.t(.diagSessionTime), durationLabel(minutes: monitor.saunaDuration))
            diagnosticRow(loc.t(.diagFanDuration), loc.t(.minutesShort, monitor.fanDuration))
            diagnosticRow(loc.t(.diagFanLevel), "\(monitor.displayedFanSpeed)")
            diagnosticRow(loc.t(.diagFanRegister), "\(monitor.fanSpeed)")
            diagnosticRow(loc.t(.diagHeatersActive), monitor.heaterElementsString)
            diagnosticRow(loc.t(.diagDoor), monitor.doorString)
            diagnosticRow(loc.t(.diagUptime), monitor.uptimeString)

            Divider()

            if monitor.alarms.isEmpty {
                Text(loc.t(.noAlarms))
            } else {
                ForEach(monitor.alarms) { alarm in
                    Label(alarm.label, systemImage: "exclamationmark.triangle.fill")
                }
            }
        } label: {
            Image(systemName: monitor.alarms.isEmpty ? "waveform.path.ecg" : "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(monitor.alarms.isEmpty ? Color.secondary : Color.orange)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .help(loc.t(.diagnostics))
    }

    private func diagnosticRow(_ title: String, _ value: String) -> some View {
        Text("\(title): \(value)")
    }

    private func durationLabel(minutes: Int) -> String {
        minutes == 0 ? loc.t(.defaultValue) : loc.t(.minutesShort, minutes)
    }

    private var footerLabel: String {
        if !monitor.isConnected { return loc.t(.noConnection) }
        guard let updated = monitor.lastUpdated else { return loc.t(.connecting) }
        return loc.t(.refreshedAt, updated.formatted(date: .omitted, time: .shortened))
    }
}
