# Still

Private, schlichte iPhone-App, iOS 17+, SwiftUI, ohne Abos, Werbung, Netzwerkzugriffe oder externe Bibliotheken.

- Ein Bildschirm: Vorbereitungs-Countdown, danach aufwärts laufende Meditationszeit; nächster Gong, Start/Pause/Fortsetzen/Beenden.
- Standard: 60 Sekunden Vorbereitung, dann Startgong und endlos alle 900 Sekunden ein kurzer Gong.
- Einstellungen: Vorbereitung 0–300 Sekunden, Intervall 15–7200 Sekunden, Gong-Lautstärke und benannte lokale Presets, löschbar. Während einer Sitzung gesperrt.
- Unaufdringliche Systemfarben, viel Platz, große Ziffern, Dynamic Type und VoiceOver. Deutsche Oberfläche.
- AVAudioSession playback und Hintergrundmodus audio. AVQueuePlayer spielt eine lokal erzeugte PCM-Datei für die Vorbereitung, AVPlayerLooper danach eine Intervall-Datei mit Gong am Anfang und Stille danach. Die Audiospur selbst legt die Gongzeiten fest; kein Hintergrund-Timer und keine Mitteilungsberechtigung.
- Gong: selbst erzeugte weiche Klangschale, 2,4 Sekunden inklusive weichem Ende. Keine fremden Audiodateien.
- Telefonanrufe, verlorene Kopfhörer und Audiofehler halten die Sitzung an; Fortsetzung ausdrücklich per Taste. Kein automatischer Neustart nach Beenden der App.
- Die Stoppuhr verwendet monotone Systemzeit. Pausen zählen nicht mit. Audio-Unterbrechungen werden berücksichtigt; verbleibende Startverzögerungen sind auf dem Gerät zu testen.
- Installation über Xcode mit persönlichem Apple Account; kostenlose Signatur läuft nach sieben Tagen ab. Kein fertiger App-Store-Download oder TestFlight ohne Apple-Entwicklerkonto.

Prüfung: Swift-Pakettests für Zeitgrenzen, Pause/Fortsetzung, Preset-Daten und PCM-Dauer/Signal; iOS-Build über GitHub Actions. Reale Sperrbildschirm-/Fokus-/Kopfhörer-Tests sind vor verlässlichem Einsatz notwendig.
