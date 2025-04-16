# NSMBW TAS Studio
A new way to TAS New Super Mario Bros Wii, based off of [Celeste TAStudio](https://github.com/EverestAPI/CelesteTAS-EverestInterop/tree/a968bc96f958d67ddce3de84175f0e2b0bad1572). Source code for `NSMBW Studio.exe` will be included in a release every time it it updated; it is mostly unchanged from Celeste TAStudio. The main repository is just for the TAS Studio setup.

## Setup
1. Download Dolphin [Lua Core v4.6](https://github.com/MikeXander/Dolphin-Lua-Core/releases/tag/v4.6), and put it into a folder of your liking
2. Download this repository and paste it into your Dolphin directory (the same folder as `Dolphin.exe`).
3. Open Dolphin and set these settings:
- Config
  - General
    - `Dual Core (speedup)`: Disabled
    - `Idle Skipping`: Disabled
  - Interface
    - `Use Panic Handlers`: Disabled
    
- Controller settings
  - DISABLE all GameCube controllers
  - `Wiimote 1`: Emulated Wiimote
    - `Extension`: Nunchuck
    - Note: Hotkey controller binds are not needed for TASing with Studio. But if you do map hotkeys for controller input, use only `Shake Z` for your spin input key.

- Hotkeys
  - MGR's recommened hotkeys are saved as a profile called `TAS Studio`. If you decide to use your own, make sure you have hotkeys for Save/Load States, Frame Advance, and Toggle Pause.
    - Note: If you use your own hotkeys, Studio may accept them as input, meaning they could change the TAS file or use up undos. These keys are not accepted as input by Studio by default:  `[ ] =`
    - <details>
        <summary>MGR's hotkeys (QWERTY Keyboards)</summary>
      
        `[` = Frame Advance\
        `]` = Play/Pause\
        `Right Shift` = Uncap emulation speed
      
        `Alt`+`-` = Save state to selected slot\
        `=` = Load state from selected slot
        `Ctrl`+`Shift`+`-` = Undo Save State\
        `Ctrl`+`Shift`+`=` = Undo Load State
      
        `Ctrl`+`Shift`+`1` = Select slot 1 (Use 1-9 and 0 to select slots 1-10)\
        `Alt`+`Shift`+`1` = Save state to slot 1 (Use 1-9 and 0 to save to slots 1-10)\
        `Alt`+`Shift`+`Q` = Load state from slot 1 (Use Q-P to load from slots 1-10)
   
        `Alt`+`;` = Start selected script\
        `Alt`+`'` = Cancel selected script\
        `Esc` = Stop the current emulation
      </details>
  - Background input is recommended but not necessary.

4. (Recommended) Download the most [up-to-date TAS files](https://github.com/MGR-tas/NsmbwTAS-Files). Place these in the `Studio\TAS Files` folder

## Using TAS Studio!

`NSMBW Studio.exe` is in the `Studio` folder. Open it; you can either use the blank file that it creates or open an existing file.

Open Dolphin and start New Super Mario Bros Wii. Select `Tools -> Execute Script`. From this window, you can launch any script in your `Sys\Scripts` folder. Launch `Data.lua` to see a bunch of useful information about the game.

When you want to 'hit play' on your TAS, Launch the script called `TAStudio.lua`. It will start replaying inputs as soon as the game is not loading.

### Input File
The input file is a text file with `tas` as the suffix, e.g. `01-01.tas`.

Format for the input file is (Frames),(Actions)

e.g. `123,R,J` (For `123` frames, hold `Right` and `Jump`)

### Available Actions
`R` = Right\
`L` = Left\
`U` = Up\
`D` = Down\
`N` = While holding L/R, do NOT hold run\
`G` = Run + 1/B Action\
`J` = Jump\
`X` = Spin Input (spin finishes 3f later)\
`P` = +\
`M` = -\
`H` = Home\
`O` = 1 (nunchuck controlls)\
`K` = 2 (nunchuck controlls)\
`C` = Nunchuck C

### Commands
Command|Description|Syntax|Legal in fullgame?
---|---|---|---
`Tilt`|Set the wiimote tilt (0-1023)|Tilt, *value*|Yes
`Hold`|Hold the specified buttons. To release, use without arguments|Hold, *inputs*|Yes
`Read`|Read inputs from another file. Root is the current file's directory|Read, *fileName*|Yes
`Insert Load`|Stop replaying inputs until the next load ends|Insert Load, *loadID*|Yes
`Write`|Edit an in-game memory value|Write, *valueType*, *address*, *value*[, *lock*]|No
`Unlock`|Clear the locked write list|Unlock|No
`Repeat`<br>`EndRepeat`|Repeats the enclosed lines for he specified number of times|Repeat, *#OfRepetitions*<br>*input_lines*<br>EndRepeat|Yes
`Enforce Legal`|Prevents the use of illegal commands (for fullgame TASes)|Enforce Legal|Yes
`Save LoadDoc`<br>`Open LoadDoc`|Save/Open the current Load Documentation to/from a file|Save LoadDoc[, *name*]<br>Open LoadDoc[, *name*]|Yes
`Delete`|Delete the object at the specified memory address|Delete, *address*|No
<!--Macro<br>EndMacro|Name a series of input lines<br>that can be called later|Macro, name<br>[input lines]<br>EndMacro<br><br>name, 5|Yes -->

<details>
  <summary>Additional info for using Write commands</summary>
  
  - There are a variety of different text strings that you can use instead of a memory address, so here's the list.
  - Strings prefixed with `.` should be placed after a different address (parent) to get good results (for example, `Player.PosX` or `0x8154B804.PosX`)
    - If strings prefixed with `.` are used without the period and without a parent, then they will assume that `Player` is the parent string.\

  `IGT` = Value of (InGameTimer - 1)*4096  (maybe I'll automate the conversion someday)\
  `RNG` = The game's RNG state (0x0 - 0xFFFFFFFF)\
  `LifeCount` = Mario's life count\
  `CoinCount`\
  `Score`\
  `SwitchTimer` = Remaining time on a P-Switch timer\
  `LevelDeaths` = Deaths per level (for easily activating super guide blocks; suffix with level name in format `.1-2`, `.5-Tower`)\
  `ProjectileCountA` = Number of recent fire/ice balls (set bot A and B)\
  `ProjectileCountB`\
  
  `Player` = The player's object address\
  `.PosX`\
  `.PosY`\
  `.Collision` = Collision flags\
  `.StarTimer` = Remaining time with star power (Player Only)\
  `.TwirlTimer` = Cooldown between spin inputs (Player Only)\
  `.SlideTimer` = 30 minus frames on ground since starting penguin slide (Player Only)\
  `.SpinTimer` = Remaining time getting upward speed from propeller spin (Player Only)\
  `.Jump` = Chained Jump Counter (Player Only)\
  `.ChainJumpTimer` = Remaining time to jump while activating the next chained jump state (Player Only)\
  `.Powerup` or `.PS` = Player Powerup State (0-6 unless you want to have fun)\
  `.PipeTimerL` or `.PipeTimerR` = Frames since landing on ground and holding L/R (Player Only)\
  
  `Inventory` = The game's inventory refference address\
  `.Mushrooms`\
  `.FireFlowers`\
  `.Propellers`\
  `.IceFlowers`\
  `.Penguins`\
  `.Minis`\
  `.Stars`\
  `.ps7s` (don't ask)
</details>



## Contact: 
@mgr_tas on Discord

Through my Discord server: https://discord.gg/JxXxKAPKwT
