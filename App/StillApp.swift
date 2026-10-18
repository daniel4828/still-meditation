import SwiftUI

@main
struct StillApp: App {
    @StateObject private var model = SessionModel()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(model).environment(\.locale, Locale(identifier: "zh_Hans")).tint(Color(red: 0.30, green: 0.43, blue: 0.37)) }
    }
}
