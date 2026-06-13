import SwiftUI
import AppKit

@main
struct SaunaBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var monitor = SaunaMonitor()

    var body: some Scene {
        MenuBarExtra {
            if monitor.config != nil {
                SaunaView().environmentObject(monitor)
            } else {
                DiscoveryView().environmentObject(monitor)
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: monitor.statusIcon)
                    .imageScale(.medium)
                Text(monitor.labelText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(monitor.statusColor)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
