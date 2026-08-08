#!/bin/bash
# =========================================================
# PSE OFFICE OS — bootstrap-2054.sh
# Team: psemanagement.services
# Bundle: services.psemanagement.supergrok
# Layer 0 Key Forge · No .env · Keychain + App Group
# =========================================================
set -euo pipefail

BUNDLE="services.psemanagement.supergrok"
GROUP="group.${BUNDLE}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "════════════════════════════════════════"
echo " PSE OFFICE OS 2054 — Bootstrap"
echo " Bundle: $BUNDLE"
echo "════════════════════════════════════════"

command -v git >/dev/null || { echo "git required"; exit 1; }
command -v xcodebuild >/dev/null 2>&1 || echo "⚠ xcodebuild not found (OK on non-Mac CI)"

ENTITLEMENTS_DIR="$ROOT/SuperGrokOffice"
mkdir -p "$ENTITLEMENTS_DIR"
cat > "$ENTITLEMENTS_DIR/SuperGrokOffice.entitlements" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>keychain-access-groups</key>
	<array>
		<string>\$(AppIdentifierPrefix)${BUNDLE}</string>
		<string>\$(AppIdentifierPrefix)${BUNDLE}.*</string>
	</array>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>${GROUP}</string>
	</array>
	<key>com.apple.developer.devicecheck.appattest-environment</key>
	<string>production</string>
</dict>
</plist>
EOF
echo "✅ Wrote SuperGrokOffice.entitlements (Keychain group + App Group ${GROUP})"

HOOK="$ROOT/.git/hooks/pre-commit"
mkdir -p "$(dirname "$HOOK")"
cat > "$HOOK" << 'HOOK'
#!/bin/bash
if git diff --cached -U0 | grep -Eiq '(xai-[A-Za-z0-9]{20,}|sk-pse-office-|sk_live_|sk_test_[A-Za-z0-9]{20,})'; then
  echo "❌ BLOCKED: possible API key in staged changes (Office OS 2054 policy)."
  echo "   Keys live only in Keychain: services.psemanagement.supergrok.master"
  exit 1
fi
exit 0
HOOK
chmod +x "$HOOK"
echo "✅ Installed pre-commit hook (blocks key commits)"

chmod +x "$ROOT/scripts/"*.sh 2>/dev/null || true
echo "✅ scripts/*.sh executable"

if command -v vercel >/dev/null 2>&1; then
  echo "→ Linking Vercel project…"
  (cd "$ROOT" && vercel link --yes --project super-grok-office 2>/dev/null) || true
  echo "✅ Vercel link attempted → super-grok-office-pse-sent.vercel.app"
else
  echo "ℹ vercel CLI not installed — skip link"
fi

cat << EOF

════════════════════════════════════════
 Bootstrap complete — 2054 Office OS
════════════════════════════════════════
 Next:
  1. Open SuperGrokOffice.xcodeproj (or create macOS App)
  2. Bundle ID: ${BUNDLE}
  3. Signing → apply SuperGrokOffice.entitlements
  4. Run → Key Forge → paste ONE xai- master key
  5. ./scripts/office-api-kit.sh

 Keychain services:
  • ${BUNDLE}.master
  • ${BUNDLE}.office
  • ${BUNDLE}.office.{chat,docs,projects,inbox,calendar,imagine,team,drive}

 No .env. Ever. Keys are born in the app UI.
════════════════════════════════════════
EOF
