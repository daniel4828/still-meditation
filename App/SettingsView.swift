import SwiftUI
import MediaPlayer

struct SettingsView: View {
    @EnvironmentObject private var model: SessionModel
    @Environment(\.dismiss) private var dismiss
    @State private var presetName = ""

    private var preparation: Binding<Int> {
        Binding(get: { model.settings.preparation }, set: {
            model.settings = SessionSettings(preparation: $0, interval: model.settings.interval, volume: model.settings.volume)
        })
    }
    private var interval: Binding<Int> {
        Binding(get: { model.settings.interval }, set: {
            model.settings = SessionSettings(preparation: model.settings.preparation, interval: $0, volume: model.settings.volume)
        })
    }
    private var volume: Binding<Double> {
        Binding(get: { model.settings.volume }, set: {
            model.settings = SessionSettings(preparation: model.settings.preparation, interval: model.settings.interval, volume: $0)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        DurationEditor(title: "Vorbereitung", seconds: preparation, minimum: 0, maximum: 300)
                    } label: { LabeledContent("Vorbereitung", value: SessionModel.time(Double(model.settings.preparation))) }
                    NavigationLink {
                        DurationEditor(title: "Gong-Intervall", seconds: interval, minimum: 15, maximum: 7200)
                    } label: { LabeledContent("Gong-Intervall", value: SessionModel.time(Double(model.settings.interval))) }
                } header: { Text("Zeit") } footer: {
                    Text("Nach der Vorbereitung erklingt der Startgong. Danach wiederholt sich der Gong ohne Zeitlimit.")
                }
                Section {
                    Slider(value: volume, in: 0.05...1) { Text("Gong-Lautstärke") }
                    Button("Gong anhören", systemImage: "speaker.wave.2", action: model.preview)
                    SystemVolumeSlider().frame(height: 36).accessibilityLabel("iPhone-Medienlautstärke")
                } header: { Text("Klang") } footer: {
                    Text("Oben: Lautstärke des Gongs. Unten: iPhone-Medienlautstärke. Bei Medienlautstärke null bleibt der Gong stumm. Prüfe den Klang vor der Meditation.")
                }
                Section("Presets") {
                    ForEach(model.presets) { preset in
                        Button {
                            model.settings = preset.settings
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name).foregroundStyle(.primary)
                                    Text("\(preset.settings.preparation) Sek. Vorbereitung · \(SessionModel.time(Double(preset.settings.interval))) Intervall")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if preset.settings == model.settings { Image(systemName: "checkmark").accessibilityLabel("Ausgewählt") }
                            }
                        }
                    }.onDelete(perform: model.deletePresets)
                    TextField("Name, z. B. Abendruhe", text: $presetName).onChange(of: presetName) { _, value in
                        presetName = String(value.prefix(60))
                    }
                    Button("Aktuelle Einstellung speichern") { model.savePreset(name: presetName); presetName = "" }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Section {
                    Text("Du kannst den Bildschirm sperren und „Nicht stören“ aktivieren. Die Sitzung spielt eine Audiospur mit stillen Pausen ab. Lass die App geöffnet oder im Hintergrund; vollständiges Beenden stoppt den Gong.")
                    Text("Anrufe und getrennte Kopfhörer pausieren die Sitzung. Setze sie danach in der App fort.")
                } header: { Text("Gut zu wissen") }.font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Einstellungen").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
    }
}

struct DurationEditor: View {
    let title: String
    @Binding var seconds: Int
    let minimum: Int
    let maximum: Int

    var body: some View {
        Form {
            Section {
                Stepper("Minuten: \(seconds / 60)", value: Binding(get: { seconds / 60 }, set: {
                    seconds = min(maximum, max(minimum, $0 * 60 + seconds % 60))
                }), in: 0...(maximum / 60))
                Stepper("Sekunden: \(seconds % 60)", value: Binding(get: { seconds % 60 }, set: {
                    seconds = min(maximum, max(minimum, seconds / 60 * 60 + $0))
                }), in: 0...59)
                LabeledContent("Dauer", value: SessionModel.time(Double(seconds)))
            }
            Section {
                if minimum == 0 { Button("Ohne Vorbereitung") { seconds = 0 } }
                if maximum > 300 {
                    ForEach([15, 30, 60, 300, 600, 900, 1200, 1800, 3600], id: \.self) { value in
                        Button(value < 60 ? "\(value) Sekunden" : "\(value / 60) Minuten") { seconds = value }
                    }
                } else {
                    ForEach([15, 30, 60, 120, 300], id: \.self) { value in
                        Button("\(value) Sekunden") { seconds = value }
                    }
                }
            } header: { Text("Schnellauswahl") }
        }.navigationTitle(title)
    }
}

struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView { MPVolumeView(frame: .zero) }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
