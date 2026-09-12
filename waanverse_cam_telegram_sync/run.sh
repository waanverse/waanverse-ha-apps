#!/usr/bin/with-contenv bashio
set +e

BOT_TOKEN=$(bashio::config 'telegram_bot_token')
CHAT_ID=$(bashio::config 'telegram_chat_id')
TRIGGER_MESSAGE=$(bashio::config 'trigger_message')
PREVIEW_WIDTH=$(bashio::config 'preview_width')
SENT_LOG="/data/telegram_sent.log"
OFFSET_FILE="/data/tg_offset"

touch "$SENT_LOG"
[ -f "$OFFSET_FILE" ] || echo 0 > "$OFFSET_FILE"

sync_clips() {
  local count=0
  while read -r f; do
    base=$(basename "$f")
    if ! grep -qF "$base" "$SENT_LOG"; then
      preview="/tmp/${base%.mkv}_preview.mkv"
      ffmpeg -y -nostdin -i "$f" -vf "scale=${PREVIEW_WIDTH}:-2" -c:v libx264 -preset fast -crf 28 \
        -c:a aac -b:a 64k "$preview" </dev/null 2>/dev/null
      if [ -f "$preview" ] && [ "$(stat -c%s "$preview")" -lt 50000000 ]; then
        curl -s -F chat_id="$CHAT_ID" -F caption="$base" -F video=@"$preview" \
          "https://api.telegram.org/bot${BOT_TOKEN}/sendVideo" > /dev/null
        echo "$base" >> "$SENT_LOG"
        count=$((count+1))
        bashio::log.info "Sent ${base}"
      fi
      rm -f "$preview"
    fi
  done < <(find /media/security_recordings -name "cam1_*.mkv" -mmin +1 | sort)

  curl -s -F chat_id="$CHAT_ID" -F text="Sync complete: sent ${count} new clip(s)." \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" > /dev/null
  bashio::log.info "Sync finished — ${count} clip(s) sent"
}

bashio::log.info "Listening for trigger message: ${TRIGGER_MESSAGE}"

while true; do
  offset=$(cat "$OFFSET_FILE")
  resp=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?timeout=30&offset=$((offset+1))")

  while read -r update; do
    [ -z "$update" ] && continue
    update_id=$(echo "$update" | jq -r '.update_id')
    msg_chat_id=$(echo "$update" | jq -r '.message.chat.id // empty')
    msg_text=$(echo "$update" | jq -r '.message.text // empty')
    echo "$update_id" > "$OFFSET_FILE"

    if [ "$msg_chat_id" = "$CHAT_ID" ]; then
      # Case-insensitive exact match against the configured trigger phrase
      if [ "$(echo "$msg_text" | tr '[:upper:]' '[:lower:]')" = "$(echo "$TRIGGER_MESSAGE" | tr '[:upper:]' '[:lower:]')" ]; then
        bashio::log.info "Trigger message received — starting sync"
        sync_clips
      fi
    fi
  done < <(echo "$resp" | jq -c '.result[]?')

  sleep 2
done