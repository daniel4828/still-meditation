import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: SessionModel
    @State private var showSettings = false
    @State private var confirmStop = false
    @ScaledMetric(relativeTo: .largeTitle) private var timerSize = 76

    private var title: String {
        if model.state == .paused { return "已暂停" }
        if model.state == .loading { return "正在准备……" }
        if !model.hasSession { return "静下来，休息一下" }
        return model.snapshot.isPreparing ? "准备" : "冥想"
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
                        .accessibilityLabel(model.snapshot.isPreparing && model.hasSession ? "准备时间" : "冥想时间")
                        .accessibilityValue(SessionModel.time(model.hasSession ? (model.snapshot.isPreparing ? model.snapshot.preparationRemaining : model.snapshot.meditationElapsed) : 0, countdown: model.snapshot.isPreparing))
                    VStack(spacing: 8) {
                        if model.hasSession {
                            Text("下次钟声：\(SessionModel.time(model.snapshot.nextGong, countdown: true)) 后")
                            Text("已完成 \(model.snapshot.completedIntervals) 个间隔").font(.caption)
                        } else {
                            Text("准备 \(model.settings.preparation) 秒")
                            Text("每隔 \(SessionModel.time(Double(model.settings.interval))) 响一次 · 持续循环")
                        }
                    }.foregroundStyle(.secondary).font(.subheadline)
                    Spacer(minLength: 28)
                    Button(action: model.toggle) {
                        Label(model.state == .idle ? "开始" : model.state == .paused ? "继续" : "暂停",
                              systemImage: model.state == .idle || model.state == .paused ? "play.fill" : "pause.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                    if model.hasSession {
                        Button("结束冥想", role: .destructive) { confirmStop = true }.padding(.vertical, 8)
                    } else {
                        Text("一声轻柔的钟声，开始冥想。之后，钟声按设定的间隔响起。")
                            .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }.padding(28).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("静坐").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel("设置与预设").disabled(model.hasSession)
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .confirmationDialog("结束本次冥想？", isPresented: $confirmStop, titleVisibility: .visible) {
                Button("结束", role: .destructive, action: model.stop)
                Button("继续冥想", role: .cancel) {}
            }
            .alert("提示", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) {
                Button("好") { model.message = nil }
            } message: { Text(model.message ?? "") }
        }
    }
}
