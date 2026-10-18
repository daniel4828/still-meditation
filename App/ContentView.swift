import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: SessionModel
    @State private var showSettings = false
    @State private var confirmStop = false
    @ScaledMetric(relativeTo: .largeTitle) private var timerSize = 76

    private var title: String {
        if model.state == .paused { return "Pause" }
        if model.state == .loading { return "Wird vorbereitet …" }
        if !model.hasSession { return "Zeit für Ruhe" }
        return model.snapshot.isPreparing ? "Ankommen" : "Meditation"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 38)
                    Image(systemName: "circle.dotted").font(.system(size: 36, weight: .ultraLight)).foregroundStyle(.secondary).accessibilityHidden(true)
                    Text(title).font(.title3).foregroundStyle(.secondary)
                    Text(SessionModel.time(model.hasSession ? (model.snapshot.isPreparing ? model.snapshot.preparationRemaining : model.snapshot.meditationElapsed) : 0,
                                           countdown: model.hasSession && model.snapshot.isPreparing))
                        .font(.system(size: timerSize, weight: .ultraLight, design: .rounded))
                        .monospacedDigit().minimumScaleFactor(0.35).lineLimit(1)
                        .accessibilityLabel(model.snapshot.isPreparing && model.hasSession ? "Vorbereitung" : "Meditationszeit")
                        .accessibilityValue(SessionModel.time(model.hasSession ? (model.snapshot.isPreparing ? model.snapshot.preparationRemaining : model.snapshot.meditationElapsed) : 0, countdown: model.snapshot.isPreparing))
                    VStack(spacing: 8) {
                        if model.hasSession {
                            Text("Nächster Gong in \(SessionModel.time(model.snapshot.nextGong, countdown: true))")
                            Text("\(model.snapshot.completedIntervals) abgeschlossene Intervalle").font(.caption)
                        } else {
                            Text("\(model.settings.preparation) Sek. ankommen")
                            Text("Gong alle \(SessionModel.time(Double(model.settings.interval))) · ohne Ende")
                        }
                    }.foregroundStyle(.secondary).font(.subheadline)
                    Spacer(minLength: 28)
                    Button(action: model.toggle) {
                        Label(model.state == .idle ? "Beginnen" : model.state == .paused ? "Fortsetzen" : "Pause",
                              systemImage: model.state == .idle || model.state == .paused ? "play.fill" : "pause.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                    if model.hasSession {
                        Button("Sitzung beenden", role: .destructive) { confirmStop = true }.padding(.vertical, 8)
                    } else {
                        Text("Ein sanfter Gong zum Start. Danach nur Stille und dein Intervall.")
                            .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }.padding(28).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Still").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel("Einstellungen und Presets").disabled(model.hasSession)
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .confirmationDialog("Sitzung beenden?", isPresented: $confirmStop, titleVisibility: .visible) {
                Button("Beenden", role: .destructive, action: model.stop)
                Button("Weiter meditieren", role: .cancel) {}
            }
            .alert("Hinweis", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) {
                Button("OK") { model.message = nil }
            } message: { Text(model.message ?? "") }
        }
    }
}
