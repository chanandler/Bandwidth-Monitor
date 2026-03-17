# Features, Requests & Ideas

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

**2. ~~Daily/weekly usage breakdown~~** ✅ Completed in v3.2  
~~The app stores 35 days of history but only surfaces "all-time since reset" and "current cycle" totals. A simple bar chart showing usage per day for the last 7 or 30 days would make that stored data actually useful.~~

**3. ~~Menubar icon alternative~~** ✅ Completed in v3.2  
~~An option to show a small graph icon (mini sparkline) in the menu bar instead of text — useful for people who want to save space but still see activity at a glance.~~

**4. ~~Network interface auto-naming improvement~~** ✅ Completed in v3.0  
~~Currently `en0` might show as "Ethernet (en0)" even if it's actually Wi-Fi. The CoreWLAN lookup handles one interface but if the Wi-Fi BSD name doesn't match, the label is wrong. Using `SCNetworkConfiguration` to get real interface display names would be more accurate.~~

---

### Medium Value

**5. ~~Export usage data~~** ✅ Completed in v3.2  
~~A button to export history as CSV (date, download bytes, upload bytes) — useful for people tracking their ISP billing or doing their own analysis.~~

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

**15. ~~Historical peak reset~~** ✅ Completed in v3.2  
~~The peak rates (shown in Statistics) currently only reset when the user manually resets all totals. A separate "Reset Peaks" button, or auto-reset on a schedule (e.g. daily), would make the peak display more meaningful.~~

**16. Pause monitoring**  
A menu item to temporarily pause polling — useful when on a metered connection or in a meeting where every background process counts. Could show "⏸" in the menu bar while paused.  
- Explanation: This helps users conserve bandwidth and reduces distractions by temporarily halting data monitoring during important times.

**17. iCloud sync for preferences**  
Sync settings (data cap, billing day, sampling interval, theme) across multiple Macs via `NSUbiquitousKeyValueStore`. Useful for people who switch between a MacBook and a desktop.  
- Explanation: Enables seamless experience across devices by keeping user preferences consistent and up-to-date automatically.

**18. ~~Richer menu bar tooltip~~** ✅ Completed in v3.1  
~~Expand the existing tooltip (currently just "Download: X / Upload: Y") into a richer summary — today's usage, current cycle total, and percentage of cap used — so users get key stats without opening Statistics at all.~~

**19. Consecutive high-speed alert**  
Notify the user if download or upload stays above a user-defined threshold for a sustained period (e.g. "Upload has been above 50 Mbps for 5 minutes"). Useful for catching runaway background uploads or unexpected downloads. The monitor already tracks a rolling sample window, so the detection logic would be straightforward.  
- Explanation: Alerts users to prolonged high bandwidth use, helping identify unexpected or unwanted network activity early.

**20. App-level bandwidth breakdown (future)**  
Show which apps are consuming the most bandwidth. This requires a network extension or system extension with elevated permissions, which is a significantly larger feature, but would be a major differentiator.  
- Explanation: Provides detailed insight into app-specific data use, empowering users to manage and troubleshoot network consumption effectively.

**21. Data cap colour indicator in menu bar**  
When data cap tracking is enabled, tint the download arrow (↓) with a warning colour (amber → red) as the user approaches their monthly cap — a passive at-a-glance indicator without needing a notification.  
- Explanation: Offers an immediate visual cue that usage is nearing limits, helping users avoid unexpected overages without intrusive alerts.

**22. ~~Onboarding / first-launch walkthrough~~** ✅ Completed in v3.0  
~~New users may not know they need to grant notification permission or configure their data cap. A simple one-time modal on first launch guiding them through the key settings would reduce confusion.~~

**23. ~~Daily/weekly bar chart in Statistics~~** ✅ Completed in v3.2  
~~The app stores 35 days of history but the Statistics view only shows a 5-minute sparkline and lifetime/cycle totals. A bar chart (toggle between 7-day and 30-day view) grouped by day would surface all that stored data. Swift Charts is already used for the sparkline, so the foundation is there.~~

**24. ~~Export usage data as CSV~~** ✅ Completed in v3.2  
~~A button in Statistics to export the 35-day history as a CSV file (date, download bytes, upload bytes). Useful for tracking ISP billing or external analysis. All the data is already persisted — it just needs writing out via an `NSSavePanel`.~~

**25. Per-interface breakdown in Statistics**  
The monitor already calls `getPerInterfaceBytes()` internally but aggregates everything to a single total for display. Surfacing a Wi-Fi vs Ethernet (vs other) split in the Statistics view would be useful on machines with multiple active connections.  
- Explanation: Allows users to see how different network interfaces contribute to total usage, aiding troubleshooting and optimization.

**26. Adjustable smoothing window in Settings**  
`smoothWindow` is hardcoded at 5 samples. Exposing this as a slider in Settings (1 = raw, 5 = default, 10 = very smooth) would let users tune display responsiveness vs. stability.  
- Explanation: Gives users control over how sensitive or stable the usage data appears, improving personalization based on preference or network conditions.

**27. ~~Notification Center / desktop widget~~** ✅ Completed in v3.1  
~~A WidgetKit widget (small and medium sizes) showing last 24 h download/upload totals, current billing cycle usage, data cap progress bar, and peak speeds. Data is written to a shared App Group store by the main app every ~60 seconds and the widget refreshes every 15 minutes or whenever the main app triggers a reload.~~

