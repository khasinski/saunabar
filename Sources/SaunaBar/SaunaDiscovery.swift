import Foundation
import Network
import Darwin

class SaunaDiscovery: ObservableObject {
    @Published var isScanning   = false
    @Published var progress: Double = 0
    @Published var statusText   = ""
    @Published var candidates: [SaunaConfig] = []

    private let scanQueue = DispatchQueue(label: "saunabar.discovery", attributes: .concurrent)

    func startScan() {
        guard !isScanning else { return }
        isScanning  = true
        candidates  = []
        progress    = 0
        statusText  = Localizer.shared.t(.detectingNetwork)

        // Run entire scan loop on background thread — never block the main thread.
        scanQueue.async {
            guard let subnet = self.localSubnet() else {
                DispatchQueue.main.async {
                    self.statusText = Localizer.shared.t(.cannotDetectNetwork)
                    self.isScanning = false
                }
                return
            }

            DispatchQueue.main.async { self.statusText = Localizer.shared.t(.scanningSubnet, subnet) }

            let total   = 254
            var checked = 0
            let lock    = NSLock()
            let group   = DispatchGroup()
            let sem     = DispatchSemaphore(value: 30)

            for i in 1...total {
                let host = "\(subnet).\(i)"
                group.enter()
                sem.wait()  // blocks background thread only
                self.scanQueue.async {
                    self.probe(host: host) { config in
                        sem.signal()
                        lock.lock()
                        checked += 1
                        let p = Double(checked) / Double(total)
                        let found = config
                        lock.unlock()

                        DispatchQueue.main.async {
                            self.progress   = p
                            self.statusText = Localizer.shared.t(.checkingHost, host)
                            if let found { self.candidates.append(found) }
                        }
                        group.leave()
                    }
                }
            }

            group.wait()
            DispatchQueue.main.async {
                self.isScanning = false
                if self.candidates.isEmpty {
                    self.statusText = Localizer.shared.t(.noDeviceFound)
                } else {
                    self.statusText = Localizer.shared.t(.foundDeviceCount, self.candidates.count)
                }
            }
        }
    }

    // MARK: - Probe single host

    private func probe(host: String, completion: @escaping (SaunaConfig?) -> Void) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: 502)!
        )
        let conn = NWConnection(to: endpoint, using: .tcp)

        // Guard against double-completion (timeout race vs normal path).
        let lock = NSLock()
        var finished = false
        func finish(_ result: SaunaConfig?) {
            lock.lock(); defer { lock.unlock() }
            guard !finished else { return }
            finished = true
            conn.cancel()
            completion(result)
        }

        // Hard timeout — unreachable hosts never return .failed in reasonable time.
        scanQueue.asyncAfter(deadline: .now() + 2.0) { finish(nil) }

        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let pdu = Data([0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01, 0x03, 0x00, 0x64, 0x00, 0x02])
                conn.send(content: pdu, completion: .contentProcessed { _ in
                    conn.receive(minimumIncompleteLength: 9, maximumLength: 64) { data, _, _, _ in
                        guard let data, data.count >= 13, data[7] == 0x03 else {
                            finish(nil); return
                        }
                        let temp = Int(Int16(bitPattern: UInt16(data[9])  << 8 | UInt16(data[10])))
                        let hum  = Int(UInt16(data[11]) << 8 | UInt16(data[12]))
                        if (-20...130).contains(temp) && (0...100).contains(hum) {
                            finish(SaunaConfig(host: host, port: 502, name: "Sauna"))
                        } else {
                            finish(nil)
                        }
                    }
                })
            case .failed, .waiting:
                finish(nil)
            default: break
            }
        }
        conn.start(queue: scanQueue)
    }

    // MARK: - Local subnet detection

    private func localSubnet() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while let cur = ptr {
            defer { ptr = cur.pointee.ifa_next }
            guard let addr = cur.pointee.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: cur.pointee.ifa_name)
            guard name.hasPrefix("en") else { continue }

            var ip = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sin in
                var inAddr = sin.pointee.sin_addr
                inet_ntop(AF_INET, &inAddr, &ip, socklen_t(INET_ADDRSTRLEN))
            }
            let ipStr = String(cString: ip)
            guard ipStr != "127.0.0.1", !ipStr.isEmpty else { continue }
            let parts = ipStr.split(separator: ".")
            if parts.count == 4 {
                return "\(parts[0]).\(parts[1]).\(parts[2])"
            }
        }
        return nil
    }
}
