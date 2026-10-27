FINANCIAL DASHBOARD — CHANGELOG
Author: Panton (Factory Development Team)

2.0.0.0 — Persistent History & Futuristic Graph Update
Changes since the 1.0.0.0 production release:

DATA & PERSISTENCE
- Added automatic balance tracking when the farm loads; opening the dashboard is no longer required to start tracking.
- Added per-savegame financialDashboard.xml persistence for history and daily aggregates.
- Added savegame-save integration so financial history is written during normal FS25 saves.
- Added restoration of stored history when loading a savegame.
- Corrected history-loading farm ID fallback so saves can restore even when player.farmId is unavailable.
- Added bounded stored samples (up to 500) and rolling daily history management.

FINANCIAL ANALYTICS
- Added a 7-day history window alongside 30- and 60-day views.
- Added selectable Balance, Inflows and Outflows graph modes.
- Added current-day vs previous-day net movement comparison.
- Preserved live balance, net change, detected movement counts, estimated inflows/outflows, and largest increase/decrease statistics.
- Tracking can detect balance changes caused by compatible external mods, including trainer/cheat money additions; transactions remain estimates, not categorized entries.

VISUALS & USABILITY
- Introduced a futuristic blue financial graph panel with cyan framing and a refined grid.
- Refined trend-line styling, subtle glow/contrast and endpoint highlighting.
- Polished graph gridline weight, border intensity and background treatment.
- Slimmed the inflow/outflow indicator bars and replaced bright colors with muted teal/rose tones.
- Preserved the established ESC-menu statistics layout and graph controls; did not ship the experimental floating-card layout.
- Updated the on-screen footer, metadata and release documentation for 2.0.0.0.
- Preserved the existing sidebar icon assets and menu registration/UV behavior.

LIMITATIONS
- PC single-player only.
- Balance-based polling can combine/cancel transactions and does not identify transaction categories.
- History is limited to data collected after tracking begins and bounded retention.

1.0.0.0 — Initial Production Release
- Dedicated ESC-menu financial dashboard and custom sidebar icon.
- Live balance, net change, estimated inflow/outflow statistics.
- 30/60-day session-only zero-centered graph, up to 500 samples.
- Largest observed increases/decreases; baseline captured when dashboard first opened.
