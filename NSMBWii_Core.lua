
--[[
  TODO:
  - Test addresses for all versions
]]

local core    = {}
local players = {}
local rng     = {}
local stats   = {}
local time    = {}
local object  = {}
local searchItem = ',AC_FLOOR_HOLE_DOKAN,' -- fill this with objects you want to watch in format ',object1,object2,object3,'  (useful for watching position/speed of enemies/objects or seeing when they load). To use, uncomment this line near the end of Data.lua

local syms = {
  __rvl_wpadcb = {
    E = 0x8039f360, J = 0x8039f0e0,
    P = 0x8039f660, K = 0x803ac060,
    W = 0x803aa460
  },
  dGameCom__m_rnd = {
    E = 0x80429f44, J = 0x80429c64,
    P = 0x8042a224, K = 0x80436be4,
    W = 0x80434fe4
  },
  fManager_c__m_executeManage = {
    E = 0x80377a34, J = 0x803777B4,
    P = 0x80377d34, K = 0x80384734,
    W = 0x80382b34
  },
  hash_A3F88BCE_A3F88BCE = {
    E = 0x80429F60, J = 0x80429c80,
    P = 0x8042a240, K = 0x80436c00,
    W = 0x80435000
  },
}

function core.game_id_rev()
  local id  = ReadValueString(0x80000004, 2)
  local reg = ReadValueString(0x80000003, 1)
  local rev = ReadValue8(0x80000007)

  return {ID = id, Region = reg, Rev = rev}
end

local id  = core.game_id_rev().ID
local reg = core.game_id_rev().Region
local rev = core.game_id_rev().Rev

-- PLAYER STATS --
players.addrs = {
  0x8154b804, -- P1
  0x81548aec, -- P2
  0x81545dd4, -- P3
  0x815430bc, -- P4
}

function players.player(player)
  local addr = players.addrs[player]

  local currentState = ReadValueString(GetPointerNormal(addr + 0x1478, 4, 0), 99)
  local previousState = ReadValueString(GetPointerNormal(addr + 0x1494, 4, 0), 99)
  local demoState = ReadValueString(GetPointerNormal(addr + 0x142C, 4, 0), 99)
  if demoState ~= 'daPlBase_c::StateID_DemoNone' then
    currentState = demoState
  end

  local inputs = ReadValue16(
    syms.__rvl_wpadcb[reg] + (0xbe0 * player) + 0x100
  ) --__rvl_wpadcb[player].rxBufs[1]
  local collisionFlags = ReadValue32(addr + 0x10D4)

  local x_pos = ReadValueFloat(addr + 0xAC)
  local x_disp = ReadValueFloat(addr + 0xC4)
  local x_spd = ReadValueFloat(addr + 0x10C)
  local x_cap = ReadValueFloat(addr + 0x110)
  local x_accel = ReadValueFloat(addr + 0x11C)

  local y_pos = ReadValueFloat(addr + 0xB0)
  local y_disp = ReadValueFloat(addr + 0xC8)
  local y_spd = ReadValueFloat(addr + 0xEC)
  local y_accel = ReadValueFloat(addr + 0x114)

  local star = ReadValue32(addr + 0x1070)
  local twirl = ReadValue32(addr + 0x27C8)
  local slide = ReadValue32(addr + 0x1A18)
  local spin = ReadValue32(addr + 0x17C4)
  local action = ReadValue32(addr + 0xEC0)
  local jump = ReadValue8(addr + 0x1568)
  local someCountdown = ReadValue32(addr + 0x14A8)

  local powerup = ReadValue32(addr + 0x14E0)
  local stored_jump = ReadValue32(addr + 0x1564)
  local lPipe = ReadValue8(addr + 0x420)
  local rPipe = ReadValue8(addr + 0x421)
  local hipAttackStage = ReadValue32(addr+ 0x14A4)

  return {
    Pos    = {x_pos, y_pos},
    Speed  = {x_disp, x_spd, x_cap, x_accel, y_disp, y_spd, y_accel},
    Timers = {star, twirl, slide, spin, action, jump, someCountdown},
    Misc   = {powerup, stored_jump, lPipe, rPipe, inputs, collisionFlags, currentState, previousState, hipAttackStage}
  }
end

function players.P1()
  return players.player(0)
end
function players.P2()
  return players.player(1)
end
function players.P3()
  return players.player(2)
end
function players.P4()
  return players.player(3)
end


-- RNG --
rng.addr = syms.dGameCom__m_rnd[reg]

function rng.next(x, maximum)
  local x = rng.increment(x, 1)
  return (x * maximum) >> 32
end

