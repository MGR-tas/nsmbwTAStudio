local text = ''
local prevFrameText = ''
local lastFrame = 0
local isNowLoading = true
local core = require 'NSMBWii_Core'
local objList = core.object.list()
local thisFrameFlags = {}
local lastFrameFlags = {}
local flags = {
  '0x1',
  '0x2',
  'PlayingAnim',  --3
  'Dead',  --4
  '0x5',
  '0x6',
  'IceDamage',  --7
  'Quake',  --8
  '0x9',
  'InJump',  --A
  'Over1speed',  --B
  'StaticJumpAnim',  --C
  '0xD',
  '0xE',
  'InSitJump',  --F
  'RideOffJump',  --10
  'CannonJump',  --11
  'WaitJump',  --12
  'WallSlide',  --13
  'JumpDai',  --14
  'NormalJumpDai',  --15
  'PlayerJumpDai',  --16
  'SomethingWithLRpipePhysics',  --17
  'IsThrowing',  --18
  '0x19',
  '0x1A',
  '0x1B',
  '0x1C',
  '0x1D',
  '0x1E',
  'ActivateBlockFromAbove',  --1F
  '0x20',
  '0x21',
  '0x22',
  '0x23',
  '0x24',
  '0x25',
  'Propel',  --26
  'PropelUpward',  --27
  '0x28',
  'PropelFall',  --29
  'DontSpinPropellerAnim',  --2A
  'SpinJump',  --2B
  '0x2C',
  'InitiateTwirl',  --2D
  'Twirl',  --2E
  '0x2F',
  'Slips',  --30
  'RollSlip',  --31
  '0x32',
  'OnFence',  --33
  'InHang',  --34
  'OnPole',  --35
  'OnVine',  --36
  '0x37',
  '0x38',
  '0x39',
  'InSwim',  --3A
  'InPenguinSwim',  --3B
  'InPenguinSlide',  --3C
  'WillCreatePenguinLandCloud',  --3D
  'SlideLock',  --3E
  '0x3F',
  '[Unused]StartSwimAction',  --40
  '0x41',
  '0x42',
  '0x43',
  '0x44',
  'IsBeingCarried',  --45
  '0x46',
  'PreventGroundPound',  --A7
  '0x48',
  '0x49',
  '0x4A',
  'OnYoshi',  --4B
  '0x4C',
  '0x4D',
  'InCloud',  --4E
  'InClownCar',  --4F
  '0x50',
  'InCrouch',  --51
  'ExitCrouch',  --52
  'LookAtCamera',  --53
  '0x54',
  '0x55',
  '0x56',
  '0x57',
  '0x58',
  'RideNut',  --59
  '0x5A',
  '0x5B',
  '0x5C',
  '0x5D',
  'InPipeWait',  --5E
  '0x5F',
  '0x60',
  'JumpSoundRelated',  --61
  '0x62',
  '0x63',
  'DemoNextGoToBlock',  --64
  '0x65',
  '0x66',
  '0x67',
  '0x68',
  '0x69',
  '0x6A',
  '0x6B',
  '0x6C',
  '0x6D',
  '0x6E',
  '0x6F',
  '0x70',
  '0x71',
  '0x72',
  '0x73',
  '0x74',
  '0x75',
  '0x76',
  'PlayerCarryRelated?',  --77
  '0x78',
  'SometimesSetsFlag77',  --79
  '0x7A',
  '0x7B',
  '0x7C',
  'FreezePlayerObj',  --7D
  '0x7E',
  '0x7F',
  '0x80',
  '0x81',
  'InCloud2',  --82
  '0x83',
  'Invincible',  --84
  '0x85',
  '0x86',
  '0x87',
  'DontResetHighSpeed',  --88
  '0x89',
  '0x8A',
  '0x8B',
  '0x8C',
  '0x8D',
  '0x8E',
  'CanMountYoshi',  --8F
  '0x90',
  '0x91',
  'CanGrabItem',  --92
  '0x93',
  '0x94',
  '0x95',
  'WallJumpSpeedControl',  --96
  'Slips2',  --97
  'LockPenguinYSpeed',  --98
  'ZPosChanged',  --99
  '0x9A',
  'CanGrabFence',  --9B
  'CanGrabVine/Rope',  --9C
  'CanGrabPole',  --9D
  'CanGoToStateFire',  --9E
  'AllowSpinput',  --9F
  'AllowWindPush',  --A0
  'WillHangOnLedge',  --A1
  'WillStandOnLedge',  --A2
  'SomethingWithTarzanRope',  --A3
  '0xA4',
  'HoldingJumpAndOver1ySpeed',  --A5
  'RecentlyEnteredStateFire',  --A6
  '0xA7',
  'PreventWallSlide/Jump',  --A8
  '0xA9',
  'PreventStandardWaterEntry',  --AA
  'JumpSoundRelated',  --AB
  '0xAC',
  'IsPenguin',  --AD
  'PreventBeingEatenByYoshi?',
  '0xAF',
  '0xB0',
  'YoshiEmptyMouth',  --B1
  '0xB2',
  '0xB3',
  '0xB4',
  'DontPlayPlayerSounds',  --B5
  '0xB6',
  'SomethingWithCollision',  --B7
  '0xB8',
  'OffScreen',  --B9
  'Invincible2',  --BA
  'Invisible',  --BB
  'HideTemporary',  --BC
  '0xBD',
  '0xBE',
  '[Unused]BonkedOnCeiling', --BF
  '0xC0',
  'WalksOnWater',  --C1
  'WillGet0.5ySpeedOnEnteringStateFall',  --C2
  'WontSinkInWater',  --C3
  'IsSmall',  --C4
  '0xC5',
  '0xC6',
  '0xC7',
  'InPlayerEat',  --C8
  '0xC9',
  'InPlayerEat2',  --CA
  'YoshiAloneWait'  --CB
}

