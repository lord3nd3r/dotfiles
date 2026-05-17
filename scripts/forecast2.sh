#!/bin/bash

# forecast.sh: Fetch 10-day weather forecast using Pirate Weather API with compact side-by-side output

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

# Step 1: Geocode ZIP to lat/long using Open-Meteo (free, no key)
GEOCODE_URL="https://geocoding-api.open-meteo.com/v1/search?name=${ZIP_CODE}&count=1&format=json"
GEOCODE_RESPONSE=$(curl -s "${GEOCODE_URL}")
if [ -z "$GEOCODE_RESPONSE" ]; then
    /bin/echo -e "${RED}Error: Failed to geocode ZIP code${RESET}"
    exit 1
fi

LAT=$(/bin/echo "$GEOCODE_RESPONSE" | jq -r '.results[0].latitude // "N/A"')
LON=$(/bin/echo "$GEOCODE_RESPONSE" | jq -r '.results[0].longitude // "N/A"')
CITY=$(/bin/echo "$GEOCODE_RESPONSE" | jq -r '.results[0].name // "Unknown"')

if [ "$LAT" = "N/A" ] || [ "$LON" = "N/A" ]; then
    /bin/echo -e "${RED}Error: Invalid ZIP code or location not found${RESET}"
    exit 1
fi

# Step 2: Fetch 10-day forecast from Pirate Weather
API_URL="https://api.pirateweather.net/forecast/${API_KEY}/${LAT},${LON}?units=us"
RESPONSE=$(curl -s "${API_URL}")

# Check if curl failed or empty
if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    /bin/echo -e "${RED}Error: Failed to fetch weather data${RESET}"
    exit 1
fi

# Check for API errors (e.g., invalid key)
ERROR=$(/bin/echo "$RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
    /bin/echo -e "${RED}Error: API issue - ${ERROR}${RESET}"
    exit 1
fi

# Parse JSON response for daily forecast (up to 10 days)
DAILY=$(/bin/echo "$RESPONSE" | jq -r '.daily.data')

# Format output header
/bin/echo -e "${BLUE}${BOLD}┌────────────────────────────────────────────────────────────┐${RESET}"
/bin/echo -e "${BLUE}${BOLD}│ 🌤️ 10-Day Weather Forecast for ${CITY} (ZIP: ${ZIP_CODE}) │${RESET}"
/bin/echo -e "${BLUE}${BOLD}└────────────────────────────────────────────────────────────┘${RESET}"
/bin/echo -e "${GREEN}${BOLD}🚀 Powered by Pirate Weather (NWS)${RESET}"
/bin/echo ""

# Collect all days' data first into parallel arrays
declare -a DATES ICONS WEATHERS TEMP_HIGHS TEMP_LOWS HUMIDITIES WINDS
while IFS= read -r day; do
    TIMESTAMP=$(/bin/echo "$day" | jq -r '.time')
    DATE=$(date -d "@${TIMESTAMP}" +%a,\ %b\ %d 2>/dev/null || /bin/echo "N/A")
    WEATHER=$(/bin/echo "$day" | jq -r '.summary // "N/A"')
    # Truncate at last space within 24 characters to avoid cutting words (wider for 2 columns)
    WEATHER=$(echo "$WEATHER" | awk '{if (length($0) > 24) {for (i=24; i>0; i--) if (substr($0,i,1) == " ") {print substr($0,1,i); exit}} else print $0}')
    ICON=$(get_weather_icon "$(/bin/echo "$day" | jq -r '.icon // "unknown"')")
    TEMP_HIGH=$(/bin/echo "$day" | jq -r '.temperatureHigh // "--"' | cut -d. -f1)
    TEMP_LOW=$(/bin/echo "$day" | jq -r '.temperatureLow // "--"' | cut -d. -f1)
    HUMIDITY=$(/bin/echo "$day" | jq -r '.humidity * 100 // "--"' | cut -d. -f1)
    WIND=$(/bin/echo "$day" | jq -r '.windSpeed // "--"' | cut -d. -f1)

    DATES+=("$DATE")
    ICONS+=("$ICON")
    WEATHERS+=("$WEATHER")
    TEMP_HIGHS+=("$TEMP_HIGH")
    TEMP_LOWS+=("$TEMP_LOW")
    HUMIDITIES+=("$HUMIDITY")
    WINDS+=("$WIND")
done < <(/bin/echo "$DAILY" | jq -c '.[]' | head -n 10)

NUM_DAYS=${#DATES[@]}

# Print days side by side (2 days per row)
for ((i=0; i<NUM_DAYS; i+=2)); do
    /bin/echo -e "${BLUE}${BOLD}┌─────────────────────────────┬─────────────────────────────┐${RESET}"
    
    # Date/Icon row
    printf "${BLUE}${BOLD}│${RESET} ${YELLOW}%-22s${RESET} │ ${YELLOW}%-22s${RESET} ${BLUE}${BOLD}│${RESET}\n" \
        "${DATES[i]:- } ${ICONS[i]:- }" "${DATES[i+1]:- } ${ICONS[i+1]:- }"
    
    # Conditions row
    printf "${BLUE}${BOLD}│${RESET} %-24s ${BLUE}${BOLD}│${RESET} %-24s ${BLUE}${BOLD}│${RESET}\n" \
        "${WEATHERS[i]:- }" "${WEATHERS[i+1]:- }"
    
    # High/Low row
    printf "${BLUE}${BOLD}│${RESET} Hi:%-2s°F Lo:%-2s°F │ Hi:%-2s°F Lo:%-2s°F ${BLUE}${BOLD}│${RESET}\n" \
        "${TEMP_HIGHS[i]:- }" "${TEMP_LOWS[i]:- }" "${TEMP_HIGHS[i+1]:- }" "${TEMP_LOWS[i+1]:- }"
    
    # Humidity/Wind row
    printf "${BLUE}${BOLD}│${RESET} Hum:%-2s%% Wind:%-3smph │ Hum:%-2s%% Wind:%-3smph ${BLUE}${BOLD}│${RESET}\n" \
        "${HUMIDITIES[i]:- }" "${WINDS[i]:- }" "${HUMIDITIES[i+1]:- }" "${WINDS[i+1]:- }"
    
    /bin/echo -e "${BLUE}${BOLD}└─────────────────────────────┴─────────────────────────────┘${RESET}"
    /bin/echo ""
done
