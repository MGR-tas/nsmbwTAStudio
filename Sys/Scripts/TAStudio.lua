local core = require 'NSMBWii_Core'
dofile('Studio\\Value Lookup Table.lua')  --value lookup table and input binds are stored here

--init
local reg = core.game_id_rev().Region

local tilt = 512
local twirlTimer = 0

local lineNumber = 0
local pauseLineAdvance = 0
local isInMainFile = true
local currLineProgress = 0
local currLine = {0, 0, ''}
local exitLoop = false
local returnData = {0, 0, ''}

local initComplete = false
local prevLoadInfo = {true, true}
local root = ''

local subFrame = false
local subFrameInputs = {'', '', ''}
local inputCall = 1

local loopNum = 0
local totalLoopNum = 0
local messageNum = 0
local messageTimer = 0

local file
local scriptFirstFrame
local lastFrame
local offset
local index = 0
local round = 0
local heldButtons = ''

local failed = false
local loadDoc = ''
local writeValueList = ''
local lockedWriteValueList = ''
local macroDoc = ''

local nunchuckaddr = core.syms.__rvl_wpadcb[reg] + 0x840 --__rvl_wpadcb[P1].info.attach
local nunchuck

function onScriptStart()
  local studioSettingsFile = io.open('Studio\\Studio Config.toml', 'r+')  --find the file currently opened by Studio and use it
  local _, _, readFileName = string.find(tostring(studioSettingsFile:read('*all')), 'LastFileName = "(.-)"')
  studioSettingsFile:close()

  _, _, root = string.find(readFileName, '(.*\\)')

  file = io.open(readFileName, 'r')
  messageSend(string.format('Reading file: %s', readFileName), 0xD2691E)

  scriptFirstFrame = GetFrameCount()
  lastFrame = scriptFirstFrame
  offset = scriptFirstFrame

  --Determines whether playing with or without nunchuck, which changes where tilt controlls are sent
  nunchuck = ReadValue32(nunchuckaddr) ~= 0
end

function onScriptCancel()
end

function onScriptUpdate()  --called every input call (3-4 times per frame)
  inputCall = inputCall + 1
  if lastFrame ~= GetFrameCount() then  --executes this loop once a frame
    inputCall = 1
    round = 1
    messageNum = 0
    writeValueList = ''
    index = GetFrameCount() - offset
    if initComplete and index > 0 then
      currLine = findLineFromIndex()  --finds the current input line and records a bunch of data for later use
    end

    --currLineProgress = index - currLine[2] + currLine[1]
    lastFrame = GetFrameCount()

    --display TAS info
    RenderText(string.format('%5.0f', lineNumber), 450, 29, 0xF1FA8C, 22)
    RenderText(string.format('%4.0f/%.0f,', index-currLine[2]+currLine[1], currLine[1]), 550, 29, 0xFFB86C, 22)
    RenderText(string.format('%s%s', currLine[3], heldButtons), 720, 29, 0x20B4B6, 22)
    if loopNum ~= 0 then
      messageSend(string.format('Repeat %.0f/%s', loopNum, totalLoopNum), 0x00FFFF)
    end

    --RenderText(string.format('Load Doc: %s', loadDoc), 500, 704, 0xD2691E, 11)
  elseif round == 1 then
    prevLoadInfo = {getLoadInfo(), prevLoadInfo[1]}
    if initComplete == false then  --manage IndexMode if init is not complete
      setIndex()
    end
    if writeValueList ~= '' then messageSend(writeValueList, 0xD2691E) end
    if lockedWriteValueList ~= '' then messageSend(lockedWriteValueList, 0xD2691E) end
    round = 0
  end


  local e = 0
  local thisFrameWriteList = lockedWriteValueList .. writeValueList
  while true do  --write all the queued values for this frame
    local _, endLine, valueType, address, valueToWrite = string.find(thisFrameWriteList, '(.-),(.-),(.-)\n', e+1)
    if endLine == nil then break end
    writeValue(valueType, address, valueToWrite)
    e = endLine
  end


  if index < 1 then  --prevents the script from playing inputs before the input file starts
    currLine = {0, 0, ''}
    tilt = 512
    subFrame = false
  end

  if subFrame then 
    --messageSend(string.format('Sub-Frame line: %s, %s, %s', subFrameInputs[1], subFrameInputs[2], subFrameInputs[3]), 0x00FFFF)
    if inputCall < 3 then
      convertLineToInputs(subFrameInputs[inputCall])
      messageSend(string.format('Sub Frame Input Sent: %s', subFrameInputs[inputCall]), 0x00FFFF)
    else
      convertLineToInputs(subFrameInputs[3])
      messageSend(string.format('Sub Frame Input Sent: %s', subFrameInputs[3]), 0x00FFFF)
    end
  else
    convertLineToInputs(currLine[3])  --execute button inputs
  end
  if nunchuck then
    SetAccelX(tilt, 4)
  else
    SetAccelY(tilt, 4)
  end
  if twirlTimer ~= 0 then  --set accZ according to twirl timer
    SetAccelZ(512*(twirlTimer-1), 4)
  end

