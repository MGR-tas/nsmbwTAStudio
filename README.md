# NSMBW TAS Studio
A new way to TAS New Super Mario Bros Wii, based off of [Celeste TAStudio](https://github.com/EverestAPI/CelesteTAS-EverestInterop/tree/a968bc96f958d67ddce3de84175f0e2b0bad1572). Source code for `NSMBW Studio.exe` is included in each release, but it is mostly unchanged from Celeste TAStudio and is not needed for TASing. The main repository is for the TAS Studio setup itself.

## Setup
Option 1: All-in-one package
- Download the latest All-in-one package from the latest Release. Once you've done that, you can skip down to the `Hotkeys` section of step 3 in the setup. The recommended hotkeys are already set and an older set of the main category TAS files are included with the All-in-one package.

Option 2: Manual setup
1. Download [Dolphin Lua Core v4.6](https://github.com/MikeXander/Dolphin-Lua-Core/releases/tag/v4.6), and put it into a folder of your liking
2. Download this repository (go to `Code`->`Download ZIP`) and paste its contents into your Dolphin directory (the same folder as `Dolphin.exe`).
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
    - Note: Hotkey controller binds are not required for TASing with Studio. If you do map hotkeys for controller input, use only `Shake Z` for your spin input key.

- Hotkeys
  - MGR's recommened hotkeys are saved as a profile called `TAS Studio`. If you decide to use your own, make sure you have hotkeys for Save/Load States, Frame Advance, and Toggle Pause.
    - Note: If you use your own hotkeys, Studio may accept them as input, meaning they could change the TAS file or use up undos. These keys are not accepted as input by Studio by default:  `[ ] =`
    - <details>
        <summary>Recommended hotkeys (QWERTY Keyboards)</summary>
      
        `[` = Frame Advance\
        `]` = Play/Pause\
        `Right Shift` = Uncap emulation speed
      
        `Alt`+`-` = Save state to selected slot\
        `=` = Load state from selected slot\
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

In your dolphin folder, open `Studio`->`NSMBW Studio.exe`. You can either create a new file or open an existing one.
- Note: If studio auto-generates a file called `MarioWii.tas`, then you will have to save it to a file on your computer in order for the script to be able to read it.

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
`Repeat`<br>`EndRepeat`|Repeats the enclosed lines for the specified number of times|Repeat, *#OfRepetitions*<br>*inputsToRepeat*<br>EndRepeat|Yes
`Read`|Read inputs from another file. Root is the current file's directory|Read, *fileName*|Yes
`Insert Load`|Stop replaying inputs until the next load ends|Insert Load, *loadID*|Yes
`Write`|Edit an in-game memory value|Write, *valueType*, *address*, *value*[, *lock*]|No
`Unlock`|Clear the locked write list|Unlock|No
`Delete`|Delete the object at the specified memory address|Delete, *address*|No
`Enforce Legal`|Prevents the use of illegal commands (for fullgame TASes)|Enforce Legal|Yes
`Save LoadDoc`<br>`Open LoadDoc`|Save/Open the current Load Documentation to/from a file|Save LoadDoc[, *name*]<br>Open LoadDoc[, *name*]|Yes
<!--Macro<br>EndMacro|Name a series of input lines<br>that can be called later|Macro, name<br>[input lines]<br>EndMacro<br><br>name, 5|Yes -->

<details>
  <summary>Additional info for Load-related commands</summary>

  New Super Mario Bros Wii has inconsistent loading times. By adding an `Insert Load` command, the game will pause the input replay until the next load ends, then continue. This makes sure that the TAS will always sync even if the load length changes. However, if enemy dances or other music cycles are affected, then the TAS may still desync when improvements are made or if the TAS is played on a different version of the game than it was drafted on. There currently is no way around this, unfortunately.

  Each load must be given a unique ID so that the script can document how long each load was and use that information to allow you to use savestates after the load. An example input line would be: `Insert Load, 5-2 Pipe1`

  When you restart `TAStudio.lua`, the load documentation is reset, so the TAS must run through any loads to redocument them. This is usually not a big deal for individual level TASing, but when working with a fullgame file, you may want to use `Save LoadDoc` and `Open LoadDoc`. These commands will save and recall your load documentation so that you can continue working between sessions without having to replay the whole TAS. Here's an example file of how to use that:

```
#Start
Open LoadDoc, 5-4
 250,R
Insert Load, 5-4 Pipe1
 106
Save LoadDoc, 5-4
  50,R
```
  
</details>

<details>
  <summary>Additional info for using Write commands</summary>

  - Available Value Types:\
  `8`\
  `16`\
  `32`\
  `Float`\
  `String`
  - There are a variety of different text strings that you can use instead of a memory address, so here's the list.
  - Strings prefixed with `.` should be placed after a different address (parent) to get good results (for example, `Player.PosX` or `0x8154B804.PosX`)
    - Most strings prefixed with `.` can be used without a parent, in which case they will assume that `Player` is the parent string.
    - Note: In multiplayer, the parent string `Player` only refers to the player who spawns first.

  `IGT` = Value of (InGameTimer - 1)*4096  (maybe I'll automate the conversion someday) (32)\
  `RNG` = The game's RNG state (0x0 - 0xFFFFFFFF) (32)\
  `LifeCount` = Mario's life count (32)\
  `CoinCount` (32)\
  `Score` (32)\
  `SwitchTimer` = Remaining time on a P-Switch timer (32)\
  `LevelDeaths` = Deaths per level (for easily activating super guide blocks; suffix with level name in format `.1-2`, `.5-Tower`) (8)\
  
  `Player` = The player's object address\
  `.PosX` (Float)\
  `.PosY` (Float)\
  `.Collision` = Collision flags (32)\
  `.StarTimer` = Remaining time with star power (Player Only) (32)\
  `.TwirlTimer` = Cooldown between spin inputs (Player Only) (32)\
  `.SlideTimer` = 30 minus frames on ground since starting penguin slide (Player Only) (32)\
  `.SpinTimer` = Remaining time getting upward speed from propeller spin (Player Only) (32)\
  `.Jump` = Chained Jump Counter (Player Only) (32)\
  `.ChainJumpTimer` = Remaining time to jump while activating the next chained jump state (Player Only) (32)\
  `.Powerup` or `.PS` = Player Powerup State (0-6 unless you want to have fun) (32)\
  `.PipeTimerL` and `.PipeTimerR` = Frames since landing on ground and holding L/R (Player Only) (32)
  
  `Inventory` = The game's inventory refference address\
  `.Mushrooms` (32)\
  `.FireFlowers` (32)\
  `.Propellers` (32)\
  `.IceFlowers` (32)\
  `.Penguins` (32)\
  `.Minis` (32)\
  `.Stars` (32)\
  `.ps7s` (32) (don't ask)
</details>



## Contact: 
I can always be found in `#tas-discussion` in the [NSMBW Speedrunning Discord Server](https://discord.gg/T7Nwspm)
