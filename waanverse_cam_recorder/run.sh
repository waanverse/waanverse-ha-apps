#!/usr/bin/with-contenv bashio
set +e

mkdir -p /media/security_recordings

CAMERA_URL=$(bashio::config 'camera_rtsp_url')
SHOULD_RECORD_ENTITY=$(bashio::config 'should_record_entity')
RETENTION_DAYS=$(bashio::config 'retention_days')

bashio::log.info "Config loaded — camera: ${CAMERA_URL}, gate: ${SHOULD_RECORD_ENTITY}"

( while true; do
    find /media/security_recordings -name "cam1_*.mkv" -mtime +"${RETENTION_DAYS}" -delete
    sleep 3600
  done ) &

get_state() {
  local entity="$1"
  local response state
  response=$(curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
       -H "Content-Type: application/json" \
       "http://supervisor/core/api/states/${entity}" 2>/dev/null)
  state=$(echo "$response" | jq -r '.state // empty' 2>/dev/null)
  [ -z "$state" ] && echo "unknown" || echo "$state"
}

FFMPEG_PID=""
is_recording=false

start_ffmpeg() {
  if [ "$is_recording" = true ]; then return; fi
  ffmpeg -rtsp_transport tcp -timeout 5000000 \
    -i "$CAMERA_URL" \
    -fflags +genpts \
    -c copy -f segment -segment_time 600 -segment_atclocktime 1 \
    -reset_timestamps 1 -strftime 1 \
    /media/security_recordings/cam1_%Y%m%d_%H%M%S.mkv &
  FFMPEG_PID=$!
  is_recording=true
  bashio::log.info "Recording started"
}

stop_ffmpeg() {
  if [ -n "$FFMPEG_PID" ] && kill -0 "$FFMPEG_PID" 2>/dev/null; then
    kill "$FFMPEG_PID"
    wait "$FFMPEG_PID" 2>/dev/null
  fi
  FFMPEG_PID=""
  [ "$is_recording" = true ] && bashio::log.info "Recording stopped"
  is_recording=false
}

trap 'stop_ffmpeg; exit 0' SIGTERM SIGINT
bashio::log.info "Starting template-gated recorder loop"

while true; do
  gate=$(get_state "$SHOULD_RECORD_ENTITY")

  if [ "$gate" = "on" ]; then
    start_ffmpeg
  elif [ "$gate" = "off" ]; then
    stop_ffmpeg
  fi

  if [ "$is_recording" = true ] && ! kill -0 "$FFMPEG_PID" 2>/dev/null; then
    bashio::log.warning "ffmpeg exited unexpectedly — restarting"
    is_recording=false
    start_ffmpeg
  fi

  sleep 5
done