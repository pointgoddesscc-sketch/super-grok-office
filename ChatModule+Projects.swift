import SwiftUI

struct ChatModule: View {
    @EnvironmentObject var office: OfficeStore
    @StateObject private var vm = ChatViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            ChatTimeline(messages: vm.messages)
            if vm.isThinking {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Grok-4.5 thinking…").font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 6)
            }
            Divider()
            ChatComposer { prompt in Task { await vm.send(prompt) } }
        }
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        .init(role: .assistant, text: "Office online. Master key in Keychain. Using grok-4.5 via /v1/responses.")
    ]
    @Published var isThinking = false
    
    private let systemPrompt = "You are Super Grok, central brain of PSE Office. Concise and action-oriented."
    
    func send(_ text: String) async {
        messages.append(.init(role: .user, text: text))
        isThinking = true
        defer { isThinking = false }
        do {
            let reply = try await XAIClient.shared.chat(system: systemPrompt, user: text, model: "grok-4.5")
            messages.append(.init(role: .assistant, text: reply.isEmpty ? "(empty)" : reply))
        } catch {
            messages.append(.init(role: .assistant, text: "Error: \(error.localizedDescription)"))
        }
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
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { m in
                        HStack {
                            if m.role == .user { Spacer(minLength: 40) }
                            Text(m.text)
                                .padding(12)
                                .background(m.role == .user ? Color.white : Color.white.opacity(0.08))
                                .foregroundStyle(m.role == .user ? .black : .white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .textSelection(.enabled)
                            if m.role == .assistant { Spacer(minLength: 40) }
                        }.id(m.id)
                    }
                }.padding()
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }
}

struct ChatComposer: View {
    var onSend: (String) -> Void
    @State private var text = ""
    var body: some View {
        HStack(spacing: 10) {
            TextField("Ask the office…", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
            Button {
                let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { return }
                onSend(t); text = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .buttonStyle(.borderless)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct ImagineModule: View {
    @State private var prompt = ""
    @State private var imageURL: URL?
    @State private var videoURL: URL?
    @State private var status = ""
    @State private var isWorking = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Imagine Studio").font(.title2.bold())
            Text("grok-imagine-image-quality + grok-imagine-video").font(.caption).foregroundStyle(.secondary)
            TextField("Prompt…", text: $prompt, axis: .vertical).lineLimit(2...4).textFieldStyle(.roundedBorder)
            HStack {
                Button("Generate Image") { Task { await runImage() } }.disabled(isWorking || prompt.isEmpty)
                Button("Generate Video") { Task { await runVideo() } }.disabled(isWorking || prompt.isEmpty)
            }
            if isWorking { ProgressView(status) }
            if let imageURL { Link("Open image", destination: imageURL) }
            if let videoURL { Link("Open video", destination: videoURL) }
            Spacer()
        }.padding(24)
    }
    
    private func runImage() async {
        isWorking = true; status = "Generating image…"; defer { isWorking = false }
        do { imageURL = try await XAIClient.shared.generateImage(prompt: prompt); status = "Done" }
        catch { status = error.localizedDescription }
    }
    
    private func runVideo() async {
        isWorking = true; status = "Polling video…"; defer { isWorking = false }
        do { videoURL = try await XAIClient.shared.generateVideo(prompt: prompt); status = "Video ready" }
        catch { status = error.localizedDescription }
    }
}

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
    let name: String; let icon: String; let status: String; let grokSummary: String
}

enum MockData {
    static let projects = [
        ProjectRow(name: "Project Atlas", icon: "map", status: "In Progress", grokSummary: "3 tickets unblocked"),
        ProjectRow(name: "Office Hub", icon: "building.2", status: "Active", grokSummary: "8 modules online")
    ]
}

struct StatusPill: View {
    let status: String
    var body: some View {
        Text(status).font(.caption2).padding(.horizontal, 8).padding(.vertical, 4)
            .background(.quaternary).clipShape(Capsule())
    }
}

struct DocsModule: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("PSE Office Handbook").font(.largeTitle).bold()
                Text("Grok-aware. Wired to Notion, Linear, Gmail, Calendar, Teams.").foregroundStyle(.secondary)
            }.padding(40)
        }
    }
}
