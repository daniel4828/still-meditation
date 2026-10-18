import Foundation

public struct SessionSettings: Codable, Equatable, Sendable {
    public let preparation: Int
    public let interval: Int
    public let volume: Double

    public init(preparation: Int = 60, interval: Int = 900, volume: Double = 0.65) {
        self.preparation = min(300, max(0, preparation))
        self.interval = min(7200, max(15, interval))
        self.volume = volume.isFinite ? min(1, max(0.05, volume)) : 0.65
    }

    enum CodingKeys: String, CodingKey { case preparation, interval, volume }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(preparation: try values.decode(Int.self, forKey: .preparation),
                  interval: try values.decode(Int.self, forKey: .interval),
                  volume: try values.decode(Double.self, forKey: .volume))
    }
}

public struct Preset: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var settings: SessionSettings
    public init(id: UUID = UUID(), name: String, settings: SessionSettings) {
        self.id = id
        self.name = name
        self.settings = settings
    }
}

public struct SessionSnapshot: Sendable {
    public let preparationRemaining: Double
    public let meditationElapsed: Double
    public let nextGong: Double
    public let completedIntervals: Int
    public var isPreparing: Bool { preparationRemaining > 0 }

    public init(elapsed: Double, settings: SessionSettings) {
        let safeElapsed = elapsed.isFinite ? max(0, elapsed) : 0
        preparationRemaining = max(0, Double(settings.preparation) - safeElapsed)
        meditationElapsed = max(0, safeElapsed - Double(settings.preparation))
        let interval = Double(settings.interval)
        completedIntervals = Int(meditationElapsed / interval)
        nextGong = preparationRemaining > 0 ? preparationRemaining : interval - meditationElapsed.truncatingRemainder(dividingBy: interval)
    }
}

public struct SessionClock: Sendable {
    private var accumulated: Double = 0
    private var startedAt: Double?
    public init() {}
    public func elapsed(at now: Double) -> Double {
        accumulated + (startedAt.map { max(0, now - $0) } ?? 0)
    }
    public mutating func resume(at now: Double) {
        guard startedAt == nil else { return }
        startedAt = now
    }
    public mutating func pause(at now: Double) {
        accumulated = elapsed(at: now)
        startedAt = nil
    }
    public mutating func reset() { accumulated = 0; startedAt = nil }
}
