#!/usr/bin/env bash
# PSE Office OS — App Store ship helper
# Bundle ID: services.psemanagement.supergrok
# Run on your Mac with Xcode + Apple Developer account signed in.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUNDLE_ID="services.psemanagement.supergrok"
SCHEME="SuperGrokOffice"
TEAM_ID="${DEVELOPMENT_TEAM:-}"   # export DEVELOPMENT_TEAM=XXXXXXXXXX

echo "══════════════════════════════════════════"
echo " PSE Office OS → App Store Connect"
echo " Bundle: $BUNDLE_ID"
echo "══════════════════════════════════════════"

echo ""
echo "[1/5] Verify required files"
for f in \
  SuperGrokOffice/Info.plist \
  SuperGrokOffice/PrivacyInfo.xcprivacy \
  SuperGrokOffice/SuperGrokOffice.entitlements \
  KeychainManager.swift \
  docs/APP_STORE_LISTING.md \
  docs/APP_STORE_PRIVACY.md
do
  if [[ -f "$f" ]]; then
    echo "  ✅ $f"
  else
    echo "  ❌ MISSING $f"
    exit 1
  fi
done

echo ""
echo "[2/5] Xcode project wiring (manual if no .xcodeproj yet)"
echo "  • Open or create SuperGrokOffice.xcodeproj"
echo "  • Target → General → Bundle Identifier = $BUNDLE_ID"
echo "  • Target → Signing & Capabilities → Team = your Apple Developer team"
echo "  • Target → Build Settings → Code Signing Entitlements = SuperGrokOffice/SuperGrokOffice.entitlements"
echo "  • Target → Info → Custom macOS Application Target Properties → use SuperGrokOffice/Info.plist"
echo "  • Target → Build Phases → Copy Bundle Resources → add PrivacyInfo.xcprivacy"

if [[ -d SuperGrokOffice.xcodeproj ]] || [[ -d *.xcodeproj 2>/dev/null ]]; then
  echo "  Found xcodeproj — continuing build"
else
  echo "  ⚠️  No .xcodeproj in repo yet."
  echo "  Create one: Xcode → File → New → Project → macOS → App"
  echo "  Product Name: SuperGrokOffice"
  echo "  Bundle ID: $BUNDLE_ID"
  echo "  Then drag all Swift sources + SuperGrokOffice/* into the target."
  echo ""
  echo "  Listing + privacy strings are already in:"
  echo "    docs/APP_STORE_LISTING.md"
  echo "    docs/APP_STORE_PRIVACY.md"
  echo "    SuperGrokOffice/Info.plist"
  exit 0
fi

echo ""
echo "[3/5] Archive (Release)"
if [[ -z "$TEAM_ID" ]]; then
  echo "  export DEVELOPMENT_TEAM=YOUR_TEAM_ID then re-run for CLI archive"
  echo "  Or: Xcode → Product → Archive"
else
  xcodebuild -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath build/SuperGrokOffice.xcarchive \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    archive
  echo "  ✅ Archive → build/SuperGrokOffice.xcarchive"
fi

echo ""
echo "[4/5] App Store Connect metadata (paste in browser)"
echo "  Name:        PSE Office OS"
echo "  Subtitle:    The last office app you'll ever need"
echo "  SKU:         PSE-OFFICE-OS-2054"
echo "  Version:     1.0.0 (100)"
echo "  Category:    Productivity"
echo "  Support URL: https://super-grok-office-pse-sent.vercel.app"
echo "  Full copy:   docs/APP_STORE_LISTING.md"
echo "  Privacy:     docs/APP_STORE_PRIVACY.md"
echo "  Screenshots: upload 01–06 (Chat → Key Forge → Pulse → Imagine → Calendar → MenuBar)"

echo ""
echo "[5/5] Upload & Submit"
echo "  Xcode → Organizer → Distribute App → App Store Connect → Upload"
echo "  Then https://appstoreconnect.apple.com → PSE Office OS → + Version → Submit for Review"
echo ""
echo "  Review notes:"
echo "  PSE Office OS stores the xAI master API key only in Keychain"
echo "  (WhenUnlockedThisDeviceOnly). No keys in UserDefaults or source."
echo "  Face ID unlocks Key Forge. Stripe is optional $29/mo Pro license."
echo ""
echo "Done. Ship when archive is in Organizer."
