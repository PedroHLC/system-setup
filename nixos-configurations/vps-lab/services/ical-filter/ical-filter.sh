#!/usr/bin/env bash
set -eu
ICAL_R=/var/persistent/secrets/ical
ICAL_URL=$(cat "$ICAL_R/url.txt")
ICAL_PREFIX=$(cat "$ICAL_R/prefix.txt")

_og=$(curl "$ICAL_URL")

[ -z "$_og" ] && exit 1

for f in "$ICAL_R"/*.ical; do
  awk -v pattern="^SUMMARY:$(cat "$f")" '
BEGIN { printf "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//PedroHLC//NONSGML pedrohlc.com AWK4ever 5.2.2//EN\r\nCALSCALE:GREGORIAN\r\nX-WR-CALNAME:Calendar\r\n" }
/BEGIN:VEVENT/ { in_event = 1; event_block = "" }
in_event { event_block = event_block $0 "\n" }
$0 ~ pattern { has_pattern = 1 }
/END:VEVENT/ {
  if (has_pattern) { printf "%s", event_block }
  in_event = 0; has_pattern = 0; event_block = ""
}
END { printf "END:VCALENDAR\r\n" }
' > "/srv/http/ical/$ICAL_PREFIX-$(basename "$f")" <<< "$_og"
done
