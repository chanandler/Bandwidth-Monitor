# Features & Requests

## Planned Features

## Requested Features

## Ideas / Backlog

### High Value

**1. Notifications for data cap thresholds**
Alert the user at 75%, 90%, and 100% of their monthly cap. Right now the cap tracking is there but completely silent — you'd only notice if you opened Statistics.

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

**9. Billing cycle day support up to 31**
Currently capped at 28. Most ISP billing cycles start on the 1st but some use the 29th–31st. Using `Calendar` to clamp to the last valid day of any given month would handle this correctly.

---

### Nice to Have

**10. Keyboard shortcut to open Statistics**
A global hotkey (configurable) to pop open the Statistics panel without clicking the menu bar.

**11. "Speed test" shortcut**
A menu item that opens Fast.com or Speedtest.net directly — small but handy when you notice rates look low.

**12. Localisation**
The app is English-only. Adding at least one or two major languages (e.g. French, German) would widen the App Store audience.

---

## Completed
- v2.0 — Menu bar bandwidth monitor with upload/download display
- v3.0 — Code quality improvements (lazy historyURL, removed dead code, @ViewBuilder refactor, relaunch fix, removed legacy availability guards)
- v3.0 — Network interface auto-naming now uses `SCNetworkInterfaceCopyAll()` for accurate, locale-aware labels (e.g. correctly identifies Wi-Fi vs Ethernet vs Thunderbolt Bridge)
