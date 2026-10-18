import Foundation

/// PCM WAV with a sparse silent tail: bounded memory even for two-hour intervals.
public enum GongWave {
    public static let sampleRate = 24_000
    public static let gongDuration = 2.4

    public static func sample(at time: Double) -> Double {
        guard time > 0, time < gongDuration else { return 0 }
        let attack = 1 - exp(-time / 0.012)
        let decay = exp(-time / 0.62)
        let release = min(1, (gongDuration - time) / 0.25)
        let modes = sin(2 * .pi * 220 * time)
            + 0.35 * sin(2 * .pi * 442.2 * time) * exp(-time / 0.8)
            + 0.17 * sin(2 * .pi * 592.4 * time) * exp(-time / 0.45)
        return modes * attack * decay * release * 0.55
    }

    public static func write(to url: URL, duration: Int, includeGong: Bool) throws {
        guard duration > 0, duration <= 7200 else { throw CocoaError(.fileWriteInvalidFileName) }
        let byteCount = duration * sampleRate * 2
        var header = Data()
        func ascii(_ text: String) { header.append(contentsOf: text.utf8) }
        func uint16(_ value: UInt16) {
            header.append(UInt8(value & 255)); header.append(UInt8(value >> 8))
        }
        func uint32(_ value: UInt32) {
            for shift in stride(from: 0, to: 32, by: 8) { header.append(UInt8((value >> shift) & 255)) }
        }
        ascii("RIFF"); uint32(UInt32(36 + byteCount)); ascii("WAVEfmt ")
        uint32(16); uint16(1); uint16(1); uint32(UInt32(sampleRate))
        uint32(UInt32(sampleRate * 2)); uint16(2); uint16(16)
        ascii("data"); uint32(UInt32(byteCount))
        try header.write(to: url, options: .atomic)
        let file = try FileHandle(forWritingTo: url)
        defer { try? file.close() }
        try file.seekToEnd()
        if includeGong {
            var samples = Data(capacity: Int(gongDuration * Double(sampleRate)) * 2)
            for index in 0..<min(duration * sampleRate, Int(gongDuration * Double(sampleRate))) {
                let value = Int16((sample(at: Double(index) / Double(sampleRate)) * 32767).rounded())
                let bits = UInt16(bitPattern: value)
                samples.append(UInt8(bits & 255)); samples.append(UInt8(bits >> 8))
            }
            try file.write(contentsOf: samples)
        }
        try file.truncate(atOffset: UInt64(44 + byteCount))
    }
}
