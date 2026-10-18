# Still

Eine schlichte Meditationsuhr fürs iPhone. SwiftUI, iOS 17 oder neuer, vollständig offline. Keine Werbung, kein Konto, kein Abo.

- Vorbereitung: 0 bis 5 Minuten, Standard 1 Minute.
- Kurzer, sanfter Startgong nach der Vorbereitung.
- Endlose Gong-Intervalle: 15 Sekunden bis 2 Stunden, Standard 15 Minuten.
- Aufwärts laufende Meditationszeit, nächster Gong, Pause/Fortsetzen/Beenden.
- Eigene Presets auf dem Gerät speichern und per Wischgeste löschen.
- Eigener synthetischer Klangschalen-Ton mit 2,4 Sekunden Dauer, Lautstärke und Vorschau.
- Helle und dunkle Systemdarstellung, große Schrift, VoiceOver-Beschriftungen.

## Auf dein iPhone installieren

Ein GitHub-Repository ist kein App-Store-Download. Für diese persönliche App ist der direkte Weg über den Mac kostenlos:

1. Installiere **Xcode** aus dem Mac App Store und öffne es einmal. Stimme den Bedingungen zu und lasse das iOS SDK installieren. Nur die Command Line Tools reichen nicht aus.
2. Öffne **Still.xcodeproj** aus diesem Ordner. Das Projekt ist fertig vorbereitet; es sind keine Zusatzpakete oder Projektgeneratoren nötig.
3. In Xcode unter **Settings → Accounts** mit deinem Apple Account anmelden. Die Xcode-Oberfläche verwendet meist englische Bezeichnungen, auch auf einem Mac mit chinesischer Systemsprache.
4. Links das blaue Projekt **Still** wählen, dann unter **TARGETS → Still → Signing & Capabilities** dein **Personal Team** wählen. **Automatically manage signing** eingeschaltet lassen. Bei Konflikten den Bundle Identifier `de.daniel4828.still` auf einen eindeutigen Wert ändern.
5. iPhone per Kabel anschließen, entsperren und der Verbindung vertrauen. Auf dem iPhone gegebenenfalls unter **设置 → 隐私与安全性 → 开发者模式** den Entwicklermodus aktivieren; bei deutscher iPhone-Sprache: **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus**. Der Schalter erscheint unter Umständen erst nach der ersten Verbindung mit Xcode. Das iPhone startet dabei neu.
6. Oben in Xcode dein iPhone als Ziel wählen und die Wiedergabe-Taste **▶** drücken. Bei einem Hinweis zur Entwickleridentität auf dem iPhone unter **设置 → 通用 → VPN与设备管理** bzw. **Einstellungen → Allgemein → VPN und Geräteverwaltung** dem eigenen Entwicklerprofil vertrauen.
7. Die App **Still** ist jetzt auf dem Home-Bildschirm. Du kannst das Kabel entfernen.

**Kostenloses Apple-Konto:** Die Signatur gilt nur sieben Tage. Danach auf demselben iPhone aus Xcode erneut starten. Die App nicht vorher löschen, damit ihre Einstellungen erhalten bleiben. Für längere Signaturen oder TestFlight ist eine kostenpflichtige Apple-Developer-Mitgliedschaft erforderlich; ein öffentliches GitHub-Repository ersetzt sie nicht.

## Bildschirm aus und „Nicht stören“

Still verwendet `AVAudioSession.Category.playback` und `UIBackgroundModes = audio`. Der Gong ist Medienwiedergabe und keine Benachrichtigung. Eine lokale Audiospur enthält Gong und stille Zwischenräume; iOS spielt diese Spur über `AVQueuePlayer` / `AVPlayerLooper` wiederholt ab. Es gibt keinen JavaScript- oder Hintergrund-Timer, der nach der Bildschirmsperre weiterlaufen müsste.

Die Architektur ist für gesperrten Bildschirm und aktiven Fokus „Nicht stören“ vorgesehen. Eine Zusicherung für jedes Gerät/jede iOS-Version ist ohne realen Test nicht möglich. Medienlautstärke null, ein umgeleiteter Bluetooth-Ausgang, Telefonanrufe oder vollständiges Beenden der App können die hörbare Wiedergabe verhindern. Eine laufende Sitzung wird nicht nach einem Neustart oder Beenden wiederhergestellt.

- Vorher **Gong anhören** testen und die iPhone-Medienlautstärke passend einstellen.
- Einmal starten, danach Bildschirm sperren. Die App nicht im App-Umschalter wegwischen.
- Entfernte Kopfhörer oder Anrufe pausieren die Sitzung; danach bewusst fortsetzen.
- Eine aktive Audiositzung kann andere Medien unterbrechen und braucht mehr Akku als ein inaktiver Timer. Die Stille ist Teil der Meditations-Audiospur. App-Store-Freigabe ist weder beantragt noch zugesichert.

## Vor dem ersten echten Einsatz testen

1. Vorbereitung auf 5 Sekunden und Intervall auf 15 Sekunden stellen. Starten: bei Sekunde 5 Startgong, danach bei 20, 35 und 50 Sekunden.
2. Dasselbe mit gesperrtem Bildschirm, Fokus „Nicht stören“ und Stummschalter testen. Auch mindestens einen vollen 15-Minuten-Zyklus und eine längere Sitzung im Energiesparmodus ausprobieren.
3. Während Vorbereitung sowie mitten im Intervall pausieren, warten, fortsetzen: Pausenzeit darf nicht mitzählen.
4. Kopfhörer trennen und einen Anruf annehmen: Sitzung muss pausieren und darf nicht überraschend auf dem Lautsprecher fortgesetzt werden.
5. Preset speichern, App beenden und öffnen: Preset bleibt erhalten; Sitzung startet nicht von selbst.

Diese Gerätetests wurden bei der Erstellung **noch nicht ausgeführt**. Build-Status und automatische Prüfungen stehen unter [GitHub Actions](https://github.com/daniel4828/still-meditation/actions).

## Entwicklung

`swift test` prüft den plattformunabhängigen Kern auf dem Mac. GitHub Actions baut zusätzlich die iOS-App für den Simulator ohne Signatur. Die Audiodateien werden lokal erzeugt. Auch ein zweistündiges Intervall benötigt nur einen kleinen Gong-Puffer im Arbeitsspeicher; die stille Dateistrecke wird als Sparse-Datei geschrieben.

Technische Referenzen: [Apple: Hintergrund-Audio](https://developer.apple.com/documentation/avfoundation/configuring-your-app-for-media-playback), [Apple: Personal-Team-Grenzen](https://developer.apple.com/help/account/basics/about-your-developer-account).

Lizenz: MIT. Der Gong wird mathematisch erzeugt; keine fremden Audioaufnahmen.
