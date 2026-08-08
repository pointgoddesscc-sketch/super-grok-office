# Super Grok macOS Office — Setup (Steps 1–5)

## 1. Clone & Open in Xcode
```bash
git clone https://github.com/pointgoddesscc-sketch/super-grok-office.git
cd super-grok-office
```
- Xcode → File → New → Project → macOS → App
- Product Name: `SuperGrokOffice`
- Bundle Identifier: **`services.psemanagement.supergrok`**
- Interface: SwiftUI, Language: Swift, Storage: none
- Replace generated files with the 6 Swift files from this repo
- Signing & Capabilities → enable Keychain Sharing (optional access group) and App Sandbox as needed

## 2. Master Key → Keychain
1. Run the app (⌘R)
2. Onboarding appears → paste your xAI key from https://console.x.ai (starts with `xai-`)
3. Tap **Save to Keychain & Start Office**
4. Key is stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` under service `services.psemanagement.supergrok.master`

## 3. Factory Auto-Provisions
- `provisionAllModules()` creates 8 scoped keys:
  - `sk-pse-office-chat-*`
  - `sk-pse-office-docs-*`
  - `sk-pse-office-projects-*`
  - `sk-pse-office-inbox-*`
  - `sk-pse-office-calendar-*`
  - `sk-pse-office-imagine-*`
  - `sk-pse-office-team-*`
  - `sk-pse-office-drive-*`
- Keys appear in the **Keys** module (API Key Factory)

## 4. Start Office
- Click **Start Office** in the toolbar or MenuBarExtra
- Sidebar modules become active
- Status badge shows **Office Online**
- Central Brain (Chat) uses the chat-scoped sub-key only

## 5. Archive & Distribute
```bash
# Or in Xcode: Product → Archive → Distribute App
xcodebuild -scheme SuperGrokOffice -configuration Release archive
```
- Upload to TestFlight (Mac) or export signed DMG
- Team members install the .app → “Join Office” flow (admin approves) → they receive only sub-keys

---

## Stripe Product + Payment Link (Create in Dashboard)

API write for Products is restricted on the connected key. Create in 60 seconds:

1. Open https://dashboard.stripe.com/products (account **Krmanagement**)
2. **+ Add product**
   - Name: `Super Grok Office`
   - Description: `Keychain-first macOS Office Hub seats. Bundle services.psemanagement.supergrok`
3. Add price:
   - Recurring → Monthly → **$29.00 USD** → Save
4. Add second price (optional):
   - Recurring → Yearly → **$290.00 USD**
5. On the product page → **Create payment link**
   - Select the monthly (or yearly) price
   - After payment: redirect to https://super-grok-office-pse-sent.vercel.app
   - Collect customer email
6. Copy the Payment Link URL (looks like `https://buy.stripe.com/...`)
7. Paste it into the Vercel landing or share directly with team

Recommended metadata on the product:
```
bundle_id = services.psemanagement.supergrok
product_type = saas_seat
```

Customer Portal (for upgrades/cancel):
Dashboard → Settings → Billing → Customer portal → Activate

---

## Real Connector Wiring Map

| Office Module | Real Connector(s) | How it wires |
|---------------|-------------------|--------------|
| Inbox | Gmail + Outlook | Triage + draft via Graph / Gmail API; use scoped `inbox` key for Grok summarization |
| Projects | Linear | List/create issues via Linear MCP; Grok acts as PM using `projects` key |
| Docs | Notion | Create/update pages; Grok rewrite/summarize with `docs` key |
| Chat | xAI (Grok-4) | All traffic uses `sk-pse-office-chat-*` only |
| Imagine | xAI grok-imagine | Scoped `imagine` key |
| Calendar | Google Calendar + Calendly | Find slots, buffer, reschedule |
| Team | Microsoft Teams | Meeting notes / channel summaries |
| Drive | (Notion / GitHub) | Semantic search over docs/code |
| Keys | Keychain | Factory UI |
| Payments | Stripe | Seats via Payment Link above |

All connectors are already connected in your OrgSuite session. The Swift modules call the corresponding APIs using the scoped office key for any Grok reasoning; the actual connector calls (Linear, Notion, Calendar, etc.) use the user’s authenticated sessions.

---

## Live Links
- Landing: https://super-grok-office-pse-sent.vercel.app
- Source: https://github.com/pointgoddesscc-sketch/super-grok-office
- Linear: https://linear.app/pse-management/project/super-grok-macos-office-d4bf4b9a8744