end

function findLineFromIndex()
  if fileIsUpdated() or GetFrameCount()-lastFrame ~= 1 or index == 1 then
    --messageSend('File indexed from start', 0x00FF00)
    startLinePos = 1
    endLinePos = 1
    totalFramesAtIndex = 0
    currLineProgress = 0
    isInMainFile = true
    macroDoc = ''
    tilt = 512
    heldButtons = ''
    lockedWriteValueList = ''

    rawLine = ''
    allowCheats = true

    lineNumber = 0
    pauseLineAdvance = 0
    loopNum = 0
    totalLoopNum = 0

    file:seek('set', 0)
    rawFile = tostring(file:read('*all')) .. '\nset, pauseLineAdvance,1\n   0'  --add an extra line of length 0 at the end to prevent the script from crashing in some situations
  --else  --if file will continue being indexed from where it left off last frame

  end
  subFrame = false
  subFrameInputs = {'', '', ''}

  --debug display file
  --RenderText('File: \n' .. string.sub(rawFile, startLinePos-150, startLinePos+1000), 800, 29, 0xD2691E, 11)
  --messageSend(string.format('Index: %.0f', index), 0xFF00FF) 

  while index > totalFramesAtIndex do  --searches through the input file until the current line is reached
    endLinePos = string.find(rawFile,'\n', startLinePos)
    if endLinePos == nil then  --if the end of the file has been reached, set endLinePos to the end of the file to prevent out of range errors
      endLinePos = rawFile.len(rawFile)
      rawLine = string.sub(rawFile, startLinePos, endLinePos)
    else
      rawLine = string.sub(rawFile, startLinePos, endLinePos-1)
    end
    arg1 = rawLine
    arg2 = ''
    if string.find(rawLine, ',') ~= nil then
      _, _, arg1, arg2 = string.find(rawLine, '(.-),%s*(.*)')
    end
    inputDuration = tonumber(arg1)
    if pauseLineAdvance == 0 then
      lineNumber = lineNumber + 1
    end

    if inputDuration ~= nil then  --if current line is an input line
      totalFramesAtIndex = totalFramesAtIndex + inputDuration
      currLineProgress = index - totalFramesAtIndex + inputDuration
      lineInputs = arg2
      if string.find(lineInputs, 'X') ~= nil and currLineProgress < 6 then  --detect a spinput in the current read line. Second condition is necessary for loading savestates during spinputs
        twirlTimer = 5 - currLineProgress
      end
    --elseif string.sub(rawLine, 1, 1) == '#' then  --if the current line is a comment

    elseif endLinePos-startLinePos > 2 and string.sub(rawLine, 1, 1) ~= '#' then  --line is a command
      if index == totalFramesAtIndex+1 then processCommand() end
      processGlobalCommand()
      if exitLoop then
        exitLoop = false
        return returnData  --simulate finding the current input
      end
    end

    if endLinePos == rawFile.len(rawFile) then  --exit the loop if the end of the file has been reached, else calcualate the next line's starting position
      break
    else
      startLinePos = endLinePos + 1
    end
  end
  if twirlTimer ~= 0 then
    twirlTimer = twirlTimer - 1
  end
  return {
    inputDuration,
    totalFramesAtIndex,
    lineInputs
  }
