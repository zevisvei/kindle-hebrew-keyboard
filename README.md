# Kindle Hebrew Keyboard

A **Hebrew on-screen keyboard for the native (stock) Kindle interface** — search,
notes, collections, anywhere the system keyboard appears. No KOReader required.

Installs as a [KUAL](https://www.mobileread.com/forums/showthread.php?t=203326)
extension. **No SSH, no PC tools** — copy one folder, tap *Install*.

> Built and verified on **Kindle Basic 10g (J9G29R), firmware 5.18.1**, jailbroken
> with AdBreak. Standard Israeli **SI‑1452** layout. Typing‑only (no word prediction).

---

## Features

- Adds Hebrew to the **stock** keyboard — works in every native text field.
- Right‑to‑left, all 27 letters (22 + 5 finals), Western digits, full symbol/number pages.
- One‑tap **Enable / Disable** toggle; your choice **survives reboot**.
- Keeps every other language the device already had.
- **No brick risk** — bind‑mount + a couple of files under `/var/local` and one
  small `/etc/upstart` job. Fully reversible via *Uninstall*.

## Requirements

- A **jailbroken** Kindle with **KUAL** installed.
- A **600×800 / 800×600** keyboard device (basic Kindles / Paperwhite‑class).
  Higher‑resolution models need regenerated keymaps — see [Limitations](#limitations).

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
2. Builds a `he/` folder there from the bundled keymaps + the `en_US` predictor libs.
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
- **600×800 / 800×600 only.** Other resolutions need regenerated keymaps.
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
   ├─ he-600x800.keymap.gz
   ├─ he-800x600.keymap.gz
   └─ hebkb.conf       upstart boot job
```

## Credits

Hebrew keymap derived from the firmware's Arabic (RTL) keymap. Thanks to the
MobileRead and [kindlemodding.org](https://kindlemodding.org) communities for the
jailbreak, KUAL, and keyboard‑layout groundwork.

## License

MIT.
