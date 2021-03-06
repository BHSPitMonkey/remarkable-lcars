#!/usr/bin/env bash
#
# remarkable-lcars
#
# Generate an LCARS-inspired suspend screen for the reMarkable Tablet (2)
#
# ImageMagick CLI docs:
# https://imagemagick.org/script/command-line-processing.php

set -o errexit
set -o nounset
set -o pipefail

# Read config file
if [[ -f /opt/etc/remarkable-lcars.conf ]]; then
  . /opt/etc/remarkable-lcars.conf
elif [[ -f .remarkable-lcars.conf ]]; then
  . .remarkable-lcars.conf
else
  echo "Config file not found. Exiting."
  exit 1
fi

# Internal configuration
PATH="/opt/bin:/opt/sbin:$PATH"
WEATHER_JSON_PATH='/tmp/remarkable-lcars-weather.json'
INTERMEDIATE_OUTPUT_PATH='/tmp/remarkable-lcars-output.png'
URL="https://api.openweathermap.org/data/2.5/onecall?lat=${LOCATION_LATITUDE}&lon=${LOCATION_LONGITUDE}&exclude=current,minutely,hourly,alerts&appid=${OPENWEATHER_KEY}&units=imperial"
if [[ -d 'assets' ]]; then
  ASSETS_DIR='assets'
else
  ASSETS_DIR='/opt/share/remarkable-lcars'
fi

# Wait for network to come up
function wait_for_network() {
  for i in {1..20}; do
    local count=$(ifconfig wlan0 | grep inet | wc -l)
    if [[ $count -eq 0 ]]; then
      echo "WiFi still not up..."
      sleep 3
    else
      echo "WiFi is up."
      return 0
    fi
  done
  echo "Timed out waiting for WiFi to come up."
  exit 1
}

# Round a floating-point number to a whole integer
function round() {
  printf "%.0f\n" "$1"
}

# Parse (already-loaded) weather data for a specified day (0-4)
function get_day() {
  local dt=$(echo $WEATHER_DATA | jq .daily[$1].dt)
  local dow=$(date -d @$dt +"%A")

  local low=$(round $(echo $WEATHER_DATA | jq .daily[$1].temp.min))
  local high=$(round $(echo $WEATHER_DATA | jq .daily[$1].temp.max))

  local icon=$(echo $WEATHER_DATA | jq -r .daily[$1].weather[0].icon)

  echo "${dow^^} $low $high ${ASSETS_DIR}/icons/$icon.png"
}

# Get a random image
function get_random_image() {
  if [[ $# -ge 2 ]] && [[ -n "$2" ]]; then
    local num="$2"
  else
    local num=$(( (RANDOM % 3) + 1 ))
  fi
  echo "${ASSETS_DIR}/img0${num}.png"
}

# Wait for the network to come up, if we're on the reMarkable device
if [[ "$(hostname)" == "reMarkable" ]]; then
  wait_for_network
fi

# Fetch weather data, if not already cached
if [[ ! -f "$WEATHER_JSON_PATH" ]]; then
  # FIXME: Need a way for this to expire, or for systemd unit to remove/skip it
  echo 'Getting weather data...'
  curl --retry 5 --retry-delay 2 -o "$WEATHER_JSON_PATH" "$URL"
fi
WEATHER_DATA=$(cat $WEATHER_JSON_PATH)

# Format weather data
get_day 0
read day_0_day day_0_lo day_0_hi day_0_icon < <(get_day 0)
read day_1_day day_1_lo day_1_hi day_1_icon < <(get_day 1)
read day_2_day day_2_lo day_2_hi day_2_icon < <(get_day 2)
read day_3_day day_3_lo day_3_hi day_3_icon < <(get_day 3)

# Generate date strings
DATE=$(date "+%A, %B %d (%T)")
STARDATE=$(( ( RANDOM % 10000 )  + 1000 )).$((RANDOM % 9))

# Render the image
DATES_Y=220
WEATHER_X=340
WEATHER_X_TEMPS=$((WEATHER_X + 120))
WEATHER_X_DAY=$((WEATHER_X + 15))
WEATHER_X_SPACING=200
convert "${ASSETS_DIR}/bg.png" \
  -font "${ASSETS_DIR}/fonts/Okuda.otf" \
  -fill white \
  -pointsize 36 \
  -draw "text 525,$DATES_Y '${DATE^^}'" \
  -draw "text 1000,$DATES_Y '$STARDATE'" \
  -pointsize 24 \
  -draw "text $((WEATHER_X_DAY + (WEATHER_X_SPACING * 0))),435 '$day_0_day'" \
  -draw "text $((WEATHER_X_DAY + (WEATHER_X_SPACING * 1))),435 '$day_1_day'" \
  -draw "text $((WEATHER_X_DAY + (WEATHER_X_SPACING * 2))),435 '$day_2_day'" \
  -draw "text $((WEATHER_X_DAY + (WEATHER_X_SPACING * 3))),435 '$day_3_day'" \
  -pointsize 52 \
  -draw "text $((WEATHER_X_TEMPS + (WEATHER_X_SPACING * 0))),380 '$day_0_hi°F'" \
  -draw "text $((WEATHER_X_TEMPS + (WEATHER_X_SPACING * 1))),380 '$day_1_hi°F'" \
  -draw "text $((WEATHER_X_TEMPS + (WEATHER_X_SPACING * 2))),380 '$day_2_hi°F'" \
  -draw "text $((WEATHER_X_TEMPS + (WEATHER_X_SPACING * 3))),380 '$day_3_hi°F'" \
  \
  -fill blue \
  -pointsize 36 \
  -draw "text 355,$DATES_Y 'EARTH DATE'" \
  -draw "text 850,$DATES_Y 'STARDATE'" \
  -pointsize 52 \
  -draw "text $((WEATHER_X_TEMPS + (WEATHER_X_SPACING * 0))),430 '$day_0_lo°F'" \
  -draw "text $((WEATHER_X_TEMPS + (WEATHER_X_SPACING * 1))),430 '$day_1_lo°F'" \
  -draw "text $((WEATHER_X_TEMPS + (WEATHER_X_SPACING * 2))),430 '$day_2_lo°F'" \
  -draw "text $((WEATHER_X_TEMPS + (WEATHER_X_SPACING * 3))),430 '$day_3_lo°F'" \
  \
  -draw "image SrcOver $((WEATHER_X + (WEATHER_X_SPACING * 0))),310 120,120 '$day_0_icon'" \
  -draw "image SrcOver $((WEATHER_X + (WEATHER_X_SPACING * 1))),310 120,120 '$day_1_icon'" \
  -draw "image SrcOver $((WEATHER_X + (WEATHER_X_SPACING * 2))),310 120,120 '$day_2_icon'" \
  -draw "image SrcOver $((WEATHER_X + (WEATHER_X_SPACING * 3))),310 120,120 '$day_3_icon'" \
  \
  $(get_random_image) -composite \
  "$INTERMEDIATE_OUTPUT_PATH"

# Move to final output path if specified
if [[ $# -ge 1 ]] && [[ -n "$1" ]]; then
  cp "$INTERMEDIATE_OUTPUT_PATH" "$1"
  echo "Wrote new image to $1"
else
  echo "Warning: No output path specified! New image written to $INTERMEDIATE_OUTPUT_PATH"
fi

