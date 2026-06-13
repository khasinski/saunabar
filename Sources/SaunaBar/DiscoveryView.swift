import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var monitor: SaunaMonitor
    @ObservedObject private var loc = Localizer.shared
    @StateObject private var discovery = SaunaDiscovery()

    @State private var showManual = false
    @State private var manualHost = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            if showManual {
                Divider()
                manualEntry
            }
        }
        .frame(width: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { discovery.startScan() }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.15, blue: 0.2),
                         Color(red: 0.1,  green: 0.1,  blue: 0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: "wifi.router.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.9))
                Text(loc.t(.searchingSauna))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(loc.t(.scanningSubtitle))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 12) {
            if discovery.isScanning {
                scanningRow
            }

            if !discovery.candidates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.t(.foundDevices))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ForEach(discovery.candidates, id: \.host) { candidate in
                        candidateRow(candidate)
                    }
                }
            } else if !discovery.isScanning {
                Text(discovery.statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            HStack {
                Button(discovery.isScanning ? loc.t(.scanning) : loc.t(.scanAgain)) {
                    discovery.startScan()
                }
                .disabled(discovery.isScanning)
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                Spacer()

                Button(showManual ? loc.t(.hide) : loc.t(.enterIPManually)) {
                    showManual.toggle()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.background)
    }

    private var scanningRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule().fill(Color.accentColor.opacity(0.8))
                        .frame(width: geo.size.width * discovery.progress)
                        .animation(.linear(duration: 0.3), value: discovery.progress)
                }
            }
            .frame(height: 4)

            Text(discovery.statusText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func candidateRow(_ config: SaunaConfig) -> some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 13))
            VStack(alignment: .leading, spacing: 1) {
                Text(config.host)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                Text(loc.t(.portLabel, Int(config.port)))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(loc.t(.connect)) { connect(config) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Manual entry

    private var manualEntry: some View {
        HStack(spacing: 8) {
            TextField("192.168.0.x", text: $manualHost)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
                .frame(maxWidth: .infinity)
                .onSubmit { connectManual() }

            Button(loc.t(.connect)) { connectManual() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(manualHost.isEmpty)
        }
        .padding(16)
        .background(.background)
    }

    // MARK: - Actions

    private func connect(_ config: SaunaConfig) {
        monitor.apply(config: config)
    }

    private func connectManual() {
        let host = manualHost.trimmingCharacters(in: .whitespaces)
        guard !host.isEmpty else { return }
        connect(SaunaConfig(host: host, port: 502, name: "Sauna"))
    }
}