function onScriptStart()
  if ReadValueString(0, 3) ~= 'SMN' then
    CancelScript()
  end
end

function onScriptCancel()
  SetScreenText('')
end

local function isPressed(button, inputs)  --copied from the input import/export scripts, but is used for detecting collision properties here
  return button & inputs == button
end

function getLoadInfo()
  if objList.ObjectNum == 1 then  --cannot be predicted; abort
    return isNowLoading
  end
  if objList.loadCheckObjs < 2 then  --is loading
    return true
  else  --is not loading
    return false
  end
end


function bin(n)
  local r = ''
  for i = 1, 32 do
    if n / 2 == n // 2 then
      r = '0' .. r
    else
      r = '1' .. r
    end

    n = n >> 1
  end
  return r
end


function isState(bitNumber)
  if bitNumber == nil then return 'error' end
  local stateTableAddr = 0x8154C818
  
  while bitNumber > 32 do
    stateTableAddr = stateTableAddr + 4
    bitNumber = bitNumber - 32
  end
  
  if ReadValue32(stateTableAddr) & 2^(bitNumber) ~= 0 then
    return 'true'
  else
    return 'false'
  end
end

function setState(bitNumber, value)
  if bitNumber == nil then return 'error' end
  if value == nil then value = 1 end
  
  local stateTableAddr = 0x8154C818
  while bitNumber > 32 do
    stateTableAddr = stateTableAddr + 4
    bitNumber = bitNumber - 32
  end
  local stateTableValue = ReadValue32(stateTableAddr)
  
  
  if value == 1 then
    WriteValue32(stateTableAddr, stateTableValue|(2^(bitNumber)))
    return 'Enabled'
  elseif stateTableValue & 2^(bitNumber) ~= 0 then
    WriteValue32(stateTableAddr, stateTableValue-(2^(bitNumber)))
    return 'Disabled'
  else
    --return 'No Action Taken'
    return value
  end
end


