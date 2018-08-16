require "serialize"
require "tprint"
whereTable = {}
count = 1
local curArea = ""
local stall = false
local Debug = false
function toggleTimer()
    if GetTimerOption('mapSend', 'enabled') == 1 then
        EnableTimer("mapSend", 0)
        print('disabled')
    else
        EnableTimer("mapSend", 1)
        print('enabled')
    end
end
function killswho()
    EnableTriggerGroup("swho", false)
    DoAfterSpecial(1, "show_whwin()", 12)
    
end
swhoTable = {}
function swhoGrab(name, line, wildcards)
    -- print (wildcards[3])
    str = string.gsub(wildcards[3], "[%%%]%^%-$().<>*:[*+?]", "")
    -- print (str)
    str = "["..wildcards[1] .. "] ["..wildcards[2] .. "] " .. str
    -- print (str)
    table.insert(swhoTable, wildcards[0])
end
function getmemoryusage1()
    collectgarbage('collect')
    return collectgarbage('count')
end
function sendWhere1()
    local iStatus
    local almatch
    local alresponse
    local alflags
    local alscriptname
    iStatus, almatch, alresponse, alflags, alscriptname = GetAlias ("where1")
    DebugNote(alflags)
    if alflags ~= 0 then
        do_Execute_no_echo('where1')
    else
        EnableAlias("where1", 1)
    end
end
function stallScript()
    stall = true
    DebugNote("Stall is : " .. tostring(stall))
end
function allowScript()
    --DoAfterSpecial(1,'setStallF()', 12)
    setStallF()
    DebugNote("allow script")
    --print('timer reset')
    ResetTimer("whtime")
    sendWhere1()
end
function setStallF()
    stall = false
    DebugNote("Stall is : " .. tostring(stall))
end
function CurAreaminwin(name, line, wildcards)
    curArea = wildcards[1]
    DebugNote (curArea)
