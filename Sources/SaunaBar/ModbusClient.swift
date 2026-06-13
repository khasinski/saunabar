import Foundation
import Network

class ModbusClient {
    let host: String
    let port: UInt16

    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    func readRegisters(start: UInt16, count: UInt16, completion: @escaping (Result<[UInt16], Error>) -> Void) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        let conn = NWConnection(to: endpoint, using: .tcp)

        // Strong capture keeps conn alive until cancel() is called
        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                var pdu = Data([0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01, 0x03])
                pdu.append(UInt8(start >> 8))
                pdu.append(UInt8(start & 0xFF))
                pdu.append(UInt8(count >> 8))
                pdu.append(UInt8(count & 0xFF))

                conn.send(content: pdu, completion: .contentProcessed { err in
                    if let err = err {
                        completion(.failure(err))
                        conn.cancel()
                        return
                    }
                    conn.receive(minimumIncompleteLength: 9, maximumLength: 256) { data, _, _, err in
                        defer { conn.cancel() }
                        if let err = err {
                            completion(.failure(err))
                            return
                        }
                        guard let data = data, data.count >= 9, data[7] == 0x03 else {
                            completion(.failure(NSError(domain: "Modbus", code: -1)))
                            return
                        }
                        let byteCount = Int(data[8])
                        let regs = stride(from: 9, to: min(9 + byteCount, data.count), by: 2).map { i in
                            UInt16(data[i]) << 8 | UInt16(data[i + 1])
                        }
                        completion(.success(regs))
                    }
                })

            case .failed(let err), .waiting(let err):
                completion(.failure(err))
                conn.cancel()

            default:
                break
            }
        }

        conn.start(queue: .global(qos: .utility))
    }

    func writeRegister(addr: UInt16, value: UInt16, completion: @escaping (Bool) -> Void) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        let conn = NWConnection(to: endpoint, using: .tcp)

        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                var pdu = Data([0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x01, 0x06])
                pdu.append(UInt8(addr >> 8)); pdu.append(UInt8(addr & 0xFF))
                pdu.append(UInt8(value >> 8)); pdu.append(UInt8(value & 0xFF))

                conn.send(content: pdu, completion: .contentProcessed { err in
                    guard err == nil else { completion(false); conn.cancel(); return }
                    conn.receive(minimumIncompleteLength: 12, maximumLength: 64) { data, _, _, _ in
                        defer { conn.cancel() }
                        completion(data?.count ?? 0 >= 12 && data![7] == 0x06)
                    }
                })
            case .failed(let err), .waiting(let err):
                _ = err
                completion(false)
                conn.cancel()
            default: break
            }
        }
        conn.start(queue: .global(qos: .utility))
    }
}
