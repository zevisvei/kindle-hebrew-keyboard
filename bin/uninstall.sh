#!/bin/sh
# Fully remove the Hebrew keyboard overlay and restore the stock keyboard.
SELF=$(readlink -f "$0"); BIN=$(dirname "$SELF"); EXT=$(dirname "$BIN")
CONF=/var/local/system/keyboard.conf
PREF=/var/local/java/prefs/Keyboard.preferences
LOG="$EXT/hebkb.log"
stamp() { echo "$(date '+%Y-%m-%d %H:%M:%S') uninstall: $*" >> "$LOG"; }

eips -c; eips 1 8 "  Removing Hebrew keyboard..."

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

eips -c; eips 1 10 "  Hebrew keyboard removed (stock restored)."
eips 1 12 "  A reboot fully clears the overlay mount."
