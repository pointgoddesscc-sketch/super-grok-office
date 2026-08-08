import SwiftUI

struct APIKeyFactoryView: View {
    @EnvironmentObject var office: OfficeStore
    @State private var newModule = "chat"
    @State private var selectedScopes: Set<String> = ["chat"]
    
    let availableScopes = ["chat","image","video","vision","memory","tools"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Office Key Factory").font(.title2).bold()
                    Text("Master in Keychain -> Unlimited scoped sub-keys").foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(online: office.isOfficeActive)
            }
            
            GroupBox("Create Office Key") {
                VStack(spacing: 16) {
                    Picker("Module", selection: $newModule) {
                        ForEach(["chat","docs","projects","inbox","calendar","imagine","team"], id: \.self) { Text($0) }
                    }
                    ScopeSelector(scopes: availableScopes, selection: $selectedScopes)
                    
                    Button(action: {
                        let key = office.createOfficeSubKey(for: newModule, scopes: Array(selectedScopes))
                        print("Created: \(key)")
                    }) {
                        Label("Create Office Key", systemImage: "key.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }.padding(.vertical, 8)
            }
            
            GroupBox("Active Keys (\(office.activeKeys.count))") {
                ForEach(office.activeKeys) { key in
                    HStack {
                        Text(key.value).font(.system(.caption, design: .monospaced)).lineLimit(1)
                        Spacer()
                        Text(key.module).font(.caption2).padding(4).background(.quaternary).clipShape(RoundedRectangle(cornerRadius: 4))
                        Button("Revoke", role: .destructive) { 
                            KeychainManager.shared.revokeSubKey(id: key.id)
                            office.activeKeys.removeAll { $0.id == key.id }
                        }
                    }.padding(.vertical, 4)
                    Divider()
                }
            }
            Spacer()
        }.padding(24)
    }
}

struct StatusBadge: View {
    var online: Bool
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(online ? Color.green : Color.orange).frame(width: 8, height: 8)
            Text(online ? "Office Online" : "Needs Master Key").font(.caption).bold()
        }.padding(.horizontal, 10).padding(.vertical, 6).background(.ultraThinMaterial).clipShape(Capsule())
    }
}

struct ScopeSelector: View {
    let scopes: [String]
    @Binding var selection: Set<String>
    var body: some View {
        FlowLayout {
            ForEach(scopes, id: \.self) { s in
                Toggle(s, isOn: Binding(
                    get: { selection.contains(s) },
                    set: { if $0 { selection.insert(s) } else { selection.remove(s) } }
                )).toggleStyle(.button)
            }
        }
    }
}

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        .init(width: proposal.width ?? 300, height: 40)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for s in subviews {
            s.place(at: .init(x: x, y: bounds.minY), proposal: .unspecified)
            x += s.sizeThatFits(.unspecified).width + 8
        }
    }
}