function rng.increment(x, n)
  local a = 0x19660D
  local b = 0x3C6EF35F
  local c = 0x100000000

  local i = 0
  while i < n do
    x = x * a + b
    x = (x + (x >> 32)) % c
    i = i + 1
  end

  return x
end

-- STATS --

function stats.misc()
  stats.inv_addr_ref = 0x815DBB74

  return {
    mushrooms  = ReadValue32(stats.inv_addr_ref),
    f_flowers  = ReadValue32(stats.inv_addr_ref + 0x4),
    propellers = ReadValue32(stats.inv_addr_ref + 0x8),
    i_flowers  = ReadValue32(stats.inv_addr_ref + 0xC),
    penguins   = ReadValue32(stats.inv_addr_ref + 0x10),
    minis      = ReadValue32(stats.inv_addr_ref + 0x14),
    stars      = ReadValue32(stats.inv_addr_ref + 0x18),
    ps7s       = ReadValue32(stats.inv_addr_ref + 0x1C),
    switch_timer = ReadValue32(0x815E4338),
    last_level_name = ReadValueString(0x80373AFC, 99),
    current_world = ReadValueString(syms.hash_A3F88BCE_A3F88BCE[reg], 99),
    current_instance = ReadValueString(0x80D20F04, 99)
  }
end

-- TIME --

function time.get()
  local timer_addr = 0x80D25BF8
  return {
    igt = ReadValue32(timer_addr) / 4096 + 1,
    roomFrame = ReadValue16(0x815E44EE),
    levelFrame = ReadValue16(0x923D4066),
  }
end

-- OBJECT LIST --

function object.list()
  local objName = {}
  local objAddr = {}

  local objectNodeAddr = ReadValue32(syms.fManager_c__m_executeManage[reg])
  local i = 1
  while (objectNodeAddr ~= 0x0) do
    local objectAddr    = ReadValue32(objectNodeAddr + 0x8)
    local objectNamePtr = ReadValue32(objectAddr + 0x6C)

    objName[i] = ReadValueString(objectNamePtr, 0x100)
    objAddr[i] = string.format('0x%X', objectAddr)

    objectNodeAddr = ReadValue32(objectNodeAddr + 0x4)
    i = i + 1
  end

  local ObjectNum = 1
  local fullObjList = ''
  local compactObjList = ''
  local itemSearchList = ''
  local loadCheckObjs = 0
  while objName[ObjectNum] ~= nil do
    local j = 0
    while objName[ObjectNum] == objName[ObjectNum + j] do
      fullObjList = fullObjList .. objAddr[ObjectNum + j] .. ' ' .. objName[ObjectNum] .. '\n'
      if string.find(searchItem, ',' .. objName[ObjectNum] .. ',') ~= nil then
        itemSearchList = itemSearchList .. objName[ObjectNum + j] .. ' ' .. objAddr[ObjectNum + j]
        itemSearchList = itemSearchList .. string.format('\n (%.4f, %.4f)', ReadValueFloat(objAddr[ObjectNum + j] + 0xAC), ReadValueFloat(objAddr[ObjectNum + j] + 0xB0))
        itemSearchList = itemSearchList .. string.format('\n (%.4f, %.4f)', ReadValueFloat(objAddr[ObjectNum + j] + 0xC4), ReadValueFloat(objAddr[ObjectNum + j] + 0xC8)) .. '\n\n'
      end
      j = j + 1
    end
    local instance = stats.misc().current_instance
    if objName[ObjectNum] == 'YES_NO_WINDOW' or objName[ObjectNum] == 'PLAYER' or objName[ObjectNum] == 'WM_MAP' or objName[ObjectNum] == 'WORLD_9_DEMO' then
      loadCheckObjs = loadCheckObjs + 1
    --I'm sorry
    elseif (objName[ObjectNum] == 'SELECT_CURSOR' and instance == 'sequenceBGTexture') or objName[ObjectNum] == 'BOOT' or (string.find(objName[ObjectNum], 'CRSIN') ~= nil and instance ~= '' and instance ~= '01-40' and instance ~= '01-42' and instance ~= 'MB') then
      loadCheckObjs = loadCheckObjs + 2
    end
    if ReadValue8(objAddr[ObjectNum] + 0xE) == 2 then
      compactObjList = compactObjList .. objName[ObjectNum] .. ' x' .. j .. '\n'
    end
    ObjectNum = ObjectNum + j
  end


  return {
    fullObjList = fullObjList,
    compactObjList = compactObjList,
    itemSearchList = itemSearchList,
    loadCheckObjs = loadCheckObjs,     --used for loadless input import/export
    ObjectNum = ObjectNum-1
  }

end


core.players = players
core.rng     = rng
core.stats   = stats
core.time    = time
core.object  = object
core.syms    = syms

return core