end

function processGlobalCommand()
  if arg1 == 'Tilt' then  --set Tilt controls when a 'Tilt' command is processed
    if tonumber(arg2) == nil then
      messageSend(string.format('Invalid Tilt value "%s"', arg2), 0xFF0000)
      return
    else
      tilt = tonumber(arg2)
    end
    return
  elseif arg1 == 'Hold' then  --Start holding specified buttons
    heldButtons = arg2
    return
  elseif arg1 == 'Write' and allowCheats then
    local _, _, valueType, address, valueToWrite, lock = string.find(arg2 .. ',','(.-),%s*(.-),%s*(.-),%s*(%d?)')
    if address == nil then  --prevent the script from crashing if the line is formatted incorrectly
      messageSend(string.format('Bad Write Line "%s"', rawLine), 0xFF0000)
    elseif index == totalFramesAtIndex+1 or lock == '1' then
      local writeAddr = convertStringToAddress(address)
      if lock == '1' and writeAddr ~= 0 then
        lockedWriteValueList = string.format('%s%s, 0x%X, %s\n', lockedWriteValueList, valueType, writeAddr, valueToWrite)
      elseif writeAddr ~= 0 then
        writeValueList = string.format('%s%s, 0x%X, %s\n', writeValueList, valueType, writeAddr, valueToWrite)  --add values to write this frame to a list. Write them during the main loop so they get updated every input call
      end
    end
    return
  elseif arg1 == 'Unlock' then
    lockedWriteValueList = ''
    return
  elseif arg1 == 'Read' then  --manage read files
    doReadManagement()
    return
  elseif arg1 == 'End Read' then  --record endReadFrame so that we don't have to reindex the file after this
    pauseLineAdvance = 0
    isInMainFile = true
    tilt = 512
    heldButtons = ''
    macroDoc = ''
    local readCommandFileName = arg2
    local loadDocumentationStartPos, loadFileNameEndPos = string.find(loadDoc, string.format('%s,', readCommandFileName), 1, true)
    loadDoc = string.format('%s%7.0f%s',string.sub(loadDoc, 1, loadFileNameEndPos+10), totalFramesAtIndex+1, string.sub(loadDoc, loadFileNameEndPos+18, -1))
    return
  elseif arg1 == 'Insert Load' then  --pause replaying inputs until the next load ends
    doLoadManagement()
    return
  elseif arg1 == 'Manual' then
    if tonumber(arg2) == nil then
      messageSend(string.format('Invalid Offset "%s"', rawLine), 0xFF0000)
      return
    end
    offset = tonumber(arg2)
    index = GetFrameCount() - offset
    initComplete = true
    messageSend(string.format('Offset updated manually to %.0f', offset), 0x00FF00)
  elseif arg1 == 'Enforce Legal' then
    allowCheats = false
    return
  elseif arg1 == 'repeat' or arg1 == 'Repeat' then
    local nextRepeatLineStartPos = endLinePos
    local afterNextRepeatLine = endLinePos
    local repeatEndPos = endLinePos
    local afterCommand = endLinePos
    while true do
      nextRepeatLineStartPos, afterNextRepeatLine = string.find(rawFile, '\n[Rr]epeat', afterNextRepeatLine)
      repeatEndPos, afterCommand = string.find(rawFile, '\n[Ee]nd[Rr]epeat', afterCommand)
      if repeatEndPos == nil then
        messageSend(string.format('No "EndRepeat" found!  %s', rawLine), 0xFF0000)
        return
      end
      if nextRepeatLineStartPos == nil then break end
      if repeatEndPos < nextRepeatLineStartPos then break end
    end
    local arg2 = tonumber(arg2)
    if arg2 == 0 or arg2 == nil then
      arg2 = 1
    end
    rawFile = string.format('%sendrepeat,%d,%d,%d,%d%s', string.sub(rawFile, 1, repeatEndPos), endLinePos, lineNumber, arg2-1, arg2, string.sub(rawFile, string.find(rawFile, '\n', afterCommand), -1))
    loopNum = 1
    totalLoopNum = arg2
    return
    --endrepeat, endlinepos, linenumber, remainingloops, totalloops
  elseif arg1 == 'endrepeat' then
    if arg2 == '' then
      messageSend(string.format('"EndRepeat" found on line %d with no associated Repeat command!', lineNumber), 0xFF0000)
      return
    end
    _, _, arg2, arg3, arg4, arg5 = string.find(arg2, '(%d-),(%d-),(%d-),(%d+)')
    if arg4 ~= '0' then
      rawFile = string.format('%sendrepeat,%d,%d,%d,%d%s', string.sub(rawFile, 1, startLinePos-1), arg2, arg3, tonumber(arg4)-1, arg5, string.sub(rawFile, endLinePos, -1))
      loopNum = arg5-arg4+1
      totalLoopNum = arg5
      endLinePos = arg2
      if isInMainFile then lineNumber = arg3 end
    else
      loopNum = 0
      totalLoopNum = 0
    end
    return
  elseif arg1 == 'SubFrame' then
    totalFramesAtIndex = totalFramesAtIndex + 1
    currLineProgress = 0
    inputDuration = 1
    lineInputs = ''
    if index == totalFramesAtIndex then
      subFrame = true
      local _, _, call1, call2, call3 = string.find(arg2 .. ',,,', '(.-),(.-),(.-),')
      if call2 == '' then
        call2 = call1
      end
      if call3 == '' then
        call3 = call2
      end
      subFrameInputs = {call1, call2, call3}
    end
  elseif arg1 == 'set' and isInMainFile then
    local _, _, var, val = string.find(arg2, '(%w+),(%w+)')
    if var == 'lineNumber' then
      lineNumber = tonumber(val)
    elseif var == 'pauseLineAdvance' then
      pauseLineAdvance = tonumber(val)
    end
    return
  elseif arg1 == 'macro' or arg1 == 'Macro' then
    local _, endMacroPos, macro = string.find(rawFile, '(.-\n[Ee]nd[Mm]acro\n)', startLinePos)
    if macro == nil then
      messageSend('Macro declaration failed! No "EndMacro" found.', 0xFF0000)
      return
    end
    if string.find(macroDoc, rawLine) == nil then  --ignore any subsequent macro declarations with the same name
      macroDoc = string.format('%s%s\n', macroDoc, macro)
    else
      messageSend(string.format('Macro declaration failed! A macro already has this name.\n%s', macro), 0xFF0000)
    end
    local _, subs = string.gsub(macro, '\n', '\n')
    if isInMainFile then lineNumber = lineNumber + subs - 1 end
    endLinePos = endMacroPos  --move the reading position to after the macro
    return
  elseif string.find(macroDoc, arg1) ~= nil then  --check if this line is a known macro callback
    pauseLineAdvance = 1
    local _, macroStartPos = string.find(macroDoc, arg1)
    local macro = string.sub(macroDoc, macroStartPos+2, string.find(macroDoc, '[Ee]nd[Mm]acro', macroStartPos)-1)
    rawFile = string.format('%sset, pauseLineAdvance,1\nRepeat, %s\n%s\nendrepeat\nset, pauseLineAdvance,0%s', string.sub(rawFile, 1, startLinePos-1), arg2, macro, string.sub(rawFile, endLinePos, -1))
    endLinePos = startLinePos-1
    return
  end
