# Bug Fixes and Completed Work

## Fixes

## Completed

**R1. ~~Sampling interval picker and text input~~** ✅ Completed in v3.0  
~~Allow users to type a value directly and replace the stepper with a picker showing 0.25 s – 30 s in 0.25 s intervals.~~

**R2. ~~Data cap size picker and text input~~** ✅ Completed in v3.0  
~~Remove the stepper and replace with a dropdown picker (1 GB – 1 TB in 1 GB steps) plus a text field for direct typed input.~~

**R3. ~~Test notification button in Settings~~** ✅ Completed in v3.0  
~~A button in the Data Cap section that fires a test notification so users can confirm notifications are working before relying on cap alerts.~~

**1. ~~Notifications for data cap thresholds~~** ✅ Completed in v3.0  
~~Alert the user at 75%, 90%, and 100% of their monthly cap. Right now the cap tracking is there but completely silent — you'd only notice if you opened Statistics.~~

**2. ~~Daily/weekly usage breakdown~~** ✅ Completed in v3.2  
~~The app stores 35 days of history but only surfaces "all-time since reset" and "current cycle" totals. A simple bar chart showing usage per day for the last 7 or 30 days would make that stored data actually useful.~~

**3. ~~Menubar icon alternative~~** ✅ Completed in v3.2  
~~An option to show a small graph icon (mini sparkline) in the menu bar instead of text — useful for people who want to save space but still see activity at a glance.~~

**4. ~~Network interface auto-naming improvement~~** ✅ Completed in v3.0  
~~Currently `en0` might show as "Ethernet (en0)" even if it's actually Wi-Fi. The CoreWLAN lookup handles one interface but if the Wi-Fi BSD name doesn't match, the label is wrong. Using `SCNetworkConfiguration` to get real interface display names would be more accurate.~~

**5. ~~Export usage data~~** ✅ Completed in v3.2  
~~A button to export history as CSV (date, download bytes, upload bytes) — useful for people tracking their ISP billing or doing their own analysis.~~

**8. ~~Dark mode support~~** ✅ Completed in v3.1  
~~The translucent theme uses `.vibrantLight` hardcoded everywhere. Adding `.vibrantDark` / auto following system appearance would make it feel native.~~

**9. ~~Billing cycle day support up to 31~~** ✅ Completed in v3.0  
~~Currently capped at 28. Most ISP billing cycles start on the 1st but some use the 29th–31st. Using `Calendar` to clamp to the last valid day of any given month would handle this correctly.~~

**11. ~~"Speed test" shortcut~~** ✅ Completed in v3.0  
~~A menu item that opens Fast.com or Speedtest.net directly — small but handy when you notice rates look low.~~

**12. ~~Localisation~~** ✅ Completed in v3.0  
~~The app is English-only. Adding at least one or two major languages (e.g. French, German) would widen the App Store audience.~~

**15. ~~Historical peak reset~~** ✅ Completed in v3.2  
~~The peak rates (shown in Statistics) currently only reset when the user manually resets all totals. A separate "Reset Peaks" button, or auto-reset on a schedule (e.g. daily), would make the peak display more meaningful.~~

**18. ~~Richer menu bar tooltip~~** ✅ Completed in v3.1  
~~Expand the existing tooltip (currently just "Download: X / Upload: Y") into a richer summary — today's usage, current cycle total, and percentage of cap used — so users get key stats without opening Statistics at all.~~

**22. ~~Onboarding / first-launch walkthrough~~** ✅ Completed in v3.0  
~~New users may not know they need to grant notification permission or configure their data cap. A simple one-time modal on first launch guiding them through the key settings would reduce confusion.~~

**23. ~~Daily/weekly bar chart in Statistics~~** ✅ Completed in v3.2  
~~The app stores 35 days of history but the Statistics view only shows a 5-minute sparkline and lifetime/cycle totals. A bar chart (toggle between 7-day and 30-day view) grouped by day would surface all that stored data. Swift Charts is already used for the sparkline, so the foundation is there.~~

**24. ~~Export usage data as CSV~~** ✅ Completed in v3.2  
~~A button in Statistics to export the 35-day history as a CSV file (date, download bytes, upload bytes). Useful for tracking ISP billing or external analysis. All the data is already persisted — it just needs writing out via an `NSSavePanel`.~~

**27. ~~Notification Center / desktop widget~~** ✅ Completed in v3.1  
~~A WidgetKit widget (small and medium sizes) showing last 24 h download/upload totals, current billing cycle usage, data cap progress bar, and peak speeds. Data is written to a shared App Group store by the main app every ~60 seconds and the widget refreshes every 15 minutes or whenever the main app triggers a reload.~~

**28. ~~Subtle tip jar nudge~~** ✅ Completed in v3.2  
~~A gentle, non-intrusive reminder that encourages users to support the app via the Tip Jar. Should appear in a few places:~~  
~~- A small "enjoying the app? Buy me a coffee ☕" line with a clickable link in the Statistics view~~  
~~- A soft prompt in the About window beneath the version number~~  
~~- An occasional (e.g. once every 30 days) banner notification — only shown to users who have never tipped, and never shown more than 3 times total so it never becomes annoying~~

