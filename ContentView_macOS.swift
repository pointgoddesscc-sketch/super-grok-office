import SwiftUI

struct ContentView_macOS: View {
    @EnvironmentObject var office: OfficeStore
    @State private var inspectorTab = 0
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR - Like Finder + Linear
            List(selection: $office.selectedModule) {
                Section("OFFICE") {
                    Label("Inbox", systemImage: "tray.full").tag(OfficeModule.inbox)
                    Label("Projects", systemImage: "square.grid.2x2").tag(OfficeModule.projects)
                    Label("Docs", systemImage: "doc.text").tag(OfficeModule.docs)
                }
                Section("INTELLIGENCE") {
                    Label("Chat", systemImage: "brain").tag(OfficeModule.chat)
                    Label("Imagine", systemImage: "photo.on.rectangle").tag(OfficeModule.imagine)
                    Label("Memory", systemImage: "memories").tag(OfficeModule.memory)
                }
                Section("CONNECT") {
                    Label("Calendar", systemImage: "calendar").tag(OfficeModule.calendar)
                    Label("Team", systemImage: "person.3").tag(OfficeModule.team)
                    Label("Drive", systemImage: "externaldrive").tag(OfficeModule.drive)
                }
                Section("SYSTEM") {
                    Label("Keys", systemImage: "key.fill").tag(OfficeModule.keys)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
            .toolbar { ToolbarItem { Button("Start Office") { office.bootstrapOffice() } } }
            
        } content: {
            // MAIN CONTENT
            switch office.selectedModule {
            case .chat: ChatModule()
            case .docs: DocsModule()
            case .projects: ProjectsModule()
            case .keys: APIKeyFactoryView()
            default: ModulePlaceholder(module: office.selectedModule)
            }
        } detail: {
            // INSPECTOR - Notion-style
            InspectorView(tab: $inspectorTab)
        }
        .overlay { if !office.isOfficeActive { MasterKeyOnboarding() } }
    }
}

enum OfficeModule: String, CaseIterable, Identifiable {
    case inbox, projects, docs, chat, imagine, memory, calendar, team, drive, keys
    var id: String { rawValue }
}

struct ModulePlaceholder: View {
    let module: OfficeModule
    var body: some View {
        VStack {
            Image(systemName: "sparkles")
            Text(module.rawValue.capitalized).font(.title2)
            Text("Module connected via scoped office key").foregroundStyle(.secondary)
        }
    }
}

struct InspectorView: View {
    @Binding var tab: Int
    var body: some View {
        VStack(alignment: .leading) {
            Text("INSPECTOR").font(.caption).foregroundStyle(.secondary)
            Text("Office Key Chain & Live Actions")
            Spacer()
        }.padding()
    }
}

struct MasterKeyOnboarding: View {
    @EnvironmentObject var office: OfficeStore
    @State private var key = ""
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            VStack(spacing: 16) {
                Text("Enter Master xAI Key").font(.title2.bold())
                SecureField("xai-...", text: $key)
                Button("Save to Keychain & Start Office") {
                    try? office.provisionMasterKey(key)
                }.buttonStyle(.borderedProminent)
            }.padding(40).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
