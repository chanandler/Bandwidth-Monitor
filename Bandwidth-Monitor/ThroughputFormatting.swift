import Foundation
import SwiftUI

public enum ThroughputUnits: String {
    case mbps // megabits per second (decimal)
    case mBps // megabytes per second (decimal)
}

public func formatThroughput(bytesPerSecond: Double, units: ThroughputUnits) -> String {
    switch units {
    case .mbps:
        let value = (bytesPerSecond * 8.0) / 1_000_000.0
        return String(format: "%.2f Mbps", value)
    case .mBps:
        let value = bytesPerSecond / 1_000_000.0
        return String(format: "%.2f MB/s", value)
    }
}

public struct ThroughputFormatter {
    public static let shared = ThroughputFormatter()
    private let formatter: NumberFormatter
    
    private init() {
        formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
    }
    
    public func string(from bytesPerSecond: Double, units: ThroughputUnits) -> String {
        switch units {
        case .mbps:
            let value = (bytesPerSecond * 8.0) / 1_000_000.0
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "0.00"
            return "\(formatted) Mbps"
        case .mBps:
            let value = bytesPerSecond / 1_000_000.0
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "0.00"
            return "\(formatted) MB/s"
        }
    }
}

@propertyWrapper
public struct ThroughputUnitsStorage {
    @AppStorage("ThroughputUnitsKey")
    private var rawValue: String = ThroughputUnits.mbps.rawValue
    
    public var wrappedValue: ThroughputUnits {
        get {
            ThroughputUnits(rawValue: rawValue) ?? .mbps
        }
        set {
            rawValue = newValue.rawValue
        }
    }
    
    public init() {}
}
