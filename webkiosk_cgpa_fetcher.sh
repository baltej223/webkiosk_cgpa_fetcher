#!/bin/bash

# ========================
# Script Configuration
# ========================
LOGIN_URL="https://webkiosk.thapar.edu/CommonFiles/UserAction.jsp"
CGPA_URL="https://webkiosk.thapar.edu/StudentFiles/Exam/StudCGPAReport.jsp"
COOKIES_FILE="cookies.txt"
OUTPUT_FILE="latest_cgpa.html"
DEFAULT_SLEEP=150

# ========================
# Usage Function
# ========================
usage() {
  echo "Usage: $0 --roll-number <num> --password <pass> [-s <seconds>]"
  echo ""
  echo "Options:"
  echo "  -r, --roll-number   Your Enrollment Number (e.g., 102103682)"
  echo "  -p, --password      Your WebKiosk password"
  echo "  -s, --sleep         Sleep interval in seconds (default: $DEFAULT_SLEEP)"
  exit 1
}

# ========================
# Argument Parsing
# ========================
ENROLLMENT_NO=""
PASSWORD=""
SLEEP_INTERVAL=$DEFAULT_SLEEP

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -r|--roll-number)
      ENROLLMENT_NO="$2"
      shift
      ;;
    -p|--password)
      PASSWORD="$2"
      shift
      ;;
    -s|--sleep)
      SLEEP_INTERVAL="$2"
      shift
      ;;
    *)
      echo "[!] Error: Unknown parameter passed: $1"
      usage
      ;;
  esac
  shift
done

if [ -z "$ENROLLMENT_NO" ] || [ -z "$PASSWORD" ]; then
  echo "[!] Error: Enrollment Number and Password are required."
  echo ""
  usage
fi

echo "[*] Starting CGPA checker for enrollment: $ENROLLMENT_NO"
echo "[*] Using sleep interval: $SLEEP_INTERVAL seconds"

# ========================
# Cleanup on Exit
# ========================
trap 'echo -e "\n[+] Exiting and cleaning up..."; rm -f "$COOKIES_FILE"; exit 0' SIGINT SIGTERM

# ========================
# Login function
# ========================
login() {
  echo "[*] Logging into WebKiosk..."
  # Use curl to perform the login POST request and save cookies
  # -s: silent mode
  # -c: cookie-jar (save cookies to this file)
  # -L: follow redirects
  # -d: data for POST request
  curl -s -c "$COOKIES_FILE" -L "$LOGIN_URL" \
    -d "txtuType=Member+Type" \
    -d "UserType=S" \
    -d "txtCode=Enrollment+No" \
    -d "MemberCode=$ENROLLMENT_NO" \
    -d "txtPin=Password%2FPin" \
    -d "Password=$PASSWORD" \
    -d "BTNSubmit=Submit" > /dev/null # Redirect output, we only care about cookies

  if [ ! -f "$COOKIES_FILE" ]; then
      echo "[!] Login failed. Cookie file not created."
      return 1
  fi
  echo "[+] Login request sent. Verifying session..."
  return 0
}

# ========================
# Fetch CGPA report
# ========================
fetch_cgpa() {
  echo "[*] Fetching CGPA report..."
  # Use curl to get the CGPA page using the saved cookies
  # -s: silent mode
  # -b: cookie file (read cookies from this file)
  response=$(curl -s -b "$COOKIES_FILE" "$CGPA_URL")

  if echo "$response" | grep -qi "session timeout\|login\|not authorized\|useraction.jsp"; then
    echo "[!] Session expired or not logged in."
    return 1
  fi

  echo "$response" > "$OUTPUT_FILE"
  echo "[+] CGPA report saved to $OUTPUT_FILE"
  return 0
}

# ========================
# Main Loop
# ========================
login # Initial login

while true; do
  if ! fetch_cgpa; then
    echo "[*] Re-attempting login..."
    login
    fetch_cgpa
  fi
  echo ""
  echo "[*] Sleeping for $SLEEP_INTERVAL seconds..."
  sleep "$SLEEP_INTERVAL"
done
