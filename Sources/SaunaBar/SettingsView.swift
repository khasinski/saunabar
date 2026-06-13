import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: SaunaMonitor
    @ObservedObject private var loc = Localizer.shared
    var onBack: () -> Void

    @State private var host: String = ""
    @State private var port: String = ""
    @State private var refreshInterval: Int = 15

    private let intervals = [5, 10, 15, 30, 60]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 20) {
                    deviceSection
                    pollingSection
                    languageSection
                    saveButton
                    forgetButton
                }
                .padding(16)
            }
            .background(.background)
        }
        .frame(width: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { loadValues() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(loc.t(.back))
                        .font(.system(size: 13))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(loc.t(.settings))
                .font(.system(size: 14, weight: .semibold, design: .rounded))

            Spacer()

            // visual balance
            Text(loc.t(.back)).font(.system(size: 13)).foregroundStyle(.clear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background)
    }

    // MARK: - Sections

    private var deviceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(loc.t(.device))
            card {
                row(label: loc.t(.ipAddress)) {
                    TextField("192.168.0.x", text: $host)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                divider
                row(label: loc.t(.port)) {
                    TextField("502", text: $port)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: 60)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var pollingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(loc.t(.refresh))
            card {
                row(label: loc.t(.everyHowManySeconds)) {
                    Picker("", selection: $refreshInterval) {
                        ForEach(intervals, id: \.self) { i in
                            Text(loc.t(.secondsShort, i)).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(loc.t(.language))
            card {
                row(label: loc.t(.language)) {
                    Picker("", selection: $loc.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(loc.t(.saveSettings))
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!hasChanges)
    }

    private var forgetButton: some View {
        Button(action: { monitor.forget() }) {
            Label(loc.t(.forgetDevice), systemImage: "trash")
                .font(.system(size: 12))
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 4)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
    }

    private var divider: some View {
        Divider().padding(.leading, 12)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.secondary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func row<V: View>(label: String, @ViewBuilder content: () -> V) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
            Spacer()
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    // MARK: - Logic

    private var hasChanges: Bool {
        guard let cfg = monitor.config else { return false }
        return host != cfg.host
            || (UInt16(port) ?? 502) != cfg.port
            || refreshInterval != cfg.refreshInterval
    }

    private func loadValues() {
        guard let cfg = monitor.config else { return }
        host = cfg.host
        port = "\(cfg.port)"
        refreshInterval = cfg.refreshInterval
    }

    private func save() {
        guard var cfg = monitor.config else { return }
        cfg.host    = host.trimmingCharacters(in: .whitespaces)
        cfg.port    = UInt16(port) ?? 502
        cfg.refreshInterval = refreshInterval
        monitor.apply(config: cfg)
        onBack()
    }
}