end

function processCommand()
  if arg1 == 'Save LoadDoc' then
    local writeFileName
    if arg2 == '' then
      writeFileName = string.format('Studio\\LoadDocs\\%s.txt',ReadValueString(0x80D20F04, 99))
    elseif string.sub(arg2, -4) == '.txt' then
      writeFileName = string.format('Studio\\LoadDocs\\%s', arg2)
    else
      writeFileName = string.format('Studio\\LoadDocs\\%s.txt', arg2)
    end
    writeFile = io.open(writeFileName, "w+")
    writeFile:write(string.format('Offset: %.0f\n%s', offset, loadDoc))
    writeFile:close()
    messageSend(string.format('LoadDoc Saved Successfully!  %s', writeFileName), 0x00FF00)
  elseif arg1 == 'Open LoadDoc' then
    openLoadDoc()
  elseif arg1 == 'Delete' and allowCheats then
    local deleteAddr = convertStringToAddress(arg2)
    if deleteAddr ~= 0 then
      arg2 = ReadValueString(ReadValue32(deleteAddr + 0x6C), 0x100)
      messageSend(string.format('Deleted "%s" (0x%X)', arg2, deleteAddr), 0x00FF00)
      WriteValue8(deleteAddr+0xB, 2)
      end
  elseif arg1 == 'InputDisplay' and allowCheats then  --bool input display (0=off, 1=on; for Hitbox Mod v7)
    WriteValue8(0x80D2B100, arg2)
  elseif arg1 == 'HitboxMode' and allowCheats then  --change hitbox configuration (0=off, 1=basic, 2=complex; for Hitbox Mod v7)
    WriteValue8(0x80D2B107, arg2)
  elseif arg1 == 'Grid' and allowCheats then  --change hitbox configuration (0=off, 1=basic, 2=complex; for Hitbox Mod v7)
    WriteValue8(0x80D2B150, arg2)
  elseif arg1 == 'InfoDisplay' and allowCheats then  --change hitbox configuration (0=off, 1=basic, 2=complex; for Hitbox Mod v7)
    WriteValue8(0x80D2B157, arg2)
  end
