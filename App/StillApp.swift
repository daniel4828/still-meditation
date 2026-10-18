import SwiftUI

@main
struct StillApp: App {
    @StateObject private var model = SessionModel()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(model).tint(Color(red: 0.30, green: 0.43, blue: 0.37)) }
    }
}
