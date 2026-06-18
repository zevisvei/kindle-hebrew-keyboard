Hebrew Keyboard for the native Kindle UI  (typing-only, SI-1452 layout)
======================================================================

Adds a Hebrew keyboard to the STOCK Kindle interface (search, notes, etc.).
No KOReader. Built and tested on Kindle Basic 10g (J9G29R), FW 5.18.1, AdBreak.

WARNING: v10 universal on-device generation is NOT fully tested (experimental).
NO WARRANTY. Use entirely at your own risk. The author takes NO responsibility
for any damage, data loss, or malfunction of your device.

REQUIREMENTS
------------
- Jailbroken Kindle with KUAL installed.
- ANY screen resolution. The installer builds the Hebrew keymap on the
  device from the device's own en_US keymap (busybox awk, no Python/Lua),
  so it inherits this screen's exact geometry. Pre-built keymaps
  (600x800 / 800x600 / 1072x1448 / 1448x1072) ship only as a fallback.

INSTALL (no SSH needed)
-----------------------
1. Copy this whole "hebrew-keyboard" folder into:  <Kindle USB>/extensions/
2. Eject + (if the menu doesn't show) reboot once so KUAL sees it.
3. KUAL  ->  Hebrew Keyboard  ->  Install / Repair
4. Open Search (or any text field) -> type Hebrew.
   If two keyboards are enabled, tap the globe key to switch.

DAILY USE
---------
KUAL -> Hebrew Keyboard ->
  Enable Hebrew        make Hebrew the active keyboard
  Disable (English)    switch back to English
  Show Status          show the active keyboard
  Uninstall            remove everything, restore the stock keyboard
Your Enable/Disable choice survives reboot.

NOTES
-----
- In Settings > Keyboards the entry is labelled "Arabic" (cosmetic: the kb
  daemon has no internal name for "he"). It still types Hebrew correctly.
- "Install" copies THIS device's own stock keyboards into a writable overlay
  and adds Hebrew, so the other languages keep working. Stock "Arabic" is
  dropped from the overlay to avoid a duplicate "Arabic" entry.
- No word prediction (typing only).
- Brick risk: none. Everything is bind-mounts + files under /var/local plus
  one small /etc/upstart job. Uninstall + reboot fully restores stock.

HOW IT WORKS
------------
/usr/share/keyboard is a read-only squashfs, so the installer copies it to
/var/local/kbroot, adds he/, and bind-mounts it back over /usr/share/keyboard.
/etc/upstart/hebkb.conf re-applies the bind on every boot (before the kb
daemon) and honors your Enable/Disable choice stored in Keyboard.preferences.
