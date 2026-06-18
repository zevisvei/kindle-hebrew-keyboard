#!/bin/sh
# Fully remove the Hebrew keyboard overlay and restore the stock keyboard.
SELF=$(readlink -f "$0"); BIN=$(dirname "$SELF"); EXT=$(dirname "$BIN")
CONF=/var/local/system/keyboard.conf
PREF=/var/local/java/prefs/Keyboard.preferences
LOG="$EXT/hebkb.log"
stamp() { echo "$(date '+%Y-%m-%d %H:%M:%S') uninstall: $*" >> "$LOG"; }
# Bottom-of-screen messages (no full-screen clear), like other KUAL extensions.
_yres() { eips -i 2>/dev/null | sed -n 's/.*[^_]yres:[^0-9]*\([0-9][0-9]*\).*/\1/p' | head -1; }
YR=$(_yres); [ -n "$YR" ] || YR=800
BR=$(( YR / 24 - 4 )); [ "$BR" -gt 0 ] || BR=24
LN=0
say() { eips 1 $((BR+LN)) "$(printf '%-34.34s' "  $1")"; LN=$((LN+1)); }

say "Removing Hebrew keyboard..."

mount -o remount,rw / 2>/dev/null
# back to English first
sed -i 's/"current": *"[^"]*"/"current": "en_US"/; s/"selected": *"[^"]*"/"selected": "en_US"/' "$CONF" 2>/dev/null
sed -i 's/^keyboard=.*/keyboard=en_US/' "$PREF" 2>/dev/null
# remove boot job
rm -f /etc/upstart/hebkb.conf
# unmount overlay (lazy if busy) and drop the writable copy
umount /usr/share/keyboard 2>/dev/null || umount -l /usr/share/keyboard 2>/dev/null
rm -rf /var/local/kbroot
restart kb >/dev/null 2>&1 || { stop kb >/dev/null 2>&1; start kb >/dev/null 2>&1; }
stamp "removed overlay, job, kbroot; restored en_US"

say "Removed. Stock restored."
say "Reboot clears the mount fully."
