import AVFoundation
import Foundation

@MainActor
final class AudioController {
    enum Event { case playing, waiting, interrupted(String), failed(String) }
    var onEvent: ((Event) -> Void)?
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var preview: AVAudioPlayer?
    private var playbackObservation: NSKeyValueObservation?
    private var errorObservation: NSKeyValueObservation?
    private var loopObservation: NSKeyValueObservation?
    private var notifications: [NSObjectProtocol] = []
    private var wantsPlayback = false
    private let directory = FileManager.default.temporaryDirectory.appendingPathComponent("StillAudio", isDirectory: true)

    init() {
        let center = NotificationCenter.default
        notifications.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  type == AVAudioSession.InterruptionType.began.rawValue else { return }
            Task { @MainActor in
                self?.pause()
                self?.onEvent?(.interrupted("Die Audiowiedergabe wurde unterbrochen. Setze die Sitzung fort, wenn du bereit bist."))
            }
        })
        notifications.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            guard let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
            Task { @MainActor in
                self?.pause()
                self?.onEvent?(.interrupted("Die Audioverbindung wurde getrennt. Prüfe den Lautsprecher, bevor du fortsetzt."))
            }
        })
        notifications.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.stop()
                self?.onEvent?(.failed("iOS hat die Audiowiedergabe zurückgesetzt. Bitte beende die Sitzung und starte neu."))
            }
        })
        notifications.append(center.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard self?.wantsPlayback == true else { return }
                self?.pause()
                self?.onEvent?(.failed("Die Audiospur konnte nicht weitergespielt werden. Bitte starte die Sitzung neu."))
            }
        })
    }

    private func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }

    func start(settings: SessionSettings) throws {
        stop()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let intervalURL = directory.appendingPathComponent("interval.wav")
        try GongWave.write(to: intervalURL, duration: settings.interval, includeGong: true)
        var initialItems: [AVPlayerItem] = []
        if settings.preparation > 0 {
            let preparationURL = directory.appendingPathComponent("preparation.wav")
            try GongWave.write(to: preparationURL, duration: settings.preparation, includeGong: false)
            initialItems.append(AVPlayerItem(url: preparationURL))
        }
        try activate()
        let queue = AVQueuePlayer(items: initialItems)
        queue.volume = Float(settings.volume)
        queue.automaticallyWaitsToMinimizeStalling = false
        queue.allowsExternalPlayback = false
        player = queue
        looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: intervalURL), timeRange: .invalid,
                                existingItemsOrdering: .loopingItemsFollowExistingItems)
        playbackObservation = queue.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor in
                guard let self, self.wantsPlayback, self.player?.timeControlStatus == status else { return }
                switch status {
                case .playing: self.onEvent?(.playing)
                case .waitingToPlayAtSpecifiedRate: self.onEvent?(.waiting)
                case .paused:
                    self.pause()
                    self.onEvent?(.interrupted("Die Wiedergabe wurde angehalten. Du kannst die Sitzung fortsetzen."))
                @unknown default: break
                }
            }
        }
        errorObservation = queue.observe(\.status, options: [.new]) { [weak self] player, _ in
            guard player.status == .failed else { return }
            Task { @MainActor in
                self?.pause()
                self?.onEvent?(.failed("Audio konnte nicht gestartet werden. Bitte beende die Sitzung und versuche es erneut."))
            }
        }
        loopObservation = looper?.observe(\.status, options: [.new]) { [weak self] looper, _ in
            guard looper.status == .failed else { return }
            Task { @MainActor in
                self?.pause()
                self?.onEvent?(.failed("Die Gong-Wiederholung ist fehlgeschlagen. Bitte starte die Sitzung neu."))
            }
        }
        wantsPlayback = true
        queue.play()
    }

    func pause() {
        wantsPlayback = false
        player?.pause()
        preview?.stop()
    }

    func resume() throws {
        guard let player, player.status != .failed, player.currentItem != nil,
              looper?.status != .failed else {
            throw NSError(domain: "Still", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bitte beende die Sitzung und starte sie neu."])
        }
        try activate()
        wantsPlayback = true
        player.play()
    }

    func stop() {
        wantsPlayback = false
        playbackObservation = nil; errorObservation = nil; loopObservation = nil
        player?.pause()
        looper?.disableLooping()
        looper = nil
        player?.removeAllItems()
        player = nil
        preview?.stop(); preview = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func previewGong(volume: Double) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("preview.wav")
        try GongWave.write(to: url, duration: 3, includeGong: true)
        try activate()
        preview = try AVAudioPlayer(contentsOf: url)
        preview?.volume = Float(volume)
        guard preview?.play() == true else {
            throw NSError(domain: "Still", code: 2, userInfo: [NSLocalizedDescriptionKey: "Die Gong-Vorschau konnte nicht abgespielt werden."])
        }
    }
}