function getAllStates()
  local stateTableAddr = 0x8154C818
  local output = ''
  local listNum = 0
  local totalFlagNum = 1
  thisFrameFlags = {}
  
  for j=0,6 do
    local stateTableValue = ReadValue32(stateTableAddr)
    for i=0,31 do
      local flagNum = i+(32*j)
      if stateTableValue & 2^(i) ~= 0 and flagNum > 1 then
        listNum = listNum+1
        if listNum == 5 then
          listNum = 1
          output = output .. '\n'
        end
        output = string.format('%s%s, ', output, flags[flagNum])
        thisFrameFlags[flagNum] = 1
      else
        thisFrameFlags[flagNum] = 0
      end
    end
    stateTableAddr = stateTableAddr + 4
  end
  
  local onFlagText = 'Turned ON Flags: '
  local offFlagText = 'Turned OFF Flags: '
  if thisFrameFlags ~= lastFrameFlags then
    for i=1,203 do
      if thisFrameFlags[i] ~= lastFrameFlags[i] then
        if thisFrameFlags[i] == 1 then
          onFlagText = string.format('%s%s, ', onFlagText, flags[i])
        else
          offFlagText = string.format('%s%s, ', offFlagText, flags[i])
        end
      end
    end
  end
  
  output = string.format('%s\n%s\nPlayer Flags: \n%s', onFlagText, offFlagText, output)
  return output
end


function onScriptUpdate()
  local p1   = core.players.P1()
  local ps   = p1.Misc[1]
  local rng  = ReadValue32(core.rng.addr)
  objList = core.object.list()
  isNowLoading = getLoadInfo()

  if GetFrameCount() ~= lastFrame then
    lastFrameFlags = thisFrameFlags
    lastFrame = GetFrameCount()
    --prevFrameText = text  --uncomment this line (and moddify the output line later) if you want the lua script to display stuff a frame late; shows what the values are on the frame currently displayed on screen
  end
  text = ''
  

  text = string.format('%s\n\n--  Level %s  --', text, core.stats.misc().current_instance)
--if core.time.get().roomFrame == core.time.get().levelFrame then  --optional display only one level frame counter if they are the same
  --text = text .. string.format('\nLevel Timer : %.3f (%.0f)', core.time.get().igt, core.time.get().roomFrame)
--else
  text = text .. string.format('\nLevel Timer : %.3f (%.0f, %.0f)', core.time.get().igt, core.time.get().levelFrame, core.time.get().roomFrame)
--end
  text = text .. '\nRNG Value   : ' .. string.format('%X', rng)
  if core.stats.misc().switch_timer ~= 0 then
    text = text .. string.format('\nSwitch Timer : %.0f', core.stats.misc().switch_timer)
  end
  --text = string.format('%s\nLoading: %s', text, isNowLoading)

