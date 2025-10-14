import Foundation
import Combine

public struct InterfaceStats {
    public let name: String
    public let bytesIn: UInt64
    public let bytesOut: UInt64
}

public enum NetworkStatsReader {
    public static func readInterfaces() -> [InterfaceStats] {
        var result: [InterfaceStats] = []
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return result }
        defer { freeifaddrs(ifaddrPtr) }

        var ptr = first
        while true {
            let ifa = ptr.pointee
            let name = String(cString: ifa.ifa_name)
            if let dataPtr = ifa.ifa_data?.assumingMemoryBound(to: if_data.self) {
                let data = dataPtr.pointee
                if (ifa.ifa_flags & UInt32(IFF_LOOPBACK)) == 0 {
                    result.append(InterfaceStats(name: name,
                                                 bytesIn: UInt64(data.ifi_ibytes),
                                                 bytesOut: UInt64(data.ifi_obytes)))
                }
            }
            guard let next = ifa.ifa_next else { break }
            ptr = next
        }
        return result
    }
}

@MainActor
public final class BandwidthMonitor: ObservableObject {
    public struct Speeds {
        public let timestamp: Date
        public let totalInBps: Double
        public let totalOutBps: Double
        public let perInterface: [String: (inBps: Double, outBps: Double)]
    }

    @Published public var latest: Speeds?

    private var lastSample: [String: (inBytes: UInt64, outBytes: UInt64)] = [:]
    private var task: Task<Void, Never>?

    public init() {}

    public func start() {
        stop()
        task = Task.detached { [weak self] in
            var lastTime = Date()
            while !Task.isCancelled {
                let now = Date()
                let dt = now.timeIntervalSince(lastTime)
                lastTime = now

                let interfaces = NetworkStatsReader.readInterfaces()

                await MainActor.run {
                    var per: [String: (Double, Double)] = [:]
                    var totalIn: Double = 0
                    var totalOut: Double = 0

                    for s in interfaces {
                        let prev = self?.lastSample[s.name]
                        let dIn = prev != nil ? Double(s.bytesIn &- prev!.inBytes) : 0
                        let dOut = prev != nil ? Double(s.bytesOut &- prev!.outBytes) : 0
                        let inBps = dt > 0 ? dIn / dt : 0
                        let outBps = dt > 0 ? dOut / dt : 0
                        per[s.name] = (inBps, outBps)
                        totalIn += inBps
                        totalOut += outBps
                    }

                    self?.lastSample = Dictionary(uniqueKeysWithValues: interfaces.map { ($0.name, ($0.bytesIn, $0.bytesOut)) })
                    self?.latest = Speeds(timestamp: now, totalInBps: totalIn, totalOutBps: totalOut, perInterface: per)
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }
}
