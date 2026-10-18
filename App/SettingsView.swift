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
                        DurationEditor(title: "准备时间", seconds: preparation, minimum: 0, maximum: 300)
                    } label: { LabeledContent("准备时间", value: SessionModel.time(Double(model.settings.preparation))) }
                    NavigationLink {
                        DurationEditor(title: "钟声间隔", seconds: interval, minimum: 15, maximum: 7200)
                    } label: { LabeledContent("钟声间隔", value: SessionModel.time(Double(model.settings.interval))) }
                } header: { Text("时间") } footer: {
                    Text("准备时间结束后，钟声响起，冥想开始。之后按设定的间隔持续响铃，直到你结束冥想。")
                }
                Section {
                    Slider(value: volume, in: 0.05...1) { Text("钟声音量") }
                    Button("试听钟声", systemImage: "speaker.wave.2", action: model.preview)
                    SystemVolumeSlider().frame(height: 36).accessibilityLabel("iPhone 媒体音量")
                } header: { Text("声音") } footer: {
                    Text("上方调整钟声音量，下方调整 iPhone 媒体音量。如果媒体音量为零，就听不到钟声。冥想前请先试听。")
                }
                Section("预设") {
                    ForEach(model.presets) { preset in
                        Button {
                            model.settings = preset.settings
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name).foregroundStyle(.primary)
                                    Text("准备 \(preset.settings.preparation) 秒 · 间隔 \(SessionModel.time(Double(preset.settings.interval)))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if preset.settings == model.settings { Image(systemName: "checkmark").accessibilityLabel("已选择") }
                            }
                        }
                    }.onDelete(perform: model.deletePresets)
                    TextField("名称，例如：晚间静坐", text: $presetName).onChange(of: presetName) { _, value in
                        presetName = String(value.prefix(60))
                    }
                    Button("保存当前设置") { model.savePreset(name: presetName); presetName = "" }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Section {
                    Text("冥想时可以锁屏并开启“勿扰模式”。应用会播放带有静音间隔的音轨。请让应用保持打开或在后台运行；从后台彻底关闭应用后，钟声也会停止。")
                    Text("来电或耳机断开连接时，冥想会暂停。之后请回到应用中继续。")
                } header: { Text("使用提示") }.font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("设置").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
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
                Stepper("分钟：\(seconds / 60)", value: Binding(get: { seconds / 60 }, set: {
                    seconds = min(maximum, max(minimum, $0 * 60 + seconds % 60))
                }), in: 0...(maximum / 60))
                Stepper("秒：\(seconds % 60)", value: Binding(get: { seconds % 60 }, set: {
                    seconds = min(maximum, max(minimum, seconds / 60 * 60 + $0))
                }), in: 0...59)
                LabeledContent("时长", value: SessionModel.time(Double(seconds)))
            }
            Section {
                if minimum == 0 { Button("跳过准备") { seconds = 0 } }
                if maximum > 300 {
                    ForEach([15, 30, 60, 300, 600, 900, 1200, 1800, 3600], id: \.self) { value in
                        Button(value < 60 ? "\(value) 秒" : "\(value / 60) 分钟") { seconds = value }
                    }
                } else {
                    ForEach([15, 30, 60, 120, 300], id: \.self) { value in
                        Button("\(value) 秒") { seconds = value }
                    }
                }
            } header: { Text("快速选择") }
        }.navigationTitle(title)
    }
}

struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView { MPVolumeView(frame: .zero) }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
