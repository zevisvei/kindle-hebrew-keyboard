#!/bin/sh
# Hebrew keyboard control (KUAL).
# enable  : mount overlay (if needed) + make Hebrew the active keyboard
# disable : switch active keyboard back to English (overlay stays; harmless)
# status  : report the currently active keyboard language
#
# NOTE: /usr/share/keyboard is ALWAYS a mountpoint (squashfs). Detect our overlay
# by the he/ dir, NOT by `mountpoint`. We do NOT umount on disable: the bind is
# busy (kb holds it) so umount fails, and it is unnecessary -- the overlay also
# contains every stock language, so switching `current` back to en_US is enough.

KBROOT=/var/local/kbroot
TARGET=/usr/share/keyboard
CONF=/var/local/system/keyboard.conf
PREF=/var/local/java/prefs/Keyboard.preferences
LOG=/mnt/us/extensions/hebrew-keyboard/hebkb.log

stamp() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

# Print messages at the BOTTOM of the screen (like other KUAL extensions),
# without clearing the whole screen. Rows are ~24 px tall; derive count from yres.
_yres() { eips -i 2>/dev/null | sed -n 's/.*[^_]yres:[^0-9]*\([0-9][0-9]*\).*/\1/p' | head -1; }
YR=$(_yres); [ -n "$YR" ] || YR=800
BR=$(( YR / 24 - 4 )); [ "$BR" -gt 0 ] || BR=24
LN=0
# pad/truncate to a fixed width so the line clears itself and never overflows
# the screen (eips errors past the right edge). ~34 cols fits 600 px screens.
say() { eips 1 $((BR+LN)) "$(printf '%-34.34s' "  $1")"; LN=$((LN+1)); }

restart_kb() { restart kb >/dev/null 2>&1 || { stop kb >/dev/null 2>&1; start kb >/dev/null 2>&1; }; }
set_lang() {   # $1 = ACTIVE lang id. selected = BOTH keyboards (he:en_US) so the
               # on-screen globe key can switch he<->en; current = the active one.
    sed -i "s/\"current\": *\"[^\"]*\"/\"current\": \"$1\"/;  s/\"selected\": *\"[^\"]*\"/\"selected\": \"he:en_US\"/" "$CONF" 2>/dev/null
    sed -i "s/^keyboard=.*/keyboard=$1/" "$PREF" 2>/dev/null
}
current_lang() { sed -n 's/.*"current": *"\([^"]*\)".*/\1/p' "$CONF" 2>/dev/null; }

case "$1" in
    enable)
        if ! ls "$KBROOT"/he/*.keymap.gz >/dev/null 2>&1; then
            say "ERROR: he keymap missing"
            stamp "enable FAILED: kbroot/he missing"; exit 1
        fi
        [ -d "$TARGET/he" ] || mount --bind "$KBROOT" "$TARGET"
        set_lang he
        restart_kb
        say "Hebrew ENABLED. Globe=he/en"
        stamp "enabled"
        ;;
    disable)
        set_lang en_US
        restart_kb
        say "English active. Globe=he/en"
        stamp "disabled (current=en_US)"
        ;;
    status)
        cur=$(current_lang)
        if [ "$cur" = "he" ]; then
            say "Active: Hebrew"
        else
            say "Active: $cur"
        fi
        ;;
    *)
        echo "usage: hebkb.sh {enable|disable|status}"
        ;;
esac
