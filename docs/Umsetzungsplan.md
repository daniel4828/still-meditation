# Still – Umsetzungsplan

Ziel: Eine schlichte persönliche Meditationsuhr mit endlosen Gongs.
Architektur: SwiftUI-Oberfläche, getrennte Audiowiedergabe, plattformunabhängiger Swift-Kern.
Technik: Swift 5.9+, iOS 17+, AVFoundation, Foundation, XCTest.
Entwurf: Entwurf.md. Umsetzung direkt in dieser Sitzung entsprechend dem ausdrücklichen Auftrag, ohne zusätzliche Freigabeschritte.

1. Tests für Vorbereitung, Intervallgrenzen, monotone Zeit/Pause, validierte und gespeicherte Presets sowie WAV-Signale schreiben und fehlend beobachten.
2. Core in Sources/StillCore implementieren; Tests vollständig ausführen.
3. App/AudioController.swift mit AVQueuePlayer/AVPlayerLooper, playback-Session, Unterbrechungen und Routewechseln implementieren.
4. App/SessionModel.swift und schlichte SwiftUI-Oberfläche mit Presets, Zeiteinstellungen, Lautstärke und Vorschau implementieren.
5. Öffnungsfertiges Xcode-Projekt, deutsche Installationsanleitung, Gerätestestliste und GitHub-Actions-Build hinzufügen.
6. Tests und iOS-Build prüfen, öffentliches GitHub-Repository erstellen und Änderungen pushen. Tatsächlich ausgeführte Prüfungen getrennt von noch offenen Gerätetests nennen.

Prüfschwerpunkte: keine Vorbereitung; exakte 15-Minuten-Grenze; Pause während der Vorbereitung; unterbrochene Audiositzung; ungültige gespeicherte Daten; lange Intervalle ohne große RAM-Belegung; Wechsel zu Lautsprecher nach Entfernen von Kopfhörern.
