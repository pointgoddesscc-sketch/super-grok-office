import SwiftUI

// MARK: - ChatModule (Central Brain)
struct ChatModule: View {
    @EnvironmentObject var office: OfficeStore
    @StateObject private var vm = ChatViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            ChatTimeline(messages: vm.messages)
            Divider()
            ChatComposer { prompt in
                Task {
                    let subKey = office.activeKeys.first(where: { $0.module == "chat" })?.value
                                ?? office.createOfficeSubKey(for: "chat", scopes: ["chat","memory"])
                    await vm.send(prompt, using: subKey)
                }
            }
        }
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        .init(role: .assistant, text: "Office online. Master key secured in Keychain. All modules connected.")
    ]
    
    func send(_ text: String, using officeKey: String) async {
        messages.append(.init(role: .user, text: text))
        // Uses internal sub-key, never master
        // XAIClient(apiKey: officeKey).streamGrok4(text)
        messages.append(.init(role: .assistant, text: "Acknowledged via scoped key. Actions routed to Projects / Calendar / Docs."))
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role { case user, assistant }
    let role: Role
    let text: String
}

struct ChatTimeline: View {
    let messages: [ChatMessage]
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(messages) { m in
                    HStack {
                        if m.role == .user { Spacer() }
                        Text(m.text)
                            .padding(12)
                            .background(m.role == .user ? Color.white : Color.white.opacity(0.08))
                            .foregroundStyle(m.role == .user ? .black : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        if m.role == .assistant { Spacer() }
                    }
                }
            }.padding()
        }
    }
}

struct ChatComposer: View {
    var onSend: (String) -> Void
    @State private var text = ""
    var body: some View {
        HStack {
            TextField("Ask the office…", text: $text)
            Button("Send") { onSend(text); text = "" }
        }.padding()
    }
}

// MARK: - ProjectsModule (Linear-style)
struct ProjectsModule: View {
    @State private var projects = MockData.projects
    var body: some View {
        Table(projects) {
            TableColumn("Project") { p in Label(p.name, systemImage: p.icon) }
            TableColumn("Status") { p in StatusPill(status: p.status) }
            TableColumn("Grok PM") { p in Text(p.grokSummary).foregroundStyle(.secondary) }
        }.tableStyle(.inset)
    }
}

struct ProjectRow: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let status: String
    let grokSummary: String
}

enum MockData {
    static let projects = [
        ProjectRow(name: "Project Atlas", icon: "map", status: "In Progress", grokSummary: "3 tickets unblocked, focus block 14:00"),
        ProjectRow(name: "Office Hub", icon: "building.2", status: "Active", grokSummary: "Key factory live, 7 modules online")
    ]
}

struct StatusPill: View {
    let status: String
    var body: some View {
        Text(status).font(.caption2).padding(.horizontal, 8).padding(.vertical, 4)
            .background(.quaternary).clipShape(Capsule())
    }
}

// MARK: - DocsModule (Notion-style)
struct DocsModule: View {
    var body: some View {
        ScrollView { 
            VStack(alignment: .leading, spacing: 16) {
                Text("PSE Office Handbook").font(.largeTitle).bold()
                Text("All docs are Grok-aware. Select text -> Ask Grok to rewrite, summarize, turn into Linear ticket.")
                    .foregroundStyle(.secondary)
            }.padding(40)
        }
    }
}
