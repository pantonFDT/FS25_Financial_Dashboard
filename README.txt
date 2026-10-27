FINANCIAL DASHBOARD 2.0.0.0
Author: Panton (Factory Development Team)
Game: Farming Simulator 25 | PC single-player

OVERVIEW
A financial analytics page in the FS25 ESC menu with a clean futuristic graph and estimated balance movement tracking. The dashboard automatically begins tracking after the farm loads and saves financial history to financialDashboard.xml inside the active savegame.

FEATURES
- Persistent history across save/reload; independent history per savegame
- 7-, 30-, and 60-day views
- Balance, estimated inflow, and estimated outflow graph modes
- Live current balance, net change, detected movement count, estimated inflows/outflows
- Today vs previous day net changes and largest detected increase/decrease
- Zero-centered change visualization with refined cyan/pink trend lines and grid
- Thin, muted inflow/outflow indicators
- Bounded history samples (up to 500), with rolling retention of daily aggregates
- Financial changes originating from other mods can be observed when they affect farm balance

HOW TO USE
Install FS25_FinancialDashboard.zip in your FS25 mods folder. Enable the mod on a single-player save, load the farm, then open Financial Dashboard in the ESC menu. Choose a metric and a 7/30/60-day view. Save your game normally to persist the history.

IMPORTANT LIMITATIONS
Transactions are inferred from sampled balance changes, not classified by source. Multiple transactions between samples may be combined or cancel out. The dashboard cannot reconstruct financial activity before installation/tracking. Available history is limited to collected days and bounded sample storage. No multiplayer support.

RELEASE NOTES
Version 2.0.0.0 packages the tested graph-only polish design and persistence improvements. As always, back up important saves and the previous mod ZIP before updating. No GIANTS ModHub approval is implied.
