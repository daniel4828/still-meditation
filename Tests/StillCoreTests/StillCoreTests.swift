import XCTest
@testable import StillCore

final class StillCoreTests: XCTestCase {
    func testPreparationAndRepeatingBoundaries() {
        let config = SessionSettings()
        XCTAssertEqual(config.preparation, 60)
        XCTAssertEqual(config.interval, 900)
        XCTAssertEqual(SessionSnapshot(elapsed: 59, settings: config).preparationRemaining, 1)
        let start = SessionSnapshot(elapsed: 60, settings: config)
        XCTAssertFalse(start.isPreparing)
        XCTAssertEqual(start.nextGong, 900)
        XCTAssertEqual(start.completedIntervals, 0)
        XCTAssertEqual(SessionSnapshot(elapsed: 960, settings: config).completedIntervals, 1)
        XCTAssertEqual(SessionSnapshot(elapsed: 60 + 900 * 100, settings: config).nextGong, 900)
    }
    func testNoPreparationAndPauseResume() {
        let config = SessionSettings(preparation: 0, interval: 15)
        XCTAssertFalse(SessionSnapshot(elapsed: 0, settings: config).isPreparing)
        var clock = SessionClock()
        clock.resume(at: 100)
        XCTAssertEqual(clock.elapsed(at: 110), 10)
        clock.pause(at: 110)
        XCTAssertEqual(clock.elapsed(at: 900), 10)
        clock.resume(at: 900)
        XCTAssertEqual(clock.elapsed(at: 905), 15)
        clock.reset()
        XCTAssertEqual(clock.elapsed(at: 1000), 0)
    }
    func testValidationAndPresetRoundTrip() throws {
        let bad = SessionSettings(preparation: -8, interval: 0, volume: 5)
        XCTAssertEqual(bad.preparation, 0)
        XCTAssertEqual(bad.interval, 15)
        XCTAssertEqual(bad.volume, 1)
        let preset = Preset(name: "Abend", settings: SessionSettings())
        let data = try JSONEncoder().encode([preset])
        XCTAssertEqual(try JSONDecoder().decode([Preset].self, from: data), [preset])
        let corrupt = Data(#"{"preparation":-10,"interval":0,"volume":9}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(SessionSettings.self, from: corrupt), bad)
    }
    func testWAVDurationAndGongEnvelope() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        defer { try? FileManager.default.removeItem(at: url) }
        try GongWave.write(to: url, duration: 15, includeGong: true)
        let data = try Data(contentsOf: url)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "RIFF")
        XCTAssertEqual(data.count, 44 + 15 * GongWave.sampleRate * 2)
        XCTAssertEqual(GongWave.sample(at: 0), 0, accuracy: 0.00001)
        XCTAssertEqual(GongWave.sample(at: 2.4), 0, accuracy: 0.00001)
        XCTAssertGreaterThan(abs(GongWave.sample(at: 0.123)), 0.001)
        XCTAssertTrue(data.suffix(100).allSatisfy { $0 == 0 })
    }
    func testPreparationWAVIsSilent() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        defer { try? FileManager.default.removeItem(at: url) }
        try GongWave.write(to: url, duration: 1, includeGong: false)
        XCTAssertTrue(try Data(contentsOf: url).dropFirst(44).allSatisfy { $0 == 0 })
    }
}
