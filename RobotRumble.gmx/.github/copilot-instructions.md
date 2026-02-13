# Robot Rumble - AI Agent Guidelines

## Project Overview
Turn-based tactical RPG built in GameMaker Studio 1.x (GMX format). Players manage a hero roster, deploy them on procedurally-generated missions, and level up through XP rewards.

## Code Style

**Language:** GML (GameMaker Language)

**Naming Conventions:**
- Objects: `camelCase` (`heroData`, `missionSelectButton`, `objFightBar`)
- Prefixes: `obj_` for managers, `var` for instances, `array` for arrays, `int` for integers
- Global variables: `globalvar variableName;` declaration then assignment
- Scripts: lowercase or camelCase (`.gml` files in `scripts/`)

**Key GML Patterns:**
```gml
// Arrays are 1-INDEXED, not 0-indexed
for (i = 1; i < array_length_1d(arrayName); i += 1)

// Instance creation with property assignment
varHero = instance_create(xPos, yPos, hero);
varHero.sprite_index = Hackbot;
varHero.intLevel = 5;

// No parentheses for zero-argument scripts
loadGlobalVariables();

// With statements for batch operations
with(hero) { image_alpha = 0.25; }
```

## Architecture

**Data-Driven Design:**
- `buttonMenu` object (referenced as `mainData`) is the persistent global data hub
- All game state stored in `mainData.arrayHeroes[1-5]` and `mainData.arrayMissions[1-9]`
- Data objects (`heroData`, `missionData`) hold stats; visual objects reference them

**Room Flow:**
`initializer` → `room1` → `homeBase` (hero management) → `missionSelect` (3x3 grid) → `playField` (deployment) → `fightRoom` (combat) → back to `homeBase`

**Key Files:**
- [scripts/GameStartUp.gml](scripts/GameStartUp.gml) - Initialization logic
- [objects/buttonMenu.object.gmx](objects/buttonMenu.object.gmx) - Global data manager
- [scripts/loadMissions.gml](scripts/loadMissions.gml) - Procedural mission generation
- [scripts/calculateWinChance.gml](scripts/calculateWinChance.gml) - Core combat math

## GMX File Format

**Objects (.object.gmx):**
- XML structure with embedded GML in `<event>` tags
- Events identified by `eventtype` and `enumb`: Create (0,0), Step (3,0), Mouse (6,4=click)
- Edit GML inside `<event><action><arguments><argument><string>` CDATA sections

**Project File:**
- `RobotRumble.project.gmx` lists all assets with `<path>` references
- Adding new assets requires XML entry AND file creation

## Project Conventions

**Global State Access:**
```gml
// buttonMenu is ALWAYS accessed as mainData
instance_create(0, 0, buttonMenu);
mainData = buttonMenu;

// All persistent data flows through mainData
mainData.arrayHeroes[1] // First hero (1-indexed)
mainData.arrayEnemies[1, 0] // Boss sprite (2D array)
```

**UI Interaction Pattern:**
- Mouse events drive UI (Left Click=6,4 | Mouse Enter=6,11 | Leave=6,10)
- `depth` for z-ordering (negative = front, e.g., `-200` for overlays)
- Panel animations via `goToRoom(justShowPanel, roomName)` then `panelShow()`

**Win Chance System:**
- Base: 16.67% per hero (3 heroes = ~50% total)
- Ability counter: +33.33% bonus
- Level difference multipliers: -3=0×, -2=0.25×, -1=0.5×, 0=1×, +1=1.25×, +2=1.5×

**Array Conventions:**
```gml
// Hero arrays: [1-5] for 5 hero types
// Mission arrays: [1-9] for 3x3 grid
// Enemy arrays: [index, 0=sprite, 1=ability, 2=name]
// ALWAYS start loops at i=1, not i=0
```

## Build and Test

**Platform:** GameMaker Studio 1.4 required (GMX format, not GMS2)
**Target:** `deployTarget = "win"` (Windows) or `"html5"`
**No automated tests:** Manual testing via room navigation

**Known Issues:**
- **Fullscreen white overlay on Windows 11:** GameMaker Studio 1.4 has a rendering bug on Windows 11 that causes a white overlay in fullscreen mode. Game is configured for windowed mode by default as a workaround. Users can manually toggle fullscreen with Alt+Enter if needed.

## Integration Points

**Google Analytics:**
- Extension: `Global Google Analytics.extension.gmx`
- Page views: `SendAnalyticsPageView(url, category, roomName)` on room start
- Events: `SendAnalyticsEvent(category, action, label, value)` for user actions
- Tracking ID: `UA-34623850-3`

**Save System:**
- INI files: `ini_open("savedata.ini")` → read/write → `ini_close()`
- Player ID generated from save or random on first launch
- Heroes and progress autosaved on mission completion

## Common Pitfalls

1. **Never use 0-indexed arrays** - GML arrays start at 1 in this codebase
2. **Don't modify GMX files directly** - Use GameMaker IDE for structural changes
3. **Sprite references are resource names** - `sprite_index = Hackbot` not `"Hackbot"`
4. **Scripts without args need no parens** - `resetActiveHero();` not `resetActiveHero()`
5. **Global scope via mainData** - Don't create duplicate data stores
6. **Room creation code** - Lives in `<code>` tags, runs once on room_start
7. **Fullscreen on Windows 11** - Engine bug causes white overlay; use windowed mode

## Example: Adding a New Hero

1. Create sprite in `sprites/` subfolder
2. Add entry to `mainData.arrayHeroes` in `loadGlobalVariables.gml`
3. Set ability counter in hero initialization
4. Update UI in `homeBase` room to display 6th slot
5. Modify `calculateWinChance.gml` if new mechanics needed
