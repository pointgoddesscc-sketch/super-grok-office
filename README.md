# Super Grok macOS Office

**Keychain-first macOS office OS powered by xAI Grok-4.**

Master key lives only in Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).  
The app factory creates unlimited scoped sub-keys `sk-pse-office-{module}-*` for Chat, Docs, Projects, Imagine, Calendar, Team, Drive, etc.  
Team members never see the master key.

## Bundle ID
`services.psemanagement.supergrok`

## Requirements
- macOS 14+ (Sonoma)
- Xcode 15+
- xAI API key (entered once by admin)

## Core Architecture
- `SuperGrokOfficeApp.swift` — App + MenuBarExtra
- `OfficeStore.swift` — Central state, bootstrap, key factory
- `KeychainManager.swift` — Master + sub-key storage
- `ContentView_macOS.swift` — NavigationSplitView (sidebar + content + inspector)
- `APIKeyFactoryView.swift` — Create / revoke scoped keys
- `ChatModule+Projects.swift` — Chat brain + Linear-style projects + Notion-style docs

## Modules (Everything Connected)
| Hub | Description | Scoped key |
|-----|-------------|------------|
| Inbox | Gmail + Outlook triage | sk-pse-office-inbox-* |
| Projects | Linear-style PM by Grok | sk-pse-office-projects-* |
| Docs | Notion-style canvas | sk-pse-office-docs-* |
| Chat | Central Brain (Grok-4) | sk-pse-office-chat-* |
| Imagine | Image + Video | sk-pse-office-imagine-* |
| Memory | Shared long-term context | injected everywhere |
| Calendar | Google + Calendly | sk-pse-office-calendar-* |
| Team | Teams/Slack notes | sk-pse-office-team-* |
| Drive | Semantic knowledge base | sk-pse-office-drive-* |
| Keys | Office Key Factory | — |

## 5 Steps to Run
1. Clone → Open in Xcode → set Bundle ID
2. Run → paste master key from console.x.ai → saved to Keychain
3. Factory auto-provisions 7+ sub-keys
4. Click **Start Office**
5. Team installs .app → Join Office → receive only sub-keys

## Security
- Master never leaves admin Mac Keychain
- Sub-keys are UUID + scope + checksum
- No .env files, no external config
- Access group: `services.psemanagement.supergrok`

## Payment / SaaS
Stripe product + pricing linked for Office seats and usage-based billing on xAI spend.

MIT • Not affiliated with xAI • © psemanagement.services 2026
