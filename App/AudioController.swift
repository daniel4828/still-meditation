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
                self?.onEvent?(.interrupted("声音播放已中断。准备好后，请继续冥想。"))
            }
        })
        notifications.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            guard let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
            Task { @MainActor in
                self?.pause()
                self?.onEvent?(.interrupted("音频连接已断开。继续前，请先检查声音会从哪里播放。"))
            }
        })
        notifications.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.stop()
                self?.onEvent?(.failed("iOS 已重置声音播放。请结束本次冥想，然后重新开始。"))
            }
        })
        notifications.append(center.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard self?.wantsPlayback == true else { return }
                self?.pause()
                self?.onEvent?(.failed("声音无法继续播放。请重新开始冥想。"))
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
                    self.onEvent?(.interrupted("声音播放已暂停。你可以继续冥想。"))
                @unknown default: break
                }
            }
        }
        errorObservation = queue.observe(\.status, options: [.new]) { [weak self] player, _ in
            guard player.status == .failed else { return }
            Task { @MainActor in
                self?.pause()
                self?.onEvent?(.failed("无法开始播放声音。请结束本次冥想，然后重试。"))
            }
        }
        loopObservation = looper?.observe(\.status, options: [.new]) { [weak self] looper, _ in
            guard looper.status == .failed else { return }
            Task { @MainActor in
                self?.pause()
                self?.onEvent?(.failed("钟声无法循环播放。请重新开始冥想。"))
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
            throw NSError(domain: "Still", code: 1, userInfo: [NSLocalizedDescriptionKey: "请结束本次冥想，然后重新开始。"])
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
            throw NSError(domain: "Still", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法试听钟声。请检查媒体音量和音频连接后重试。"])
        }
    }
}
