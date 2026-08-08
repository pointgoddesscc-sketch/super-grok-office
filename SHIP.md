# PSE Office OS — SHIP 2054.06.12

**Bundle ID:** `services.psemanagement.supergrok`  
**Display Name:** PSE Office OS  
**Landing:** https://super-grok-office-pse-sent.vercel.app  
**Repo:** https://github.com/pointgoddesscc-sketch/super-grok-office

## Package status

| Piece | Status |
|-------|--------|
| KeychainManager.swift (Layer 0) | ✅ in repo |
| office-api-kit.sh (4 curls, Keychain) | ✅ scripts/ |
| bootstrap-2054.sh | ✅ scripts/ |
| XAIClient.swift (grok-4 / imagine) | ✅ |
| PrivacyInfo.xcprivacy | ✅ SuperGrokOffice/ |
| SuperGrokOffice.entitlements | ✅ SuperGrokOffice/ |
| App Store listing + privacy docs | ✅ docs/ |
| Stripe webhook (license forge) | ✅ api/stripe/webhook.ts |
| Screenshots (6 frames) | ✅ generated (upload from artifacts) |
| Stripe $29 product + payment link | ⚠️ Dashboard (MCP write still blocked) |

## Stripe — create in Dashboard (2 min)

MCP key on **Krmanagement** (`acct_1TpYnzJKMo7r5iU4`) can **read** but still cannot **PostProducts**. Create once by hand:

1. [Stripe Dashboard → Products](https://dashboard.stripe.com/products) → **+ Add product**
2. Name: **Super Grok Office**
3. Pricing: **$29.00 USD** · Recurring · **Monthly**
4. **Payment link** → After payment redirect:  
   `https://super-grok-office-pse-sent.vercel.app?welcome=pro`
5. **Developers → Webhooks** → endpoint:  
   `https://super-grok-office-pse-sent.vercel.app/api/stripe/webhook`  
   Events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`
6. Copy webhook signing secret → Vercel env `STRIPE_WEBHOOK_SECRET` (never commit)

Optional re-consent if write APIs appear later:  
https://access.stripe.com/mcp/oauth2/authorize/sessions/oases_UzrgQ1GyjJ3mGB

## App Store Connect — submit today

1. Xcode: Bundle ID `services.psemanagement.supergrok`
2. Attach `SuperGrokOffice.entitlements` + `PrivacyInfo.xcprivacy`
3. Paste usage strings from `docs/APP_STORE_PRIVACY.md`
4. Paste listing from `docs/APP_STORE_LISTING.md`
5. Upload 6 screenshots (Chat, Key Forge, Pulse, Imagine, Calendar, MenuBar)
6. Privacy questionnaire: No tracking; data not linked; xAI + Stripe as noted
7. Archive → Distribute → Submit

## Local verify (Mac)

```bash
git clone https://github.com/pointgoddesscc-sketch/super-grok-office.git
cd super-grok-office
chmod +x scripts/bootstrap-2054.sh scripts/office-api-kit.sh
./scripts/bootstrap-2054.sh
# Run app → Key Forge → Face ID → paste one xAI master key
./scripts/office-api-kit.sh   # 4 flows green
```

**Ready to ship:** Yes — code, privacy, entitlements, listing, webhook, and API kit are in place. Only Stripe product/link is a one-time Dashboard click.
