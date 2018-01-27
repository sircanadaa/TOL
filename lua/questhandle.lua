--------------------------------------
-- Declaration
--------------------------------------

-- Class
local CQuestHandler = {}
CQuestHandler.__index = CQuestHandler

-- Private functions
local validateRooms
local validateIndex
local getQuestRooms
local getAreaRooms
local getKillRooms
local calcQuestRoomDistances
local sortQuestRooms
local printQuestRooms

--------------------------------------
-- Public methods
--------------------------------------

-- Factory, creates a new quest handler.
function CQuestHandler.create()
    local instance = {}
    setmetatable(instance, CQuestHandler)
    instance:clear()
    return instance
end

-- Clears the quest object
function CQuestHandler:clear()
    self.area = nil
    self.room = nil
    self.mob = nil
    self.rooms = {}
    self.lastRoomIndex = 0
end

-- Set the target area name
function CQuestHandler:setArea(area)
    DebugNote("Quest area: " .. area)
    self.area = area
    getQuestRooms(self)
end

-- Set the target room name
function CQuestHandler:setRoom(room)
    DebugNote("Quest room: " .. room)
    self.room = room
end

-- Set the target mob
function CQuestHandler:setMob(mob)
    DebugNote("Quest mob: ".. mob)
    self.mob = mob
end

-- Moves to the quest room with the highest score.
function CQuestHandler:gotoFirst()
    self.lastRoomIndex = 0
    self:gotoNext()
end

-- Moves to the quest room with a given index
function CQuestHandler:gotoIndex(idx)
    if not validateIndex(self.rooms, idx) then return end

    self.lastRoomIndex = idx
    Execute('mapper goto '.. self.rooms[self.lastRoomIndex].id)
end

-- Moves to the next quest room.
function CQuestHandler:gotoNext()
    if not validateRooms(self.rooms) then return end
    if not self:hasMoreRooms() then
        print ("No more quest rooms.")
        return
    end

    self.lastRoomIndex = self.lastRoomIndex + 1
    Execute("xmapper1 move " .. self.rooms[self.lastRoomIndex].id)
end

-- Returns true if there are more quest rooms to visit and gotoNext should work.
function CQuestHandler:hasMoreRooms()
    if self.rooms == nil then return false end
    if #self.rooms <= self.lastRoomIndex then return false end
    return true
end

-- Prints out rooms.
function CQuestHandler:showRooms(all)
    calcQuestRoomDistances(self.rooms)
    printQuestRooms(self, all or false)
end

-- Function for testing test
function CQuestHandler:Test()
    self:setMob("the Liavango Despot")
    self:setRoom("Home of the Despot")
    self:setArea("The Darkside of the Fractured Lands")
end

--------------------------------------
-- Local (Private) Functions
--------------------------------------
function validateRooms(rooms)
    if #rooms == 0 then
        print("No rooms have been found, Try typing 'quest info' to see if it is an update problem.")
        return false
    end

    return true
end

function validateIndex(rooms, idx)
    if not validateRooms(rooms) then return false end

    if idx == nil then
        print("And index must be provided")
        return false
    end

    if idx > #rooms then
        print ("No quest room with that index")
        return false
    end

    return true
end

function getQuestRooms(qHandler)
    local areaRooms = getAreaRooms(qHandler)
    local killRooms = getKillRooms(qHandler)

    qHandler.rooms = {}
    qHandler.lastRoomIndex = 0

    local questRooms = qHandler.rooms

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

    calcQuestRoomDistances(questRooms)
    sortQuestRooms(questRooms);
    printQuestRooms(qHandler, false)

    if #questRooms == 0 then
        print("The specified room cannot be found and is probably not mapped.")
    else
        DebugNote("Best room: " .. questRooms[1].id .. ", Kills: " .. questRooms[1].kills)
    end
end

-- Gets all know rooms from the map database based on area and room name.
function getAreaRooms(qHandler)
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
            fixsql(qHandler.area), fixsql(qHandler.room))

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
function getKillRooms(qHandler)
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
            fixsql(qHandler.mob), fixsql(qHandler.mob))

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

function calcQuestRoomDistances(questRooms)
    local currRoomId = currentRoom.roomid or "32418" -- Recall

    for i, questRoom in pairs(questRooms) do
        local path, distance = findpath(currRoomId, questRoom.id)

        if (distance ~= nil) then
            questRoom.distance = tonumber(distance)
        end
    end
end

function sortQuestRooms(questRooms)
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

function printQuestRooms(qHandler, all)
    ColourNote("Gray", "", "NUM  Room name                              UID   Kills  Dist  SpeedWalk")
    ColourNote("Gray", "", "------------------------------------------------------------------------");

    local maxLines = #qHandler.rooms
    if not all and maxLines > 7 then maxLines = 5 end

    for i=1, maxLines do
        room = qHandler.rooms[i]

        if room.distance ~= nil then
            local line = string.format("%3d  %-35s  (%5d) %5d  %4d", i, qHandler.room, room.id, room.kills, room.distance)

            Hyperlink("tq " .. i, line, "Goto room (" .. room.id .. ")", "darkorange", "black", 0)
            Hyperlink("mapper where " .. room.id, "   to room", "Show SpeedWalk", "lightgreen", "black", 0)
        else
            local line = string.format("%3d  %-35s  (%5s) %5d", i, qHandler.room, room.id, room.kills)
            Hyperlink("tq " .. i, line, "Goto area (" .. qHandler.area .. ")", "moccasin", "black", 0)
        end

        print("")
    end

    if #qHandler.rooms > maxLines then
        Hyperlink("rq all", "     To show all " .. #qHandler.rooms .. " rooms, type 'rq all'", "", "cornflowerblue", "black", 0)
        print("")
    end

    ColourNote("Gray", "", "------------------------------------------------------------------------");
    Send("")
end

return CQuestHandler
