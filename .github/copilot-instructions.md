# Ratwood Development Guide

## Project Overview

Ratwood is a medieval fantasy roleplay game built on BYOND (DreamMaker/DM language), forked from tgstation. It features anthro-allowed medieval roleplay with custom systems for skills, triumphs, patrons, and complex social/economic gameplay.

**Core Technologies:**
- BYOND/DreamMaker (.dm files)
- TypeScript/React (tgui/ directory for UI)
- SQLite databases for persistence
- Node.js tooling for builds

## Architecture

### Modular Structure
Code is split between `code/` (base) and multiple `modular_*` directories:
- `modular_azurepeak/` - Azure Peak map/features
- `modular_helmsguard/` - Helmsguard content
- `modular_hearthstone/` - Hearthstone additions
- `modular_causticcove/` - Caustic Cove content
- `modular_stonehedge/` - Stonehedge features
- `modular_twilight_axis/` - Twilight Axis content

**Pattern:** Modular directories mirror `code/` structure. Use modular folders for map-specific or experimental features to avoid merge conflicts.

### Component System (DCS)
Uses signal-based Datum Component System instead of deep inheritance:
- Add behaviors via `AddComponent()` or `AddElement()`
- Components: `/datum/component/` - stateful, per-instance
- Elements: `/datum/element/` - stateless, shared across instances
- Register to signals: `RegisterSignal(source, COMSIG_*, PROC_REF(handler))`
- Handler procs must have `SIGNAL_HANDLER` macro

**Example:**
```dm
/datum/component/item_equipped_movement_rustle/Initialize()
    RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equip))
    
/datum/component/item_equipped_movement_rustle/proc/on_equip(datum/source, mob/equipper)
    SIGNAL_HANDLER
    RegisterSignal(equipper, COMSIG_MOVABLE_MOVED, PROC_REF(try_step))
```

### Key Systems

**Skills:** `/datum/skill/` - level-based progression (see `code/datums/skills/`)
- Levels: 0-6 (Novice → Legendary)
- Dream point costs for training
- Trait-based caps via `trait_uncap` list

**Triumphs:** Player progression/currency system
- Earned through gameplay achievements
- Spent on loadout items (`/datum/loadout_item`, `triumph_cost` var)
- Stored in database, tracked per-client

**Patrons/Gods:** `/datum/patron/` - deity system affecting gameplay

**Subsystems:** `/datum/controller/subsystem/` - tick-based game loops
- Check `code/controllers/subsystem/` for existing subsystems
- Common: SSatmos, SSprocessing, SSmobs, SSroguetown

## Development Workflows

### Implementation Requirements

**CRITICAL: Always search DreamMaker documentation before coding**
- When implementing ANY feature, bug fix, or code change, FIRST use `mcp_search_docs_search_docs` to search DreamMaker/BYOND documentation
- Search for relevant functions, procs, datums, or systems you plan to use
- This prevents common mistakes and ensures idiomatic BYOND code
- Only proceed with implementation after reviewing the documentation

### Building
Use VS Code tasks (Ctrl+Shift+B) or command line:
```bash
# Standard build
.\tools\build\build.bat

# Local testing (faster map load)
.\tools\build\build.bat -DLOCALTEST

# Without dungeon generation
.\tools\build\build.bat -DLOCALTEST -DNO_DUNGEON

# Low memory mode
.\tools\build\build.bat -DLOWMEMORYMODE
```

### Compile Flags (code/_compile_options.dm)
- `TESTING` - Enable debug messages with `testing("message")`
- `TESTSERVER` - In-game debug tools
- `MATURESERVER` - Content restrictions
- `NO_DUNGEON` - Disable dungeon generation
- `NPC_THINK_DEBUG` - Show NPC AI thoughts above heads

### TGUI Development
Frontend UI lives in `tgui/`:
```bash
# Development with hot reload
.\bin\tgui-dev.cmd

# Production build
.\bin\tgui-build.cmd
```

React-based components in `tgui/packages/tgui/interfaces/`. Backend communication via `ui_act()` and `ui_data()` procs.

## Code Patterns

### Path Conventions
- `/datum/` - Data structures, no physical presence
- `/atom/` - Physical objects in world
- `/obj/` - Items, machinery, structures
- `/mob/` - Living creatures, players, NPCs
- `/turf/` - Floor/wall tiles
- `/area/` - Named regions, often prefixed: `/area/rogue/indoors/`, `/area/rogue/outdoors/`

### Common Includes
Files are included via `.dme`:
- `code/__DEFINES/` - Macros, constants
- `code/__HELPERS/` - Global helper procs
- `code/_globalvars/` - Global lists/vars

### Database Usage
SQLite via `/database` datum:
```dm
var/database/db = new("mydb.db")
var/database/query/q = new("SELECT * FROM table WHERE key=?", value)
if(q.Execute(db))
    while(q.NextRow())
        var/list/row = q.GetRowData()
```

**Data stored:** Player saves (`data/player_saves/`), triumph leaderboards, admin logs

## Testing & Debugging

**In-game:**
- `TESTSERVER` flag enables transformation editing
- Admin verb panel for spawning/testing
- `testing("debug")` for conditional debug output

**Logs:** `data/logs/` - Check runtime errors here first

**Map Testing:** Use `FORCE_MAP` define for rapid testing:
```dm
#define FORCE_MAP "_maps/roguetest.json"
```

## Contributing Standards

From CONTRIBUTING.md:
1. **Include test evidence** in PRs (screenshots/videos)
2. **Never comment out code** - delete it completely
3. **No slurs** in code or comments
4. **Explain "why"** in PR description
5. **Map PRs require Maptainer approval**

## Common Gotchas

- **Indentation matters in DM:** Use tabs, not spaces
- **Signal handlers must be marked:** Use `SIGNAL_HANDLER` macro
- **Modular overrides:** Check if type already exists in modular folders before editing base code
- **Icon states:** Defined in `.dmi` files, referenced by string in `icon_state` var
- **Loadout items:** Set `donoritem = TRUE` if using `ckeywhitelist`
- **Database requirements:** Comment `ADMIN_LEGACY_SYSTEM` in config/config.txt to use SQL admins

## Key Files Reference

- `roguetown.dme` - Main project file, includes all code
- `code/_compile_options.dm` - Build flags
- `code/rt.dm` - Roguetown-specific defines
- `config/config.txt` - Server configuration
- `code/world.dm` - World initialization
- `_maps/*.json` - Map files (use JSON format)
