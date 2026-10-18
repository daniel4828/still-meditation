import Combine
import Foundation

@MainActor
final class SessionModel: ObservableObject {
    enum State { case idle, loading, running, paused }
    @Published private(set) var state: State = .idle
    @Published private(set) var elapsed: Double = 0
    @Published var settings: SessionSettings { didSet { persist() } }
    @Published private(set) var presets: [Preset]
    @Published var message: String?
    private var clock = SessionClock()
    private let audio = AudioController()
    private var timer: AnyCancellable?
    private let defaults: UserDefaults
    private var now: Double { ProcessInfo.processInfo.systemUptime }
    var snapshot: SessionSnapshot { SessionSnapshot(elapsed: elapsed, settings: settings) }
    var hasSession: Bool { state != .idle }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = defaults.data(forKey: "settings").flatMap { try? JSONDecoder().decode(SessionSettings.self, from: $0) } ?? SessionSettings()
        presets = defaults.data(forKey: "presets").flatMap { try? JSONDecoder().decode([Preset].self, from: $0) } ?? []
        audio.onEvent = { [weak self] event in
            guard let self, self.hasSession else { return }
            switch event {
            case .playing:
                self.clock.resume(at: self.now)
                self.state = .running
            case .waiting:
                self.clock.pause(at: self.now)
                self.state = .loading
            case .interrupted(let text), .failed(let text):
                self.clock.pause(at: self.now)
                self.elapsed = self.clock.elapsed(at: self.now)
                self.state = .paused
                self.message = text
            }
        }
        timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            self.elapsed = self.clock.elapsed(at: self.now)
        }
    }

    func toggle() {
        do {
            switch state {
            case .idle:
                clock.reset(); elapsed = 0; state = .loading
                try audio.start(settings: settings)
            case .running, .loading:
                pause()
            case .paused:
                state = .loading
                try audio.resume()
            }
        } catch {
            audio.stop(); clock.reset(); elapsed = 0; state = .idle
            message = "无法播放声音。请检查媒体音量和音频连接后重试。"
        }
    }

    func pause() {
        audio.pause()
        clock.pause(at: now)
        elapsed = clock.elapsed(at: now)
        state = .paused
    }

    func stop() {
        audio.stop(); clock.reset(); elapsed = 0; state = .idle
    }

    func preview() {
        do { try audio.previewGong(volume: settings.volume) }
        catch { message = "无法播放声音。请检查媒体音量和音频连接后重试。" }
    }

    func savePreset(name: String) {
        let clean = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        guard !clean.isEmpty else { return }
        presets.append(Preset(name: clean, settings: settings))
        persist()
    }

    func deletePresets(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { presets.remove(at: index) }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: "settings") }
        if let data = try? JSONEncoder().encode(presets) { defaults.set(data, forKey: "presets") }
    }

    static func time(_ seconds: Double, countdown: Bool = false) -> String {
        let whole = max(0, Int(countdown ? ceil(seconds) : floor(seconds)))
        if whole >= 3600 { return String(format: "%d:%02d:%02d", whole / 3600, whole / 60 % 60, whole % 60) }
        return String(format: "%02d:%02d", whole / 60, whole % 60)
    }
}
