#!/bin/bash

# forecast.sh: Fetch 10-day weather forecast using Pirate Weather API in compact IRC-style output

# Check if ZIP code is provided
if [ -z "$1" ]; then
    /bin/echo -e "\033[31mError: Please provide a ZIP code (e.g., forecast 32444)\033[0m"
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    /bin/echo -e "\033[31mError: jq is not installed. Install it with 'sudo apt install jq'\033[0m"
    exit 1
fi

# Configuration
API_KEY="$PIRATE_API_KEY"  # Set in ~/.bashrc
if [ -z "$API_KEY" ]; then
    /bin/echo -e "\033[31mError: PIRATE_API_KEY environment variable not set. Get a free key at pirateweather.net\033[0m"
    exit 1
fi
ZIP_CODE="$1"
COUNTRY="us"

# Colors for output
RED='\033[31m'
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
BLUE='\033[34m'
BOLD='\033[1m'
RESET='\033[0m'

# Function to map weather conditions to cute icons
get_weather_icon() {
    local condition="$1"
    case "$condition" in
        "clear-day") /bin/echo "☀️" ;;
        "clear-night") /bin/echo "🌙" ;;
        "rain") /bin/echo "🌧️" ;;
        "snow") /bin/echo "❄️" ;;
        "sleet") /bin/echo "🌨️" ;;
        "wind") /bin/echo "💨" ;;
        "fog") /bin/echo "🌫️" ;;
        "cloudy") /bin/echo "☁️" ;;
        "partly-cloudy-day") /bin/echo "⛅" ;;
        "partly-cloudy-night") /bin/echo "🌤️" ;;
        *) /bin/echo "🌈" ;;  # Default for unknown conditions
    esac
}

# Function to map icon to short weather summary
get_short_summary() {
    local condition="$1"
    case "$condition" in
        "clear-day") /bin/echo "Sky is Clear" ;;
        "clear-night") /bin/echo "Clear Night" ;;
        "rain") /bin/echo "Moderate Rain" ;;
        "snow") /bin/echo "Snow" ;;
        "sleet") /bin/echo "Sleet" ;;
        "wind") /bin/echo "Windy" ;;
        "fog") /bin/echo "Foggy" ;;
        "cloudy") /bin/echo "Overcast Clouds" ;;
        "partly-cloudy-day") /bin/echo "Few Clouds" ;;
        "partly-cloudy-night") /bin/echo "Scattered Clouds" ;;
        *) /bin/echo "Variable Weather" ;;  # Default
    esac
}

# Step 1: Geocode ZIP to lat/long using Open-Meteo (free, no key)
GEOCODE_URL="https://geocoding-api.open-meteo.com/v1/search?name=${ZIP_CODE}&count=1&format=json"
GEOCODE_RESPONSE=$(curl -s "${GEOCODE_URL}")
if [ -z "$GEOCODE_RESPONSE" ]; then
    /bin/echo -e "${RED}Error: Failed to geocode ZIP code${RESET}"
    exit 1
fi

LAT=$(echo "$GEOCODE_RESPONSE" | jq -r '.results[0].latitude // "N/A"')
LON=$(echo "$GEOCODE_RESPONSE" | jq -r '.results[0].longitude // "N/A"')
CITY=$(echo "$GEOCODE_RESPONSE" | jq -r '.results[0].name // "Unknown"')
STATE=$(echo "$GEOCODE_RESPONSE" | jq -r '.results[0].admin1 // "Unknown"')

if [ "$LAT" = "N/A" ] || [ "$LON" = "N/A" ]; then
    /bin/echo -e "${RED}Error: Invalid ZIP code or location not found${RESET}"
    exit 1
fi

CITY_FULL="${CITY}, ${STATE}, USA"

# Step 2: Fetch 10-day forecast from Pirate Weather
API_URL="https://api.pirateweather.net/forecast/${API_KEY}/${LAT},${LON}?units=us"
RESPONSE=$(curl -s "${API_URL}")

# Check if curl failed or empty
if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    /bin/echo -e "${RED}Error: Failed to fetch weather data${RESET}"
    exit 1
fi

# Check for API errors (e.g., invalid key)
ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
    /bin/echo -e "${RED}Error: API issue - ${ERROR}${RESET}"
    exit 1
fi

# Parse JSON response for daily forecast (up to 10 days)
DAILY=$(echo "$RESPONSE" | jq '.daily.data')

# Build the compact forecast line
FORECAST_LINE=":: ${CITY_FULL} ::"
while IFS= read -r day; do
    TIMESTAMP=$(echo "$day" | jq -r '.time')
    DAY_NAME=$(date -d "@${TIMESTAMP}" +%A)
    ICON=$(get_weather_icon "$(echo "$day" | jq -r '.icon // "unknown"')")
    SUMMARY=$(get_short_summary "$(echo "$day" | jq -r '.icon // "unknown"')")
    TEMP_HIGH=$(echo "$day" | jq -r '.temperatureHigh // "--"' | cut -d. -f1)
    TEMP_LOW=$(echo "$day" | jq -r '.temperatureLow // "--"' | cut -d. -f1)

    # Color temps: yellow for high, cyan for low
    HIGH_COLORED="${YELLOW}${TEMP_HIGH}F${RESET}"
    LOW_COLORED="${CYAN}${TEMP_LOW}F${RESET}"

    FORECAST_LINE="${FORECAST_LINE} ${DAY_NAME} ${ICON} ${SUMMARY} ${HIGH_COLORED} / ${LOW_COLORED} ::"
done < <(echo "$DAILY" | jq -c '.[]' | head -n 10)

# Output the forecast line
/bin/echo -e "${FORECAST_LINE}"
/bin/echo -e "${GREEN}🚀 Powered by Pirate Weather (NWS)${RESET}"
