# Prüfbericht – 18. Oktober 2026

Geprüfter App-Quellcode: Commit `de07de0`. Nachfolgende Änderungen betreffen ausschließlich Anleitung, CI-Konfiguration und diese Vorschau-Dateien.

- Swift-Kern auf Daniels Mac erfolgreich kompiliert. Lokale XCTest-Ausführung war wegen fehlendem vollständigem Xcode nicht möglich.
- Alle fünf XCTest-Tests auf GitHub bestanden: Vorbereitung/Intervallgrenzen, Pause/Fortsetzung ohne Vorbereitung, validierte Preset-Daten, WAV-Dauer/Gong-Hüllkurve, stille Vorbereitung.
- Vollständiger iOS-Simulator-Build erfolgreich, ohne Signatur. Keine Compilerfehler; lediglich Apples Hinweis auf nicht benötigte AppIntents-Metadaten.
- App im iPhone-Simulator installiert und gestartet. Helle und dunkle Ansicht als echte Screenshots gespeichert und visuell auf Lesbarkeit sowie abgeschnittene Inhalte geprüft.
- Zusätzliche lesende Codeprüfung: keine wichtigen Befunde.
- Xcode-Projekt und Info.plist mit plutil geprüft; Git-Diff ohne Leerraumfehler.

Nachweis: https://github.com/daniel4828/still-meditation/actions/runs/39159930627

Nicht ausgeführt: Installation auf Daniels physischem iPhone, hörbare Gongs bei gesperrtem Bildschirm und Fokus, lange Hintergrundsitzung, Telefon-/Kopfhörer-Unterbrechungen, tatsächliche App-Bedienung in einem UI-Test. Die Checkliste dafür steht in README.md. Simulatorstart und bestandener Build ersetzen diese Gerätetests nicht.
