# App Store Privacy — services.psemanagement.supergrok

**Display Name:** PSE Office OS  
**Bundle ID:** services.psemanagement.supergrok  
**Category:** Productivity + Business

## Info.plist usage strings

```
NSFaceIDUsageDescription
PSE Office OS uses Face ID to unlock the master Key Forge key stored in the Secure Enclave. Biometrics never leave this device.

NSCalendarsUsageDescription
Office OS reads your calendar to auto-block deep-work time and schedule follow-ups from Chat Brain and Inbox Zero.

NSCalendarsFullAccessUsageDescription
Full calendar access lets Calendar Flow optimize time blocks and defend focus sessions.

NSContactsUsageDescription
Contacts are used only to resolve names in Inbox Zero drafts and Team Sync meeting notes. Never uploaded for advertising.

NSMicrophoneUsageDescription
Optional voice input for Chat Brain dictation. Audio is processed for transcription only and is not stored permanently.

NSPhotoLibraryUsageDescription
Imagine Studio can save generated office assets (decks, diagrams) to your photo library when you choose Export.

NSCameraUsageDescription
Optional camera for document capture into Docs Forge. Images stay on device unless you explicitly send them to Grok vision.
```

## App Privacy questionnaire (App Store Connect)

| Question | Answer |
|----------|--------|
| Data Used to Track You | **No** |
| Data Linked to You | **None** (master key stays on-device in Keychain) |
| Data Not Linked to You | Product Interaction; Other User Content (prompts to xAI for app functionality) |
| Third parties | **xAI** (api.x.ai) inference only; **Stripe** billing only after purchase |

## PrivacyInfo.xcprivacy

Ship `SuperGrokOffice/PrivacyInfo.xcprivacy` in the app target (Required Reason APIs: UserDefaults CA92.1, File Timestamp C617.1, System Boot Time 35F9.1). Tracking = false.

## Screenshots required (macOS)

1. MenuBar Presence  
2. Chat Brain  
3. Project Pulse  
4. Imagine Studio  
5. Key Forge  
6. Calendar Flow  

Use 2880×1800 (or 1280×800) dark UI captures. Marketing frames available under `docs/screenshots/`.

## Review notes (paste in App Store Connect)

> PSE Office OS stores the xAI master API key only in the macOS Keychain with WhenUnlockedThisDeviceOnly accessibility. No API keys in UserDefaults, env files, or source. Face ID unlocks Key Forge. Chat prompts are sent to xAI solely for app functionality. Stripe is used only for the optional $29/mo Office license.