end

function convertLineToInputs(line)
  line = line .. heldButtons
  line = string.gsub(line, ',', '')  --remove commas from input line for easier processing
  local inputNum = #line

  for i=1,inputNum do
    local inputStep = string.sub(line,i,i)
    if string.find(validButtons, inputStep) == nil then  --don't crash dolphin if an invalid input is given
      if round == 1 then
        messageSend(string.format('Invalid input "%s"', inputStep), 0xFF0000)
      end
      break
    end
    PressButton(inputTable[inputStep], 4)
  end
  if (string.find(line, 'L') ~= nil or string.find(line, 'R') ~= nil) and string.find(line, 'N') == nil then
    PressButton('Z', 4)
  end
end

function getLoadInfo()
  if core.object.list().ObjectNum == 1 then  --cannot be predicted; abort
    return prevLoadInfo[1]
  end
  if core.object.list().loadCheckObjs < 2 then  --is loading
    return true
  else  --is not loading
    return false
  end
end

function writeValue(valueType, address, valueToWrite)
  if valueType == '8' then
    WriteValue8(address, tonumber(valueToWrite))
  elseif valueType == '16' then
    WriteValue16(address, tonumber(valueToWrite))
  elseif valueType == '32' then
    WriteValue32(address, tonumber(valueToWrite))
  elseif valueType == 'Float' then
    WriteValueFloat(address, tonumber(valueToWrite))
  elseif valueType == 'String' then
    WriteValueString(address, valueToWrite)
  else
    messageSend(string.format('Unrecognized Write Value Type %s', valueType), 0xFF0000)
  end
end

function readValue(valueType, address)
  if valueType == '8' then
    return ReadValue8(address)
  elseif valueType == '16' then
    return ReadValue16(address)
  elseif valueType == '32' then
    return ReadValue32(address)
  elseif valueType == 'Float' then
    return ReadValueFloat(address)
  elseif valueType == 'String' then
    return ReadValueString(address)
  else
    messageSend(string.format('Unrecognized Read Value Type %s', valueType), 0xFF0000)
  end
end

function messageSend(messageText, color)
  messageNum = messageNum+1
  local disPosY = messageNum*15+29
  RenderText(messageText, 500, disPosY, color, 11)
