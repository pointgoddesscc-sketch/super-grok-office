# Super Grok macOS Office — Setup (Steps 1–5)

## 1. Clone & Open in Xcode
```bash
git clone https://github.com/pointgoddesscc-sketch/super-grok-office.git
cd super-grok-office
```
- Xcode → New → macOS App → Bundle ID **`services.psemanagement.supergrok`**
- Drop in all Swift files from this repo (including `XAIClient.swift`)
- Signing: enable Keychain access as needed

## 2. Master Key → Keychain
1. Run (⌘R)
2. Paste xAI key from https://console.x.ai (`xai-…`)
3. Saved with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`

## 3. Factory Auto-Provisions
Creates internal identifiers `sk-pse-office-{module}-*` for UI/tracking.  
**Real API calls always use the master Keychain key** (see XAIClient).

## 4. Start Office
Toolbar / MenuBarExtra → **Office Online**. Chat uses `/v1/responses` with `grok-4.5`.

## 5. Archive
Product → Archive → TestFlight or signed DMG.

---

## Real xAI API (wired in XAIClient.swift)

Matches the official curl examples:

| Capability | Model | Endpoint |
|------------|-------|----------|
| Chat / fix code | `grok-4.5` | `POST /v1/responses` |
| Multi-turn | `grok-4.5` | `POST /v1/responses` with `input: [{role, content}]` |
| Image | `grok-imagine-image-quality` | `POST /v1/images/generations` |
| Video | `grok-imagine-video` | `POST /v1/videos/generations` then poll `GET /v1/videos/{request_id}` |

Authorization: `Bearer <master key from Keychain>` only.  
Office sub-keys (`sk-pse-office-*`) are **not** sent to api.x.ai.

Example equivalence:
```bash
# Same as XAIClient.respond(input:)
curl https://api.x.ai/v1/responses \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -d '{"model":"grok-4.5","input":"Fix this function..."}'
```

---

## Stripe Product + Payment Link

Create in Dashboard (API product write restricted):
1. https://dashboard.stripe.com/products → **+ Add product** → **Super Grok Office**
2. Recurring **$29/month** (optional $290/year)
3. **Create payment link** → redirect to https://super-grok-office-pse-sent.vercel.app
4. Share `buy.stripe.com/…`

---

## Connector map
Inbox → Gmail/Outlook · Projects → Linear · Docs → Notion · Calendar → Google + Calendly · Team → Microsoft Teams · Payments → Stripe · Chat/Imagine → xAI via master key

## Live
- Landing: https://super-grok-office-pse-sent.vercel.app
- Source: https://github.com/pointgoddesscc-sketch/super-grok-office
