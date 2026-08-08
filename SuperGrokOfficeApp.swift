import SwiftUI

@main
struct SuperGrokOfficeApp: App {
    @StateObject private var office = OfficeStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView_macOS()
                .environmentObject(office)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 800)
        
        MenuBarExtra("Super Grok Office", systemImage: "brain.head.profile") {
            Button("Open Office") {
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Start Office") {
                office.bootstrapOffice()
            }
            Button("Key Factory") {
                office.selectedModule = .keys
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
