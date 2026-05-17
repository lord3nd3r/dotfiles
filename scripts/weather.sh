#!/bin/bash

# weather.sh: Fetch current weather using Pirate Weather API with cool icons

# Check if ZIP code is provided
if [ -z "$1" ]; then
    /bin/echo -e "\033[31mError: Please provide a ZIP code (e.g., weather 32444)\033[0m"
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

# Function to map weather conditions to cool icons
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

# Step 2: Fetch weather from Pirate Weather
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

# Parse JSON response
TEMP=$(/bin/echo "$RESPONSE" | jq -r '.currently.temperature // "N/A"')
FEELS_LIKE=$(/bin/echo "$RESPONSE" | jq -r '.currently.apparentTemperature // "N/A"')
HUMIDITY=$(/bin/echo "$RESPONSE" | jq -r '.currently.humidity * 100 // "N/A"' | cut -d. -f1)  # Convert to %
WEATHER=$(/bin/echo "$RESPONSE" | jq -r '.currently.summary // "N/A"')
WIND=$(/bin/echo "$RESPONSE" | jq -r '.currently.windSpeed // "N/A"')
ICON=$(get_weather_icon "$(/bin/echo "$RESPONSE" | jq -r '.currently.icon // "unknown"')")

# Get current date and time for header
CURRENT_TIME=$(date "+%a, %b %d %I:%M %p")

# Format output with ASCII box and cool styling
/bin/echo -e "${BLUE}${BOLD}┌──────────────────────────────────────────┐${RESET}"
/bin/echo -e "${BLUE}${BOLD}│ 🌍 Weather for ${CITY} (ZIP: ${ZIP_CODE}) ${ICON} │${RESET}"
/bin/echo -e "${BLUE}${BOLD}│ ${CURRENT_TIME}                    │${RESET}"
/bin/echo -e "${BLUE}${BOLD}├──────────────────────────────────────────┤${RESET}"
/bin/echo -e "${BLUE}${BOLD}│ ${YELLOW}Conditions:${RESET} ${WEATHER} ${ICON}${RESET}"
/bin/echo -e "${BLUE}${BOLD}│ ${YELLOW}Temperature:${RESET} ${TEMP}°F (Feels like ${FEELS_LIKE}°F)${RESET}"
/bin/echo -e "${BLUE}${BOLD}│ ${YELLOW}Humidity:${RESET} ${HUMIDITY}%${RESET}"
/bin/echo -e "${BLUE}${BOLD}│ ${YELLOW}Wind Speed:${RESET} ${WIND} mph${RESET}"
/bin/echo -e "${BLUE}${BOLD}└──────────────────────────────────────────┘${RESET}"
/bin/echo -e "${GREEN}${BOLD}🚀 Powered by Pirate Weather (NWS)${RESET}"
