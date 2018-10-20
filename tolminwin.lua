internalrevision = "$Rev$"
dofile (GetPluginInfo (GetPluginID (), 20) .. "luapath.lua")
require 'var'
require "commas"
require 'miniwin'
require 'tprint'
require 'pluginhelper'
require 'ldplugin'
require 'aardutils'
require 'verify'
cpwin = Miniwin:new{name = "TOL"}
cpwin:set_default('windowpos', 7)
cpwin:add_setting("time_colour", {help = "the colour for the time", type = "colour", default = verify_colour(0xD670DA), sortlev = 1})
cpwin:add_setting("mobdead_colour", {help = "the colour for when a mob is dead", type = "colour", default = verify_colour("red"), sortlev = 1})
cpwin:add_setting("mobnotfound", {help = "the colour for when a mob is not in kill table db", type = "colour", default = verify_colour("green"), sortlev = 1})
cpwin:add_setting("notlevel_colour", {help = "the colour for when this cp is no longer from this level", type = "colour", default = verify_colour("cyan"), sortlev = 1})
--cpwin:disable()
cpmobs = {}
cptimer = {}
level = nil
curlevel = nil
showcpwin = true
cur_action = ''
level = 0
function getmemoryusage()
    collectgarbage('collect')
    return collectgarbage('count')
end
function set_show()
    showcpwin = true
end

function cp_info_handle()
    Send('cp info')
    EnableTrigger('catch_cp_info', 1)
end
function kill_catch_cp_info()
    EnableTrigger('catch_cp_info', 0)
end

function catch_cp_info(name, line, wildcards)
    str = wildcards[1]
    if str == "Use 'cp check' to see only targets that you still need to kill." then
        EnableTrigger('catch_cp_info', 0)
    elseif str =="You are not currently on a campaign." then
        EnableTrigger('catch_cp_info', 0)
    end
    if string.find(str, 'Level Taken') then 
        level = tonumber(string.sub(str, string.find(str, '%d+')))
    end
    show_cp_text()
end

function show_cp_text ()
    local texttable = {}
    local header = {}
    local style = {}
    -- do nothing if no campaign
    -- if #cpmobs == 0 then
    --     cpwin:show(false)
    --     return
    -- end -- if
    -- heading nomap_Past the Northern Gate_amazonclan
    style = {}
    style.text = string.format("LT: %-3s Campaign mobs left: %-5s Action : %-49s",level, #cpmobs, cur_action)
    table.insert (header, {style})
    style = {}
    style.text = ("indx  Name                               #    Area                           Dist")
    style.textcolour = "Gray"
    table.insert (texttable, {style})
    -- list of mobs
    for i, v in ipairs (cpmobs) do
        style = {}
        if v.dist == nil then v.dist = 0 end
        if v.num == nil then v.num = 1 end
        if i < 10 then
            style.text = string.format(i.." : %-35s  %s", v.name, string.format("%-35s %3d", v.num.." :" .. " (" .. v.location .. ")", tonumber(v.dist)))
        else
            style.text = string.format(i..": %-35s  %s", v.name, string.format("%-35s %3d", v.num.." :" .. " (" .. v.location .. ")", tonumber(v.dist)))
        end
        if verify_bool(v.mobdead) then
            -- print ("in the if block for v.mobdead")
            -- print ("v.mobdead")
            -- print (tostring(v.mobdead))
            -- print ("v.intable")
            -- print (tostring(v.intable))
            -- print ("")
            style.textcolour = "mobdead_colour"
        end
        if not verify_bool(v.intable) and v.intable ~= nil then
            -- print ("in the if block for v.intable")
            -- print ("v.mobdead")
            -- print (tostring(v.mobdead))
            -- print ("v.intable")
            -- print (tostring(v.intable))
            -- print ("")
            style.textcolour = "green"
        end
        table.insert (texttable, {style})
        --tprint (texttable)
    end -- for
    
    cpwin:enable()
    cpwin:addtab('default', texttable, header, true)
    
    cpwin:show(true)
    
    
    --cpwin:changetotab('default')
    style = {}
    style.text = " CP: " .. #cpmobs
    cpwin:tabbroadcast(true, {style})
end -- show_cp_text
function OnPluginBroadcast (msg, id, name, text)
    if id == "8065ca1ba19b529aee53ee44" then
        if msg == 1 then
            local pvar = GetPluginVariable("8065ca1ba19b529aee53ee44", "cp_mobs")
            -- get the mobs
            loadstring(pvar)()
            cpmobs = cp_mobs
            
            show_cp_text()
        elseif msg == 2 then
            --local pvar = GetPluginVariable("8065ca1ba19b529aee53ee44", "action")
            -- get the timer
            --loadstring(pvar)()
            cur_action = text
            if cur_action == 'update level' then
                cp_info_handle()
            end
            show_cp_text()
        elseif msg == 3 or msg == 4 then
            
            cptimer = {}
            cpmobs = {}
            -- cpwin:disable()
        end
        
    end
    phelper:OnPluginBroadcast(msg, id, name, text)
end
function OnPluginInstall ()
    --OnPluginEnable is automatically called by pluginhelper
    phelper:OnPluginInstall()
            show_cp_text()

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
end -- function OnPluginConnect
function OnPluginSaveState ()
    phelper:OnPluginSaveState()
end -- function OnPluginSaveState
