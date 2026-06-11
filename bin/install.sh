#!/bin/sh
# Self-contained installer for the Hebrew native keyboard overlay.
# Copy this whole extension folder to <kindle>/extensions/ and run from KUAL.
# No SSH needed. Idempotent: safe to run again.
#
# What it does (all reversible -- see uninstall.sh):
#   1. mount / read-write (jailbreak makes / RO again after each boot)
#   2. copy this device's /usr/share/keyboard -> /var/local/kbroot (writable)
#   3. build /var/local/kbroot/he from bundled keymaps + en_US predictor libs
#   4. drop the stock 'ar' from the overlay (avoids a duplicate "Arabic" entry)
#   5. install the boot job /etc/upstart/hebkb.conf
#   6. enable Hebrew (sets it active) and restart kb
#
# Brick risk: none. Only bind-mounts + edits in /var/local + one tiny /etc job.

SELF=$(readlink -f "$0"); BIN=$(dirname "$SELF"); EXT=$(dirname "$BIN")
DATA="$EXT/data"
SRC=/usr/share/keyboard
DST=/var/local/kbroot
CONF=/var/local/system/keyboard.conf
PREF=/var/local/java/prefs/Keyboard.preferences
LOG="$EXT/hebkb.log"

stamp() { echo "$(date '+%Y-%m-%d %H:%M:%S') install: $*" >> "$LOG"; }
say()   { eips 1 "$1" "  $2"; }

eips -c
say 8 "Installing Hebrew keyboard..."

# 0. sanity: bundled keymaps present
if [ ! -f "$DATA/he-600x800.keymap.gz" ]; then
    say 10 "ERROR: data/he-600x800.keymap.gz missing"; stamp "FAIL: no bundled keymap"; exit 1
fi

# 1. rootfs rw (for the /etc job)
mount -o remount,rw / 2>/dev/null

# 2. writable copy of THIS device's keyboard tree
if [ ! -d "$DST" ]; then
    cp -a "$SRC" "$DST" || { say 10 "ERROR: copy keyboard tree failed"; stamp "FAIL: cp tree"; exit 1; }
    stamp "copied $SRC -> $DST"
fi

# 3. build he/ : predictor libs from en_US + bundled keymaps (typing-only, no kdb/ldb)
mkdir -p "$DST/he"
cp -a "$DST"/en_US/libpredictor.so* "$DST/he/" 2>/dev/null
cp -a "$DST"/en_US/utils.so*        "$DST/he/" 2>/dev/null
cp -a "$DST"/en_US/pkgconfig        "$DST/he/" 2>/dev/null
cp -f "$DATA"/he-600x800.keymap.gz "$DST/he/he-600x800.keymap.gz"
cp -f "$DATA"/he-800x600.keymap.gz "$DST/he/he-800x600.keymap.gz"
stamp "built $DST/he"

# 4. remove stock Arabic from the overlay (cosmetic: he shows as "Arabic", avoid dupes)
rm -rf "$DST/ar"

# 5. install boot job
cp -f "$DATA/hebkb.conf" /etc/upstart/hebkb.conf 2>/dev/null && stamp "installed /etc/upstart/hebkb.conf" \
    || stamp "WARN: could not write /etc/upstart (rootfs RO?)"

# 6. mount now + enable Hebrew
[ -d "$SRC/he" ] || mount --bind "$DST" "$SRC"
sed -i 's/"current": *"[^"]*"/"current": "he"/; s/"selected": *"[^"]*"/"selected": "he"/' "$CONF" 2>/dev/null
if grep -q '^keyboard=' "$PREF" 2>/dev/null; then
    sed -i 's/^keyboard=.*/keyboard=he/' "$PREF"
else
    echo 'keyboard=he' >> "$PREF"
fi
restart kb >/dev/null 2>&1 || { stop kb >/dev/null 2>&1; start kb >/dev/null 2>&1; }
stamp "enabled + kb restarted"

eips -c
say 8  "Hebrew keyboard installed."
say 10 "Open search to type Hebrew."
say 12 "Toggle via KUAL menu."
