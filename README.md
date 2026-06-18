# Kindle Hebrew Keyboard

A **Hebrew on-screen keyboard for the native (stock) Kindle interface** — search,
notes, collections, anywhere the system keyboard appears. No KOReader required.

Installs as a [KUAL](https://www.mobileread.com/forums/showthread.php?t=203326)
extension. **No SSH, no PC tools** — copy one folder, tap *Install*.

> Built and verified on **Kindle Basic 10g (J9G29R), FW 5.18.1** and **Paperwhite
> 11th gen (2021), FW 5.16.20**, jailbroken with AdBreak. Standard Israeli
> **SI‑1452** layout. Typing‑only (no word prediction).

> ⚠️ **The universal on‑device keymap generation (v10) is NOT fully tested.** The
> `awk` generator's output was verified byte‑for‑byte against known‑good keymaps,
> but the complete fresh‑install flow has not been run end‑to‑end on every device
> or resolution. Treat v10 as experimental.

> **No warranty / no liability.** This software is provided "as is", without
> warranty of any kind. You use it **entirely at your own risk** — the author
> accepts **no responsibility for any damage, data loss, or malfunction** of your
> device. Although the design avoids partition/boot/firmware writes, jailbroken
> devices always carry risk. If unsure, don't install.

---

## Features

- Adds Hebrew to the **stock** keyboard — works in every native text field.
- Right‑to‑left, all 27 letters (22 + 5 finals), Western digits, full symbol/number pages.
- **On‑screen 🌐 globe key switches Hebrew ⇄ English** — both are kept enabled
  (`selected = he:en_US`) so the firmware's language key toggles between them, and
  it **survives reboot**.
- One‑tap **Enable / Disable** toggle from the KUAL menu as well.
- Keeps every other language the device already had.
- **No brick risk** — bind‑mount + a couple of files under `/var/local` and one
  small `/etc/upstart` job. Fully reversible via *Uninstall*.

## Requirements

- A **jailbroken** Kindle with **KUAL** installed.
- A **jailbroken** Kindle with **KUAL** — **any screen resolution**. The installer
  builds the Hebrew keymap *on the device* from the device's own `en_US` keymap
  (correct geometry for any model), so no per‑model keymap is needed. Pre‑built
  keymaps (600×800 / 800×600 / 1072×1448 / 1448×1072) ship as a fallback.

## Install (no SSH)

1. Copy the **`hebrew-keyboard`** folder to `<Kindle USB drive>/extensions/`.
2. Eject. If the menu doesn't appear, reboot once so KUAL picks it up.
3. **KUAL → Hebrew Keyboard → Install / Repair**.
4. Open Search (or any text field) and type Hebrew. With two keyboards enabled,
   tap the 🌐 globe key to switch.

## Daily use

**KUAL → Hebrew Keyboard →**

| Item | Action |
|------|--------|
| **Install / Repair** | First‑time setup (idempotent — safe to re‑run) |
| **Enable Hebrew** | Make Hebrew the active keyboard |
| **Disable (English)** | Switch back to English |
| **Show Status** | Show the active keyboard |
| **Uninstall** | Remove everything, restore the stock keyboard |

Your Enable/Disable choice is stored and re‑applied on every boot.

## How it works

`/usr/share/keyboard` is a **read‑only squashfs**, and the kernel has no overlayfs,
so a new language can't simply be dropped in. The installer instead:

1. Copies the device's own `/usr/share/keyboard` → `/var/local/kbroot` (writable).
2. Builds a `he/` folder there: an `awk` script (`data/make_he.awk`, busybox‑only,
   no Python/Lua) reads the device's own `en_US` keymap and rewrites just its base
   letter layer with the SI‑1452 rows — so the Hebrew layout inherits the exact
   geometry of *this* screen, at any resolution. Predictor libs are copied from
   `en_US`. (If `awk` or `en_US` is somehow unavailable, it falls back to the
   bundled pre‑built keymaps.)
3. **Bind‑mounts** `kbroot` back over `/usr/share/keyboard`.
4. Installs `/etc/upstart/hebkb.conf`, which re‑applies the bind **before the `kb`
   daemon starts** on each boot and honors your choice in `Keyboard.preferences`.

The `kb` daemon then auto‑lists `he` in `keyboard.conf` and loads the Hebrew keymap.

> **Key gotcha** (documented so forks don't trip on it): `/usr/share/keyboard` is
> *always* a mountpoint (the squashfs), so an idempotency guard must test for the
> `he/` directory — **never** `mountpoint -q`, which is always true and silently
> skips the bind on boot.

## Layout (SI‑1452)

```
ק ר א ט ו ן ם פ
ש ד ג כ ע י ח ל ך ף
ז ס ב ה נ מ צ ת ץ            ⌫
```

## Limitations

- **Settings label says "Arabic".** Cosmetic only — it types Hebrew correctly. The
  `kb` daemon has no internal name for `he` and falls back to "Arabic"; fixing the
  label would require patching the `kb` binary.
- **No word prediction** (typing only — no `.ldb` dictionary shipped).
- **Both keyboards show as "English" in the globe cycle.** The firmware labels every
  keyboard with the device's UI language, so the 🌐 cycle shows two "English"
  entries — one types Hebrew, one English. They switch correctly; the labels are
  just ambiguous (cosmetic, would require patching the framework to fix).
- **Layout assumption.** On‑device generation assumes the firmware's base letter
  layer is the standard 3‑row QWERTY (`!!shift` + 7 keys on the bottom row).
  Verified on Basic 10g and Paperwhite 11g; an unusual firmware schema would fall
  back to the bundled keymaps.
- OTA firmware updates may replace `keyboard.sqsh`; re‑run *Install / Repair* after.

## Safety / rollback

No partition, boot, or firmware writes — **bricking is not possible** from this
package. *Uninstall* (or removing `/etc/upstart/hebkb.conf` + a reboot) fully
restores the stock keyboard. If a bad keymap ever made the keyboard unusable,
*Uninstall* works from KUAL without needing the keyboard at all.

## Repo layout

```
hebrew-keyboard/
├─ config.xml          KUAL extension descriptor
├─ menu.json           KUAL menu
├─ VERSION
├─ README.md / README.txt
├─ bin/
│  ├─ install.sh       set up overlay + boot job, enable Hebrew
│  ├─ uninstall.sh     remove everything, restore stock
│  └─ hebkb.sh         enable / disable / status
└─ data/
   ├─ make_he.awk      on-device keymap generator (busybox awk; universal)
   ├─ he-600x800.keymap.gz    fallback — Basic 10g class
   ├─ he-800x600.keymap.gz
   ├─ he-1072x1448.keymap.gz  fallback — Paperwhite 11th gen
   ├─ he-1448x1072.keymap.gz
   └─ hebkb.conf       upstart boot job
```

## Credits

Hebrew keymap derived from the firmware's Arabic (RTL) keymap. Thanks to the
MobileRead and [kindlemodding.org](https://kindlemodding.org) communities for the
jailbreak, KUAL, and keyboard‑layout groundwork.

## License

MIT.