--Input-State Change
--Useful for level banner dismissal - mash 2/A and this will show the frame that the banner got dismissed. Then go back and press 2/A 3f before the number shown by this (also dolphin's turbo is bad so use a script to mash (Alternate.lua) or just experiment with pressing 2/A on a few different frames to see which one is optimal). Automatically hidden if you're in-level.

  if core.time.get().igt == 1 then
    local lastchange, recordstate
    if ReadValue8(0x80C87DBB) == 0 then
      if recordstate == 1 then
        --loadlength = GetFrameCount() - lastchange
        lastchange = GetFrameCount() - 1
      end
      recordstate = 0
    else
       if recordstate == 0 then
        lastchange = GetFrameCount() - 1
      end
      recordstate = 1
    end
    text = text .. '\nInput-State Change: ' .. tostring(lastchange)
    --text = text .. '\nPrev Transition Time: ' .. tostring(loadlength)
  end

  text = text .. '\n\n--  Mario  --'
  --text = string.format('%s\nInputs : %X', text, core.players.P1().Misc[5])

  text = string.format('%s\nCurrent State: %s', text, p1.Misc[7])
  text = string.format('%s\nPrevious State: %s', text, p1.Misc[8])
  --text = string.format('%s\nIs state: %s', text, isState(0x88))
  --text = string.format('%s\n\nSet State: %s', text, setState(0x4, 0))

  local collisionText = '\n'
  local flags = core.players.P1().Misc[6]
  if isPressed(1, flags) then
    collisionText = collisionText .. 'Ground '
    if isPressed (0x1000000, flags) then
      collisionText = collisionText .. '(Ice) '
    end
  end
  if isPressed(2, flags) then
    collisionText = collisionText .. 'Ceiling '
  end
  if isPressed(8, flags) then
    collisionText = collisionText .. 'WallL '
  end
  if isPressed(0x10, flags) then
    collisionText = collisionText .. 'WallR '
  end
  if isPressed(0x4000, flags) then  --0x10000 is also related?
    collisionText = collisionText .. 'Water '
    if isPressed(0x40000, flags) then
      collisionText = collisionText .. '(bubble) '
    end
  elseif isPressed(0x8000, flags) then
    collisionText = collisionText .. 'Liquid (Surface) '
  end
  if isPressed(0x20000, flags) then
    collisionText = collisionText .. 'StandingOnLiquidSurface?'
  end
  text = text .. collisionText

  text = string.format('%s\n\nX Position  : %.4f', text, p1.Pos[1])
  text = string.format('%s\nY Position  : %.4f', text, p1.Pos[2])
  text = string.format('%s\n\nX Displaced : %.4f', text, p1.Speed[1])
  --[[if math.abs(p1.Speed[1]-p1.Speed[2]) <= 0.00005 then  --prevents the difference from swapping between +0.0000 and -0.0000 absurdly frequently
    text = text .. ' (0.0000)'
  else]]
    text = string.format('%s (%.4f)', text, p1.Speed[1]-p1.Speed[2])
  --end
  text = string.format('%s\nX Speed     : %.4f', text, p1.Speed[2])
  text = string.format('%s\nX Speed Cap : %.4f', text, p1.Speed[3])
  text = string.format('%s\nX Accel     : %.4f', text, p1.Speed[4])
  text = string.format('%s\n\nY Displaced : %.4f', text, p1.Speed[5])
  text = string.format('%s\nY Speed     : %.4f', text, p1.Speed[6])
  text = string.format('%s\nY Accel     : %.4f\n', text, p1.Speed[7])

  if p1.Timers[1] ~= 0 then
    text = string.format('%s\nStar Timer  : %.0f', text, p1.Timers[1])
  end
  if ps == 4 then
    text = string.format('%s\nSpin Timer  : %.0f', text, p1.Timers[4])
  end
  if p1.Timers[2] ~= 0 then
    text = string.format('%s\nTwirl Timer : %.0f', text, p1.Timers[2])
  end
  if ps == 5 then
    text = string.format('%s\nSlide Timer : %.0f', text, p1.Timers[3])
  end
    text = string.format('%s\nAction Timer: %.0f', text, p1.Timers[5])
    text = string.format('%s\nStored Jump : %.0f', text, p1.Misc[2])
    text = string.format('%s\nJump Timer  : %.0f', text, p1.Timers[6])
  if p1.Misc[3] ~= 0 then
    text = string.format('%s\nPipe Timer  : %.0f', text, p1.Misc[3])
  else
    text = string.format('%s\nPipe Timer  : %.0f', text, p1.Misc[4])
  end
  text = string.format('%s\nCountdown   : %.0f', text, p1.Timers[7])
  text = string.format('%s\nAction Stage: %.0f', text, p1.Misc[9])

  --text = string.format('%s\n\nChanged Flags : %s', text, getChangedFlags())
  text = string.format('%s\n\n%s', text, getAllStates())

  --text = text .. '\n\n' .. objList.itemSearchList  --select an object to watch at the top of NSMBW_Core.lua. Displays object address, position, and speed by default; watch data can be cusomized in NSMBW_Core.lua.
  text = text .. '\n\n' .. objList.compactObjList
  --text = text .. '\n\n' .. objList.fullObjList  --uncomment this line and comment the above line to see the full object list, with object addresses.

  SetScreenText(text)
end