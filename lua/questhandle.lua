local questArea
local questRoom
local questMob
local questRooms = {}
local lastRoomIndex = 0

--------------------------------------
-- Triggers
--------------------------------------
function qTest()
    qMob("the Liavango Despot")
    qRoom("Home of the Despot")
    qArea("The Darkside of the Fractured Lands")
end

function qGoto()
    lastRoomIndex = 0
    qNext()
end

function qGotoIndex(name, line, wildcards)
    local idx = tonumber(wildcards[1])
    if idx == nil then return end

    if questRooms == nil then
        print ("No rooms have been found, Try typing 'quest info' to see if it is an update problem.")
        return
    end

    if #questRooms >= idx then
        lastRoomIndex = idx
        Execute('mapper goto '.. questRooms[lastRoomIndex].id)
    else
        print ("No quest room with that index")
    end
end

function qNext()
    mobname = sanitizeName(questMob)

    if questRooms == nil then
        print ("No rooms have been found, Try typing 'quest info' to see if it is an update problem.")
        return
    end

    if #questRooms > lastRoomIndex then
        lastRoomIndex = lastRoomIndex + 1
        Execute("xmapper1 move " .. questRooms[lastRoomIndex].id)
    else
        print ("No more quest rooms.")
    end
end

function qRooms()
    calcQuestRoomsDistance()
    printQuestRooms(false)
end

function qRoomsAll()
    calcQuestRoomsDistance()
    printQuestRooms(true)
end

--------------------------------------
-- Functions
--------------------------------------
function qArea(area)
    DebugNote("Quest area: " .. area)
    questArea = area
    getQuestRooms()
end

function qRoom(room)
    DebugNote("Quest room: " .. room)
    questRoom = room
end

function qMob(mob)
    DebugNote("Quest mob: ".. mob)
    questMob = mob
end

function getQuestRooms()
    local areaRooms = getAreaRooms()
    local killRooms = getKillRooms()

    questRooms = {}
    DebugNote(areaRooms)
    for i = 1, #areaRooms do
        local areaRoomId = areaRooms[i].roomId
        local questRoom = { id = areaRoomId, kills = 0 }

        for k = 1, #killRooms do
            if tostring(killRooms[k].roomId) == areaRoomId then
                questRoom.kills = killRooms[k].kills;
            end
        end
        questRooms[i] = questRoom
    end

    calcQuestRoomsDistance()
    sortQuestRooms();

    lastRoomIndex = 0

    printQuestRooms(false)

    if #questRooms == 0 then
        print("The specified room cannot be found and is probably not mapped.")
    else
        DebugNote("Best room: " .. questRooms[1].id .. ", Kills: " .. questRooms[1].kills)
    end
end

-- Gets all know rooms from the map database based on area and room name.
function getAreaRooms()
    areaRooms = {}

    dbArea = sqlite3.open(GetInfo (66) ..'Aardwolf.db')
    DebugNote("Aardwolf.db is open: " .. tostring(dbArea:isopen()))

    if dbArea:isopen() then
        qryArea = string.format(
            " select r.uid  as roomId   " ..
            "   from rooms r            " ..
            "   join areas a            " ..
            "     on a.uid = r.area     " ..
            "  where a.name = %s        " ..
            "    and r.name = %s        ",
            fixsql(questArea), fixsql(questRoom))

        c = 0
        for areaRoom in dbArea:nrows(qryArea) do
            c = c+1
            DebugNote("Area room: " .. areaRoom.roomId)
            areaRooms[c] = areaRoom
        end

        dbArea:close()
    end

    return areaRooms
end

-- Gets all rooms from the kill database that the specific mob has been killed in.
function getKillRooms()
    killRooms = {}

    local dbKill = sqlite3.open(GetPluginInfo (GetPluginID (), 20) .. 'KillTable.db')
    DebugNote("KillTable.db is open: " .. tostring(dbKill:isopen()))

    if dbKill:isopen() then
        qryKill = string.format(
            " select room_id  as roomId " ..
            "      , count(*) as kills  " ..
            "   from mobkills           " ..
            "  where name = %s          " ..
            "  group by room_id         " ..
            "  union                    " ..
            " select room_id  as roomId " ..
            "      , count(*) as kills  " ..
            "   from cpmobs             " ..
            "  where name = %s          " ..
            "  group by room_id         " .. 
            "  order by kills           ",
            fixsql(questMob), fixsql(questMob))

        c = 0
        for killRoom in dbKill:nrows(qryKill) do
            c = c+1
            DebugNote("Kill room: " .. killRoom.roomId .. ", Kills: " .. killRoom.kills)
            killRooms[c] = killRoom
        end
        DebugNote(killRooms)
        dbKill:close()
    end

    return killRooms
end

function calcQuestRoomsDistance()
    local currRoomId = currentRoom.roomid

    if currRoomId == nil or currRoomId == '-1' then
        currRoomId = "32418" -- Recall
    end

    for i = 1, #questRooms do
        local path, distance = findpath(currRoomId, questRooms[i].id)

        if (distance ~= nil) then
            questRooms[i].distance = tonumber(distance)
        end
    end
end

function sortQuestRooms()
    table.sort(questRooms,
        function(left, right)
            if left.distance == nil and right.distance == nil then
                return left.kills > right.kills
            elseif left.distance == nil and right.distance ~= nil then
                return false
            elseif left.distance ~= nil and right.distance == nil then
                return true
            elseif left.kills == right.kills then
                return left.distance < right.distance
            else
                return left.kills > right.kills
            end
        end)
end

function printQuestRooms(all)
    ColourNote("Gray", "", "NUM  Room name                              UID   Kills  Dist  SpeedWalk")
    ColourNote("Gray", "", "------------------------------------------------------------------------");

    local maxLines = #questRooms
    if not all and maxLines > 7 then maxLines = 5 end

    for i = 1, maxLines do
        local room = questRooms[i]

        if room.distance ~= nil then
            local line = string.format("%3d  %-35s  (%5d) %5d  %4d", i, questRoom, room.id, room.kills, room.distance)

            Hyperlink("tq " .. i, line, "Goto room (" .. room.id .. ")", "darkorange", "black", 0)
            Hyperlink("mapper where " .. room.id, "   to room", "Show SpeedWalk", "lightgreen", "black", 0)
        else
            local line = string.format("%3d  %-35s  (%5s) %5d", i, questRoom, room.id, room.kills)
            Hyperlink("tq " .. i, line, "Goto area (" .. questArea .. ")", "moccasin", "black", 0)
        end

        print("")
    end

    if #questRooms > maxLines then
        Hyperlink("rq all", "     To show all " .. #questRooms .. " rooms, type 'rq all'", "", "cornflowerblue", "black", 0)
        print("")
    end

    ColourNote("Gray", "", "------------------------------------------------------------------------");
    Send("")
end