end

function setIndex()
  if prevLoadInfo[1] == false and prevLoadInfo[2] == true then
    index = 1
    offset = GetFrameCount()
    messageSend(string.format('Offset updated automatically to %.0f', offset), 0xD2691E)
    initComplete = true
    currLine = findLineFromIndex()
    --prevLoadInfo[2] = false
  else
    messageSend('Waiting for load to end...', 0xD2691E)
  end
end

function doLoadManagement()
  local loadID = arg2
  local loadIDStartPos, loadIDEndPos = string.find(loadDoc, string.format('%s,', loadID), 1, true)
  local startLoadFrame = totalFramesAtIndex+1
  pauseLineAdvance = 1
  if loadIDStartPos == nil then  --if load has not been documented yet
  --example Load Doc line: '[load ID],   10842,   12399'  --works up until input index 9,999,999 (46 hours)
    loadDoc = loadDoc .. string.format('\n%s, %7.0f, %7.0f', loadID, startLoadFrame, 0)
    --messageSend('Wrote to LoadDoc Init', 0x00FFFF)
    loadIDStartPos, loadIDEndPos = string.find(loadDoc, string.format('%s,', loadID), 1, true)
  end

  local recordedStartFrame = tonumber(string.sub(loadDoc, loadIDEndPos+2, loadIDEndPos+8))
  local endLoadFrame = tonumber(string.sub(loadDoc, loadIDEndPos+11, loadIDEndPos+17))

  if endLoadFrame == 0 or index <= endLoadFrame+1 then  --if load has not ended or input index is during the load; check until endLoadFrame+1 for longer-than-documented loads to reindex
    local addToLoadDoc = string.format('%s, %7.0f', loadID, startLoadFrame)
    loadDoc = string.format('%s%s%s',string.sub(loadDoc, 1, loadIDStartPos-1), addToLoadDoc, string.sub(loadDoc, loadIDStartPos+#addToLoadDoc, -1))
    --messageSend('Wrote to LoadDoc 0', 0x00FFFF)

    if startLoadFrame ~= recordedStartFrame then  --reset loadDoc if previous inputs changed and are currently in the load
      loadDoc = string.format('%s%7.0f%s',string.sub(loadDoc, 1, loadIDEndPos+10), 0, string.sub(loadDoc, loadIDEndPos+18, -1))
      --messageSend('Wrote to LoadDoc 1', 0x00FFFF)
    end

    if index == totalFramesAtIndex + 1 or GetFrameCount() == scriptFirstFrame+1 then  --make the script think it wasn't loading on the frame before this command to prevent ds issues in some situations
      prevLoadInfo[2] = false
    end

    if prevLoadInfo[1] == false and prevLoadInfo[2] == true then  --load end detected
      loadDoc = string.format('%s%7.0f%s',string.sub(loadDoc, 1, loadIDEndPos+10), index-1, string.sub(loadDoc, loadIDEndPos+18, -1))
      --messageSend('Wrote to LoadDoc 2', 0x00FFFF)
      totalFramesAtIndex = totalFramesAtIndex + index - startLoadFrame
    else
      messageSend('Waiting for load to end...', 0xD2691E)
      exitLoop = true
      returnData = {0, totalFramesAtIndex, ''}
    end
    return
  end
  --index > endLoadFrame+1

  if startLoadFrame ~= recordedStartFrame then  --update loadDoc if previous inputs changed and TAS is after the load. Prone to desyncs if load length changes after making an earlier edit and the load is not replayed to reindex its length, so be careful!
    loadDoc = string.format('%s%7.0f%s',string.sub(loadDoc, 1, loadIDEndPos+10), 0, string.sub(loadDoc, loadIDEndPos+18, -1))
    --messageSend('Wrote to LoadDoc 3', 0x00FFFF)
  end
  --insert a blank line of length load
  rawFile = string.format('%s%4.0f\n%s',string.sub(rawFile, 1, endLinePos),endLoadFrame-startLoadFrame+1,string.sub(rawFile, endLinePos, -1))
  if isInMainFile then
    lineNumber = lineNumber - 2
    pauseLineAdvance = 0
  end
end

function doReadManagement()
  local readCommandFileName = string.format('%s%s',root,arg2)
  local loadDocumentationStartPos, loadFileNameEndPos = string.find(loadDoc, string.format('%s,', readCommandFileName), 1, true)
  local startReadFrame = totalFramesAtIndex+1
  if loadDocumentationStartPos == nil then  --if Read file has not been documented yet
    --insert the Read file and a line 'End Read, [file ID]'
    if io.open(readCommandFileName, 'r') ~= nil then  --make sure the file exists
      pauseLineAdvance = 1
      isInMainFile = false
      loadDoc = loadDoc .. string.format('\n%s, %7.0f, %7.0f', readCommandFileName, startReadFrame, 0)
      readCommandFile = io.open(readCommandFileName, 'r')

      local textToImportToFile = string.gsub(tostring(readCommandFile:read('*all')), '%w LoadDoc', '#')  --remove problematic commands. Comment any trailing arguments
      --textToImportToFile = string.gsub(textToImportToFile, 'IndexMode', '#')

      rawFile = string.format('%s%s\nEnd Read, %s%s',string.sub(rawFile, 1, endLinePos),textToImportToFile,readCommandFileName,string.sub(rawFile, endLinePos, -1))


      if index == startReadFrame then 
        lineNumber = lineNumber+1
        heldButtons = ''  --reset some values to avoid desyncs
        tilt = 512
        macroDoc = ''
      end

      readCommandFile:close()
      messageSend(string.format('Read file: %s', readCommandFileName), 0xD2691E)
    else
      messageSend(string.format('File "%s" does not exist!', readCommandFileName), 0xFF0000)
    end
    return
  end
  --if file is already documented in loadDoc
  --messageSend('File is already Documented!', 0x00FF00)
  local recordedStartFrame = tonumber(string.sub(loadDoc, loadFileNameEndPos+2, loadFileNameEndPos+8))
  local addToLoadDoc = string.format('%s, %7.0f', readCommandFileName, startReadFrame)
  loadDoc = string.format('%s%s%s',string.sub(loadDoc, 1, loadDocumentationStartPos-1), addToLoadDoc, string.sub(loadDoc, loadDocumentationStartPos+#addToLoadDoc, -1))

  local endReadFrame = tonumber(string.sub(loadDoc, loadFileNameEndPos+11, loadFileNameEndPos+17))
  if endReadFrame == 0 or index < endReadFrame then  --if End Read has not previously been called or input index is during the read
    pauseLineAdvance = 1
    if index == startReadFrame then
      heldButtons = ''  --reset some values to avoid desyncs
      tilt = 512
      macroDoc = ''
    end
    isInMainFile = false
    if startReadFrame ~= recordedStartFrame then  --update loadDoc if previous inputs changed
      loadDoc = string.format('%s%7.0f%s',string.sub(loadDoc, 1, loadFileNameEndPos+10), startReadFrame-recordedStartFrame+endReadFrame, string.sub(loadDoc, loadFileNameEndPos+18, -1))
    end
    --insert the Read file and a line 'End Read, [file ID]'
    readCommandFile = io.open(readCommandFileName, 'r')

    local textToImportToFile = string.gsub(tostring(readCommandFile:read('*all')), '%w LoadDoc', '#')  --remove problematic commands
    --textToImportToFile = string.gsub(textToImportToFile, 'IndexMode', '#IndexMode')

    rawFile = string.format('%s%s\nEnd Read, %s%s',string.sub(rawFile, 1, endLinePos),textToImportToFile,readCommandFileName,string.sub(rawFile, endLinePos, -1))

    readCommandFile:close()
    messageSend(string.format('Read file: %s', readCommandFileName), 0xD2691E)
    return
  end
  if startReadFrame ~= recordedStartFrame then  --update loadDoc if previous inputs changed
    loadDoc = string.format('%s%7.0f%s',string.sub(loadDoc, 1, loadFileNameEndPos+10), startReadFrame-recordedStartFrame+endReadFrame, string.sub(loadDoc, loadFileNameEndPos+18, -1))
  end
  --insert a blank line of length read
  rawFile = string.format('%s%4.0f\n%s',string.sub(rawFile, 1, endLinePos),endReadFrame-startReadFrame,string.sub(rawFile, endLinePos, -1))
  if isInMainFile then lineNumber = lineNumber - 2 end
end

function openLoadDoc()
  local _, _, docFileName, arg3 = string.find(arg2 .. ',','(.-),%s*(.*)')
  if docFileName == 'SkipOffset' and arg3 == '' then  --if using the default file name and SkipOffset
    docFileName = ''
    arg3 = 'SkipOffset,'
  end
  if docFileName == '' then
    docFileName = string.format('Studio\\LoadDocs\\%s.txt', ReadValueString(0x80D20F04, 99))
  elseif string.sub(docFileName, -4) == '.txt' then
    docFileName = string.format('Studio\\LoadDocs\\%s', docFileName)
  else
    docFileName = string.format('Studio\\LoadDocs\\%s.txt', docFileName)
  end
  if io.open(docFileName, "r") == nil then
    messageSend(string.format('LoadDoc not found! %s', docFileName), 0xFF0000)
    return
  end
  --if docFile exists
  docFile = io.open(docFileName, "r")
  docFile:seek('set', 8)
  if arg3 ~= 'SkipOffset,' then
    offset = docFile:read("*number")
    index = GetFrameCount() - offset
    loadDoc = string.sub(tostring(docFile:read("*all")), 2)
  else  --if SkipOffset is called, adjust the input lines based on the current offset
    local loadDocOffset = docFile:read("*number")
    local newLoadDocText = string.sub(tostring(docFile:read("*all")), 3) .. '/n'
    local pos = 1
    while true do
      local _, _, lineName, startF, endF = string.find(newLoadDocText, '([%s%w%.%%%(%)-]+),%s*(%d+),%s*(%d+)', pos)
      if lineName == nil then
        break
      end
      if string.find(loadDoc, lineName) == nil then
        if endF ~= 0 then
          endF = endF+totalFramesAtIndex
        end
        loadDoc = loadDoc .. string.format('\n%s, %7.0f, %7.0f', lineName, startF+totalFramesAtIndex, endF)
      end
      pos = pos + #lineName + 19
    end
  end
  docFile:close()
  messageSend(string.format('LoadDoc opened successfully! %s', docFileName), 0x00FF00)
end

function fileIsUpdated()
  file:seek('set', 0)
  if lastRawFile ~= tostring(file:read('*all')) then
    messageSend('File updated!', 0x00FF00)
    file:seek('set', 0)
    lastRawFile = tostring(file:read('*all'))
    return true
  else
    return false
  end
end

function searchLookupTable(input)
  if string.find(validLookupOptions, string.format('\n%s\n', input)) == nil then
    if input ~= '' then
      messageSend(string.format('Invalid value lookup: %s', input), 0xFF0000)
      failed = true
    end
    return 0
  end
  if string.find(regionSpecificList, input) ~= nil then
    input = input .. core.game_id_rev().Region
  end

  return lookupTable[input]
end

function convertStringToAddress(rawString)
  local _, _, pt1, pt2, pt3 = string.find(rawString, '(%w+)(%.?%w*)%-?(%w*)')
  local address = -1
  failed = false
  if string.sub(pt1, 1, 2) == '0x' then
    address = pt1
  else
    address = searchLookupTable(pt1)
  end
  if string.sub(pt2, 2, 3) == '0x' then
    address = address + string.sub(pt2,2,-1)
  else
    address = address + searchLookupTable(pt2)
  end
  if string.sub(pt3, 2, 3) == '0x' then
    address = address + string.sub(pt3,2,-1)
  else
    address = address + searchLookupTable(pt3)
  end
  if failed then  --return 0 if any Lookup Table search failed
    return 0
  end
  return address
end
