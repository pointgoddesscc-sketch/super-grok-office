#!/bin/bash
# =========================================================
# Super Grok macOS Office - API Kit
# Team: psemanagement.services
# Bundle ID: services.psemanagement.supergrok
# Everything starts from here - keys created from macOS app
# =========================================================

set -e

# --- KEY FACTORY: Get key from macOS Keychain (created by app) ---
get_office_key() {
  OFFICE_KEY=$(security find-generic-password -s "services.psemanagement.supergrok.office" -w 2>/dev/null || true)
  if [ -n "$OFFICE_KEY" ]; then
    echo "$OFFICE_KEY"
    return
  fi
  MASTER_KEY=$(security find-generic-password -s "services.psemanagement.supergrok.master" -w 2>/dev/null || true)
  if [ -n "$MASTER_KEY" ]; then
    echo "$MASTER_KEY"
    return
  fi
  if [ -n "$XAI_API_KEY" ]; then
    echo "$XAI_API_KEY"
    return
  fi
  echo "❌ No office key found. Open Super Grok Office app > Settings > Office Keys > Create Office Key"
  echo "Or export XAI_API_KEY from console.x.ai"
  exit 1
}

XAI_KEY=$(get_office_key)
echo "✅ Using Office Key: ${XAI_KEY:0:15}... (psemanagement.services)"

echo ""
echo "--- 1. Fixing median function ---"
curl -s https://api.x.ai/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $XAI_KEY" \
  -d '{
    "model": "grok-4",
    "input": "Fix this function and explain the bug: function median(a){a.sort();return a[a.length/2]}"
  }' | jq -r '.output_text // .output[0].content[0].text // .'

echo ""
echo "--- 2. Office Brain Question ---"
curl -s https://api.x.ai/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $XAI_KEY" \
  -d '{
    "model": "grok-4",
    "input": [
        {
            "role": "system",
            "content": "You are Grok, the office brain for PSE Management (psemanagement.services). You run the entire macOS Office OS where everything is connected. Everything starts from you."
        },
        {
            "role": "user",
            "content": "What is the meaning of life, the universe, and everything?"
        }
    ]
  }' | jq -r '.output_text // .output[0].content[0].text // .'

echo ""
echo "--- 3. Generating Image ---"
curl -s https://api.x.ai/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $XAI_KEY" \
  -d '{
    "model": "grok-imagine-image",
    "prompt": "A collage of London landmarks in a stenciled street-art style"
  }' | jq .

echo ""
echo "--- 4. Generating Video ---"
REQUEST_ID=$(curl -sS -X POST https://api.x.ai/v1/videos/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $XAI_KEY" \
  -d '{
    "model": "grok-imagine-video",
    "prompt": "A glowing crystal-powered rocket launching from Mars"
  }' | jq -r '.request_id // .id')

if [ -z "$REQUEST_ID" ] || [ "$REQUEST_ID" = "null" ]; then
  echo "Failed to start video generation"
  exit 1
fi

echo "Started video: $REQUEST_ID"
echo "Polling..."

while true; do
  RESULT=$(curl -sS "https://api.x.ai/v1/videos/$REQUEST_ID" \
    -H "Authorization: Bearer $XAI_KEY")
  STATUS=$(echo "$RESULT" | jq -r '.status // .state')
  echo "Status: $STATUS"
  
  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "done" ] || [ "$STATUS" = "succeeded" ]; then
    VIDEO_URL=$(echo "$RESULT" | jq -r '.video_url // .video.url // .url')
    echo "✅ Video Ready: $VIDEO_URL"
    echo "$RESULT" | jq .
    break
  fi
  
  if [ "$STATUS" = "failed" ] || [ "$STATUS" = "expired" ] || [ "$STATUS" = "error" ]; then
    echo "❌ Failed:"
    echo "$RESULT" | jq .
    exit 1
  fi
  
  sleep 5
done

echo ""
echo "🎉 All office tasks done - psemanagement.services"
