# Financial Dashboard 2.0 — Farming Simulator 25

**Author:** Panton (Factory Development Team)  
**Version:** 2.0.0.0  
**Platform:** PC, single-player only

Financial Dashboard adds a dedicated financial analytics page to the Farming Simulator 25 ESC menu, with persistent financial history, balance movement statistics, and a futuristic graph.

## Features

- Persistent, per-savegame financial history stored in `financialDashboard.xml`.
- Automatic balance tracking after the farm loads, including observable balance changes from other mods.
- Selectable **7 / 30 / 60-day** views and **Balance / Inflows / Outflows** graph modes.
- Daily net movement comparisons, estimated inflows/outflows, detected movement counts, and largest observed changes.
- Refined cyan/pink graph lines, gridlines, and muted inflow/outflow indicators.

## Installation

1. Download `FS25_FinancialDashboard.zip` from the GitHub **Releases** section.
2. Copy the ZIP **without extracting it** into your Farming Simulator 25 `mods` folder.
3. Enable the mod for a single-player savegame.
4. Load your farm and open **Financial Dashboard** from the ESC menu.
5. Save the game normally to preserve history.

**Do not install the GitHub source-code ZIP as a mod.** Use the ZIP attached to the release instead.

## Important limitations

- PC single-player only; multiplayer is not supported.
- Transactions are inferred from sampled balance changes, not classified by source. Multiple changes between samples can combine or cancel out.
- The mod cannot reconstruct transactions from before it was installed.
- Historical storage is bounded, and available history depends on recorded data.
- Back up important savegames before updating.

## Changes in v2.0

See [CHANGELOG.md](CHANGELOG.md) for the complete changes from the original public v1.0 release.

## Copyright and permissions

Copyright © 2026 Panton (Factory Development Team). All rights reserved to the extent permitted by applicable law and third-party licenses.

This is **source-available, not an open-source license**. Public visibility of this repository does not authorize reuploads, redistribution, or modified releases beyond permissions expressly granted in [LICENSE.txt](LICENSE.txt), applicable law, or existing third-party licenses. Hosting and platform terms may grant additional rights to the respective platforms.

This mod is not affiliated with or endorsed by GIANTS Software.