end
function whereGrabber(name, line, wildcards)
    wild1 = string.lower(wildcards[1])
    DebugNote (wild1)
    ---DebugNote(wildcards[2].." ".. #wildcards[2])
    if wild1 == "you" or wild1 == "your" or wild1 == "the" or wild1 == "name" then killScript() return end
    --if #wildcards[2] > 40 then killScript() return end
    -- DebugNote (wildcards[0])
    whereTable[count] = {wildcards[1], wildcards[2]}
    
    count = count + 1
    EnableTrigger("KillSomething", 1)-- testing on
end
function stopGrabbing(name, line, wildcards)
    -- DebugNote(wildcards[0].. " stopGrabbing part")
    DebugNote("stopGrabbing")
    DebugNote(whereTable)
    killScript()
    EnableTriggerGroup('swho', 1)
    do_Execute_no_echo('swho 12 area')
    if whereTable == nil then return end
    
    
end
function DebugNote(msg)
    if not Debug then return end
    if type(msg) == 'table' then
        tprint(msg)
    else
        Note (msg)
    end
    
end
function killScript()
    EnableTrigger("DoSomething", 0)
    EnableTrigger("KillSomething", 0)
    EnableTrigger("whereStarter", 0)
    EnableTrigger("CurAreaminwin", 0)
    EnableTriggerGroup("gag_where", 0)
    setStallF()
    EnableAlias("where1", 1)
end
function whereStarter()
    EnableTrigger("DoSomething", 1)
end
function startTheScript(name, line, wildcards)
    DebugNote(name)
    if stall then DebugNote("reurtning becuase stall was true") return end
    whereTable = {}
    swhoTable = {}
    count = 1
    stallScript()
    DebugNote(os.date("%c"))
    SendNoEcho('where')
    --print('where sent from startTheScript')
    EnableTrigger("whereStarter", 1)
    EnableTrigger("CurAreaminwin", 1)
    EnableTimer("whtime", 1)
    EnableTriggerGroup("gag_where", 1)
    EnableAlias("where1", 0)
    -- DoAfterSpecial(.2 ,'stopGrabbing()', 12)  ---testing off
end
function do_Execute_no_echo(command)
    local original_echo_setting = GetOption("display_my_input")
    SetOption("display_my_input", 0)
    Execute(command)
    SetOption("display_my_input", original_echo_setting)
end
dofile (GetPluginInfo (GetPluginID (), 20) .. "luapath.lua")
-- require 'var'
-- require "commas"
require 'miniwin'
require 'pluginhelper'
-- require 'ldplugin'
-- require 'aardutils'
-- require 'verify'
whwin = Miniwin:new{name = "Where Saver"}
whwin:set_default('windowpos', 1) -- if it breaks this used to be 7
whwin:add_setting("time_colour", {help = "the colour for the time", type = "colour", default = verify_colour(0xD670DA), sortlev = 1})
whwin:add_setting("mobdead_colour", {help = "the colour for when a mob is dead", type = "colour", default = verify_colour("red"), sortlev = 1})
whwin:add_setting("mobnotfound", {help = "the colour for when a mob is not in kill table db", type = "colour", default = verify_colour("green"), sortlev = 1})
whwin:add_setting("notlevel_colour", {help = "the colour for when this cp is no longer from this level", type = "colour", default = verify_colour("cyan"), sortlev = 1})
--whwin:disable()
--fid=whwin:addfont("Dina",8)
--print (fid)
--whwin:setdefaultfont()
cpmobs = {}
cptimer = {}
level = nil
curlevel = nil
showwhwin = false
function set_show()
    showwhwin = true
end
function show_whwin ()
    background_colour = 0xE7FFFF
    win = GetPluginID ()
    if #whereTable == 0 or #swhoTable == 0 then return end
    local texttable = {}
    local header = {}
    local style = {}
    local tmptbl = {}
    style = {}
    if curArea == nil then
        print ("cur area == nil")
    end
    font_id = "fn"
    
    font_name = "Dina" -- the actual font
    
    -- make window so I can grab the font info
    check (WindowCreate (win,
        0, 0, 1, 1,
        1, -- irrelevant
        0,
    background_colour))
    check (WindowFont (win, font_id, font_name, 8, false, false, false, false, 0, 0)) -- normal
    font_height = WindowFontInfo (win, font_id, 1) -- height
    style.text = string.format("Area: %s", curArea)
    style.font_name = font_name
    table.insert (header, {style})
    --DebugNote(whereTable)
    for i, v in ipairs (whereTable) do
        DebugNote ('whereTable iteration '..i.." value: " .. v[1])
        style = {}
        style.font_name = font_name
        --style.text = string.format("%-12s   %s", q,   v[2])
        
        
        style.textcolour = "time_colour"
        if v[2] == "???" then
            style.textcolour = "mobdead_colour"
        end
        -- table.insert (texttable, {style})
        
        for p, q in ipairs(swhoTable) do
            DebugNote ('swhoTable iteration '..p.." value: " .. q)
            if v[1] ~= nil then
                if string.find(q, v[1]) then
                    --style = {}
                    style.text = string.format("%-12s   %s", q, v[2])
                    bool, ind = has_value(swhoTable, q)
                    if bool then table.remove(swhoTable, ind) end -- This is teh remove for the tmptbly
                    if string.find(q, "(OPK)") then
                        style.textcolour = "mobdead_colour"
                    else
                        style.textcolour = "mobnotfound"
                    end --if else
                    style.font_name = font_name
                    table.insert(texttable, {style})
                end-- if
            end-- if
        end --for
    end -- for
    for i, p in ipairs(swhoTable) do
        style = {}
        style.text = p
        style.font_name = font_name
        if string.find(p, "(OPK)") then
            style.textcolour = "mobdead_colour"
        else
            style.textcolour = "mobnotfound"
        end
        table.insert(texttable, {style})
    end
    --tprint(texttable)
    whwin:enable()
    whwin:addtab('default', texttable, header, true)
    
    whwin:show(true)
    
    
    whwin:changetotab('default')
    style = {}
    style.text = " Area: " .. curArea
    whwin:tabbroadcast(true, {style})
end
function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true, index
        end
    end
    return false
end
local runningFlag = 3
local curZone
local lastZone
function OnPluginBroadcast (msg, id, name, text)
    if text == 'ok_you_can_go_now' then
        allowScript()
    end
    if text == 'kinda_busy' then
        
      stallScript()
    end
    if (text == "char.status") then
        res, gmcparg = CallPlugin("3e7dedbe37e44942dd46d264", "gmcpval", "char.status")
        luastmt = "gmcpdata = " .. gmcparg
        assert (loadstring (luastmt or "")) ()
        runningFlag = tonumber(gmcpdata.state)
        -- print("Changing the flag to: ".. runningFlag)
        if runningFlag ~= 3 and runningFlag ~= 8 then
            stallScript()
            
            fileName = 'WhereCheck'
            -- file = io.open(fileName, "w+")
            -- file:write(runningFlag)
            -- file:close()
        else
            setStallF()
            
        end
    end
    if (text == "room.info") then
        res, gmcparg = CallPlugin("3e7dedbe37e44942dd46d264", "gmcpval", "room.info")
        luastmt = "gmcpdata = " .. gmcparg
        assert (loadstring (luastmt or "")) ()
        curZone = gmcpdata.zone
        DebugNote(lastZone)
        DebugNote(curZone)
        if runningFlag ~= 3 or stall then return end
        if lastZone == nil then lastZone = -1 end
        if lastZone ~= curZone and not stall then
            lastZone = curZone
            DebugNote("OPB room.info")
            DebugNote('area update')
            sendWhere1()
            
        end
        DebugNote(lastZone)
        DebugNote(curZone)
    end
end
function OnPluginInstall ()
    --OnPluginEnable is automatically called by pluginhelper
    phelper:OnPluginInstall()
end -- OnPluginInstall
function OnPluginClose()
    phelper:OnPluginClose()
end -- OnPluginClose
function OnPluginEnable ()
    
    phelper:OnPluginEnable()
    
end -- OnPluginEnable
function OnPluginDisable ()
    phelper:OnPluginDisable()
end -- OnPluginDisable
function OnPluginConnect ()
    phelper:OnPluginConnect()
end -- OnPluginConnect
function OnPluginDisconnect ()
    phelper:OnPluginDisconnect()
end
-- function OnPluginConnect
--function OnPluginSaveState ()
--phelper:OnPluginSaveState()
--end -- function OnPluginSaveState
