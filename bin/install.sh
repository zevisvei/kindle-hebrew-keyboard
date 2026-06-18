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
AWK="$DATA/make_he.awk"
SRC=/usr/share/keyboard
DST=/var/local/kbroot
CONF=/var/local/system/keyboard.conf
PREF=/var/local/java/prefs/Keyboard.preferences
LOG="$EXT/hebkb.log"

stamp() { echo "$(date '+%Y-%m-%d %H:%M:%S') install: $*" >> "$LOG"; }
# Messages print at the BOTTOM of the screen (like other KUAL extensions), no
# full-screen clear. Row count derived from yres (~24 px/row). $1 (old row arg)
# is ignored; lines stack from the bottom.
_yres() { eips -i 2>/dev/null | sed -n 's/.*[^_]yres:[^0-9]*\([0-9][0-9]*\).*/\1/p' | head -1; }
YR=$(_yres); [ -n "$YR" ] || YR=800
BR=$(( YR / 24 - 5 )); [ "$BR" -gt 0 ] || BR=24
LN=0
say()   { eips 1 $((BR+LN)) "$(printf '%-34.34s' "  $2")"; LN=$((LN+1)); }

say 0 "Installing Hebrew keyboard..."

# 1. rootfs rw (for the /etc job)
mount -o remount,rw / 2>/dev/null

# 2. writable copy of THIS device's keyboard tree
if [ ! -d "$DST" ]; then
    cp -a "$SRC" "$DST" || { say 10 "ERROR: copy keyboard tree failed"; stamp "FAIL: cp tree"; exit 1; }
    stamp "copied $SRC -> $DST"
fi

# 3. build he/ : predictor libs from en_US + Hebrew keymaps (typing-only, no kdb/ldb)
mkdir -p "$DST/he"
cp -a "$DST"/en_US/libpredictor.so* "$DST/he/" 2>/dev/null
cp -a "$DST"/en_US/utils.so*        "$DST/he/" 2>/dev/null
cp -a "$DST"/en_US/pkgconfig        "$DST/he/" 2>/dev/null

# 3a. PREFERRED (universal): generate the Hebrew keymap on-device from THIS
#     device's OWN en_US keymap(s) -- correct geometry for ANY screen res.
made=0
if [ -f "$AWK" ] && command -v awk >/dev/null 2>&1; then
    for f in "$DST"/en_US/en_US-*.keymap.gz; do
        [ -f "$f" ] || continue
        r=$(echo "$f" | sed 's/.*en_US-\(.*\)\.keymap\.gz/\1/')
        if gunzip -c "$f" > "/tmp/en_US-$r.keymap" 2>/dev/null \
           && awk -f "$AWK" "/tmp/en_US-$r.keymap" "/tmp/en_US-$r.keymap" > "/tmp/he-$r.keymap" 2>/dev/null \
           && [ -s "/tmp/he-$r.keymap" ]; then
            gzip -c "/tmp/he-$r.keymap" > "$DST/he/he-$r.keymap.gz" && made=1
            stamp "generated he-$r from device en_US"
        fi
        rm -f "/tmp/en_US-$r.keymap" "/tmp/he-$r.keymap"
    done
fi

# 3b. FALLBACK: bundled keymaps matching the device's en_US resolution(s).
if [ "$made" = 0 ]; then
    stamp "on-device gen unavailable; trying bundled keymaps"
    for f in "$DST"/en_US/en_US-*.keymap.gz; do
        [ -f "$f" ] || continue
        r=$(echo "$f" | sed 's/.*en_US-\(.*\)\.keymap\.gz/\1/')
        if [ -f "$DATA/he-$r.keymap.gz" ]; then
            cp -f "$DATA/he-$r.keymap.gz" "$DST/he/he-$r.keymap.gz"; made=1
            stamp "bundled he-$r matched device"
        fi
    done
fi

# 3c. LAST RESORT: copy every bundled keymap (unknown-res device).
if [ "$made" = 0 ]; then
    if ls "$DATA"/he-*.keymap.gz >/dev/null 2>&1; then
        say 10 "WARN: no res match; copying all keymaps"
        cp -f "$DATA"/he-*.keymap.gz "$DST/he/"
        stamp "WARN: copied all bundled keymaps (no res match)"
    else
        say 10 "ERROR: cannot build any he keymap"; stamp "FAIL: no keymap source"; exit 1
    fi
fi
stamp "built $DST/he"

# 4. remove stock Arabic from the overlay (cosmetic: avoids a duplicate entry)
rm -rf "$DST/ar"

# 5. install boot job
cp -f "$DATA/hebkb.conf" /etc/upstart/hebkb.conf 2>/dev/null && stamp "installed /etc/upstart/hebkb.conf" \
    || stamp "WARN: could not write /etc/upstart (rootfs RO?)"

# 6. mount now + enable Hebrew. selected = he:en_US so the on-screen globe key
#    switches he<->en; current = he (Hebrew active on open).
[ -d "$SRC/he" ] || mount --bind "$DST" "$SRC"
sed -i 's/"current": *"[^"]*"/"current": "he"/; s/"selected": *"[^"]*"/"selected": "he:en_US"/' "$CONF" 2>/dev/null
if grep -q '^keyboard=' "$PREF" 2>/dev/null; then
    sed -i 's/^keyboard=.*/keyboard=he/' "$PREF"
else
    echo 'keyboard=he' >> "$PREF"
fi
restart kb >/dev/null 2>&1 || { stop kb >/dev/null 2>&1; start kb >/dev/null 2>&1; }
stamp "enabled + kb restarted"

say 0 "Installed. Open search to type."
say 0 "Globe=he/en, or use KUAL menu."
