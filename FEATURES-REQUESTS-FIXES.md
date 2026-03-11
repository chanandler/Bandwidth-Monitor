# Features, Requests & Fixes

## Planned Features

## Requested Features

**R1. ~~Sampling interval picker and text input~~** ✅ Completed in v3.0
~~Allow users to type a value directly and replace the stepper with a picker showing 0.25 s – 30 s in 0.25 s intervals.~~

**R2. ~~Data cap size picker and text input~~** ✅ Completed in v3.0
~~Remove the stepper and replace with a dropdown picker (1 GB – 1 TB in 1 GB steps) plus a text field for direct typed input.~~

**R3. ~~Test notification button in Settings~~** ✅ Completed in v3.0
~~A button in the Data Cap section that fires a test notification so users can confirm notifications are working before relying on cap alerts.~~

## Ideas / Backlog

### High Value

**1. ~~Notifications for data cap thresholds~~** ✅ Completed in v3.0
~~Alert the user at 75%, 90%, and 100% of their monthly cap. Right now the cap tracking is there but completely silent — you'd only notice if you opened Statistics.~~

**2. Daily/weekly usage breakdown**
The app stores 35 days of history but only surfaces "all-time since reset" and "current cycle" totals. A simple bar chart showing usage per day for the last 7 or 30 days would make that stored data actually useful.

**3. Menubar icon alternative**
An option to show a small graph icon (mini sparkline) in the menu bar instead of text — useful for people who want to save space but still see activity at a glance.

**4. ~~Network interface auto-naming improvement~~** ✅ Completed in v3.0
~~Currently `en0` might show as "Ethernet (en0)" even if it's actually Wi-Fi. The CoreWLAN lookup handles one interface but if the Wi-Fi BSD name doesn't match, the label is wrong. Using `SCNetworkConfiguration` to get real interface display names would be more accurate.~~

---

### Medium Value

**5. Export usage data**
A button to export history as CSV (date, download bytes, upload bytes) — useful for people tracking their ISP billing or doing their own analysis.

**6. Adjustable smoothing window in Settings**
`smoothWindow` is hardcoded at 5. Exposing this (e.g. 1 = raw, 5 = smooth, 10 = very smooth) would let users tune responsiveness vs. stability.

**7. Per-interface breakdown in Statistics**
Show download/upload split by interface (Wi-Fi vs Ethernet) rather than just the combined total — useful for people on mixed networks.

**8. Dark mode support**
The translucent theme uses `.vibrantLight` hardcoded everywhere. Adding `.vibrantDark` / auto following system appearance would make it feel native.

**9. ~~Billing cycle day support up to 31~~** ✅ Completed in v3.0
~~Currently capped at 28. Most ISP billing cycles start on the 1st but some use the 29th–31st. Using `Calendar` to clamp to the last valid day of any given month would handle this correctly.~~

---

### Nice to Have

**10. Keyboard shortcut to open Statistics**
A global hotkey (configurable) to pop open the Statistics panel without clicking the menu bar.

**11. "Speed test" shortcut**
A menu item that opens Fast.com or Speedtest.net directly — small but handy when you notice rates look low.

**12. Localisation**
The app is English-only. Adding at least one or two major languages (e.g. French, German) would widen the App Store audience.

---

## Fixes

**F1. ~~Notifications not appearing when app is active~~** ✅ Fixed in v3.0
Test notification button and data cap alerts were silently suppressed when the Settings window was open. macOS suppresses notifications for the active app by default unless a `UNUserNotificationCenterDelegate` is set. Fixed by conforming `AppDelegate` to `UNUserNotificationCenterDelegate` and implementing `willPresent` to return `.banner` + `.sound`, ensuring notifications display even while the app is frontmost.

---

## Completed
- v2.0 — Menu bar bandwidth monitor with upload/download display
- v3.0 — Code quality improvements (lazy historyURL, removed dead code, @ViewBuilder refactor, relaunch fix, removed legacy availability guards)
- v3.0 — Network interface auto-naming now uses `SCNetworkInterfaceCopyAll()` for accurate, locale-aware labels (e.g. correctly identifies Wi-Fi vs Ethernet vs Thunderbolt Bridge)
- v3.0 — Billing day picker extended to 31; `currentCycleStart()` clamps to the last valid day of the month so days 29–31 work correctly in short months
- v3.0 — Data cap notifications: fires a system notification at 75%, 90%, and 100% usage; each threshold fires once per billing cycle and resets automatically when the cycle rolls over or totals are reset
- v3.0 — Settings: sampling interval replaced with dropdown picker (0.25 s – 30 s) + typed text field
- v3.0 — Settings: data cap size replaced with dropdown picker (1 GB – 1 TB) + typed text field
- v3.0 — Settings: test notification button added to Data Cap section
- v3.0 — Fix: notifications now display as banners when app is active (`UNUserNotificationCenterDelegate` + `willPresent`)
