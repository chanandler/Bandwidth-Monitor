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

**8. ~~Dark mode support~~** ✅ Completed in v3.1
~~The translucent theme uses `.vibrantLight` hardcoded everywhere. Adding `.vibrantDark` / auto following system appearance would make it feel native.~~

**9. ~~Billing cycle day support up to 31~~** ✅ Completed in v3.0
~~Currently capped at 28. Most ISP billing cycles start on the 1st but some use the 29th–31st. Using `Calendar` to clamp to the last valid day of any given month would handle this correctly.~~

---

### Nice to Have

**10. Keyboard shortcut to open Statistics**
A global hotkey (configurable) to pop open the Statistics panel without clicking the menu bar.

**11. ~~"Speed test" shortcut~~** ✅ Completed in v3.0
~~A menu item that opens Fast.com or Speedtest.net directly — small but handy when you notice rates look low.~~

**12. ~~Localisation~~** ✅ Completed in v3.0
~~The app is English-only. Adding at least one or two major languages (e.g. French, German) would widen the App Store audience.~~

---

### New Ideas

**13. Configurable notification thresholds**
Currently the 75/90/100% thresholds are hardcoded. Let users set their own — some people might want an early warning at 50%, others only care about 100%.

**14. Menu bar colour coding by speed**
Change the colour of the menu bar text dynamically based on how fast the current speed is relative to the user's peak — green when idle/slow, amber at moderate, red when near peak. Gives instant visual feedback at a glance without needing to read numbers.

**15. Historical peak reset**
The peak rates (shown in Statistics) currently only reset when the user manually resets all totals. A separate "Reset Peaks" button, or auto-reset on a schedule (e.g. daily), would make the peak display more meaningful.

**16. Pause monitoring**
A menu item to temporarily pause polling — useful when on a metered connection or in a meeting where every background process counts. Could show "⏸" in the menu bar while paused.

**17. iCloud sync for preferences**
Sync settings (data cap, billing day, sampling interval, theme) across multiple Macs via `NSUbiquitousKeyValueStore`. Useful for people who switch between a MacBook and a desktop.

**18. ~~Richer menu bar tooltip~~** ✅ Completed in v3.1
~~Expand the existing tooltip (currently just "Download: X / Upload: Y") into a richer summary — today's usage, current cycle total, and percentage of cap used — so users get key stats without opening Statistics at all.~~

**19. Consecutive high-speed alert**
Notify the user if download or upload stays above a user-defined threshold for a sustained period (e.g. "Upload has been above 50 Mbps for 5 minutes"). Useful for catching runaway background uploads or unexpected downloads. The monitor already tracks a rolling sample window, so the detection logic would be straightforward.

**20. App-level bandwidth breakdown (future)**
Show which apps are consuming the most bandwidth. This requires a network extension or system extension with elevated permissions, which is a significantly larger feature, but would be a major differentiator.

**21. Data cap colour indicator in menu bar**
When data cap tracking is enabled, tint the download arrow (↓) with a warning colour (amber → red) as the user approaches their monthly cap — a passive at-a-glance indicator without needing a notification.

**22. ~~Onboarding / first-launch walkthrough~~** ✅ Completed in v3.0
~~New users may not know they need to grant notification permission or configure their data cap. A simple one-time modal on first launch guiding them through the key settings would reduce confusion.~~

**23. Daily/weekly bar chart in Statistics**
The app stores 35 days of history but the Statistics view only shows a 5-minute sparkline and lifetime/cycle totals. A bar chart (toggle between 7-day and 30-day view) grouped by day would surface all that stored data. Swift Charts is already used for the sparkline, so the foundation is there.

**24. Export usage data as CSV**
A button in Statistics to export the 35-day history as a CSV file (date, download bytes, upload bytes). Useful for tracking ISP billing or external analysis. All the data is already persisted — it just needs writing out via an `NSSavePanel`.

**25. Per-interface breakdown in Statistics**
The monitor already calls `getPerInterfaceBytes()` internally but aggregates everything to a single total for display. Surfacing a Wi-Fi vs Ethernet (vs other) split in the Statistics view would be useful on machines with multiple active connections.

**26. Adjustable smoothing window in Settings**
`smoothWindow` is hardcoded at 5 samples. Exposing this as a slider in Settings (1 = raw, 5 = default, 10 = very smooth) would let users tune display responsiveness vs. stability.

**27. ~~Notification Center / desktop widget~~** ✅ Completed in v3.1
~~A WidgetKit widget (small and medium sizes) showing last 24 h download/upload totals, current billing cycle usage, data cap progress bar, and peak speeds. Data is written to a shared App Group store by the main app every ~60 seconds and the widget refreshes every 15 minutes or whenever the main app triggers a reload.~~

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
- v3.0 — Onboarding: 7-step first-launch walkthrough covering language, welcome, theme, units, data cap, notifications, and finish; versioned so major updates can re-trigger it for existing users
- v3.0 — Localisation: full English, French (Français), and German (Deutsch) support via in-app `L` struct; language picker in onboarding step 1 and in Settings; defaults to system locale if supported
- v3.0 — Speed Test shortcut: "Speed Test" submenu in the menu bar with Fast.com and Speedtest.net options; opens in the default browser
- v3.1 — Dark mode: added `.dark` theme option; all windows, popovers, and view backgrounds now correctly apply `.darkAqua` appearance; removed hardcoded `.vibrantLight` from About, Tip Jar, Settings, and Details popover
- v3.1 — Richer menu bar tooltip: hovering the menu bar item now shows last 24 h totals, current cycle totals, data cap % (if enabled), and peak speeds
- v3.1 — Notification Center / desktop widget: WidgetKit extension (small + medium) showing 24 h usage, cycle totals, cap progress bar, and peak speeds; main app writes to shared App Group store every ~60 s and triggers widget reload