**28. ~~Subtle tip jar nudge~~** ✅ Completed in v3.2  
~~A gentle, non-intrusive reminder that encourages users to support the app via the Tip Jar. Should appear in a few places:~~  
~~- A small "enjoying the app? Buy me a coffee ☕" line with a clickable link in the Statistics view~~  
~~- A soft prompt in the About window beneath the version number~~  
~~- An occasional (e.g. once every 30 days) banner notification — only shown to users who have never tipped, and never shown more than 3 times total so it never becomes annoying~~

---

### Fresh Feature Ideas (2026)

**29. Automatic Network Type Detection & Profile Switching**  
Automatically detect when the user switches between Wi-Fi, Ethernet, VPN, or mobile hotspot, and change monitoring profiles or alert thresholds accordingly. E.g., stricter data cap alerts when on mobile hotspot.  
- Explanation: This ensures users always have optimal alerts and settings tuned to their current connection, reducing surprises and making the app smarter for mobile or shared environments.

**30. Interactive Usage Heatmap**  
Show an interactive grid or calendar heatmap visualizing hourly usage patterns across days/weeks. Helps users spot peak hours and plan around heavy usage times.  
- Explanation: Provides a visual overview of usage patterns, making it easier to identify trends and optimize network habits.

**31. Real-Time Notification of Unusual Activity**  
Monitor for sudden spikes or drops in bandwidth outside the user's normal pattern and alert with a notification or banner ("Unusual upload detected at 3:14 PM").  
- Explanation: Helps detect anomalies that might indicate problems or unauthorized activity, improving security and awareness.

**32. Quick Actions in Menu Bar**  
Add right-click or long-press quick actions in the menu bar item for pausing monitoring, resetting peaks, or exporting data without opening the main app window.  
- Explanation: Enhances usability by providing fast access to common controls directly from the menu bar.

**33. Siri Shortcut & App Intents Support**  
Expose actions like 'Show current usage', 'Export history', or 'Pause monitoring' as App Intents and Siri Shortcuts for hands-free or automation integration.  
- Explanation: Enables voice control and automation, making the app more accessible and convenient to use.

**34. Advanced Filtering and Custom Alerts**  
Let users define custom alert rules (e.g. notify if usage > X GB between 6–10 PM, or if upload exceeds Y MB in 10 min). Supports power-user workflows.  
- Explanation: Provides flexibility for tailored notifications that fit unique user needs and schedules.

**35. Network Quality Score**  
Calculate and display a 'quality score' based on bandwidth, jitter, and outage frequency to help users identify unreliable connections over time.  
- Explanation: Gives users a simple metric to evaluate their network's reliability and troubleshoot issues proactively.

**36. Bandwidth Forecasting**  
Predict end-of-cycle usage based on recent trends and alert if the user is on track to exceed their data cap, with suggestions for lowering usage.  
- Explanation: Helps users plan their usage proactively and avoid unexpected overages by anticipating future consumption.

**37. One-Tap Troubleshooting Report**  
Allow users to generate a diagnostic report (recent rates, network changes, errors) for sharing with support or troubleshooting their connection.  
- Explanation: Simplifies problem reporting and support by quickly compiling relevant network info into a shareable format.

**38. Accessibility Optimizations**  
Add VoiceOver navigation, larger text support, and high-contrast theme options to make the app more usable for everyone.  
- Explanation: Ensures the app is inclusive and usable by people with a range of accessibility needs.

**39. Bandwidth Usage Widgets for visionOS**  
Provide 3D/spatial widgets for visionOS, enabling users to see floating usage graphs or data caps in their environment.  
- Explanation: Extends monitoring into spatial computing spaces, offering innovative and immersive ways to visualize data.

**40. Liquid Glass Menu Bar Design**  
Adopt Apple's Liquid Glass design for the menu bar and main windows, creating a modern, fluid look that adapts to backgrounds and light.  
- Explanation: Modernizes the app’s UI with a sleek, context-aware visual style that enhances aesthetics and user experience.

**41. Visual Intelligence Integration**  
Let users scan their networking environment or hardware setup via camera and match it to troubleshooting tips or usage analytics.  
- Explanation: Uses visual input to simplify setup and diagnostics, making troubleshooting more intuitive and accessible.

**42. Scheduled Quiet Hours**  
Allow users to define time windows when notifications and usage alerts are suppressed—ideal for meetings, sleep, or focus time.  
- Explanation: Respects user downtime by silencing alerts during specified periods, reducing distractions.

**43. Family/Shared Network Usage Tracking**  
Support for syncing and aggregating data usage across multiple Macs (and possibly iOS devices) for a shared home or office connection.  
- Explanation: Helps households or teams monitor collective usage, improving transparency and management of shared bandwidth.

**44. Detailed ISP Outage Reporting**  
Automatically detect and log network outages, attempt root-cause analysis, and present a timeline for the user to share with their ISP.  
- Explanation: Provides actionable insights into connectivity issues to streamline support interactions and resolution.

**45. App Privacy Insights**  
Summarize privacy risks by tracking which apps/services send or receive data with non-local servers.  
- Explanation: Increases user awareness about data flows, enhancing privacy and security understanding.

**46. Power/Energy Impact Monitoring**  
Estimate and display the energy impact of heavy network activity on battery life and thermal load.  
- Explanation: Helps users balance performance with battery health by showing network activity’s power cost.

**47. System Dashboard Widget**  
Add a system Dashboard widget (if macOS version supports it) with customizable stats for quick at-a-glance usage checks.  
- Explanation: Offers handy, always-visible summaries of bandwidth use without opening the app.

**48. Proactive ISP Plan Recommendations**  
Analyze the user's long-term usage and suggest ISP plans that match their needs more closely, including cost and speed comparisons.  
- Explanation: Helps users optimize their internet service choices by matching plans to actual usage patterns and budgets.
