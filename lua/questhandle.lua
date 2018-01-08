local questArea
local questRoom
local questMob
local questRooms
local lastRoomIndex

--------------------------------------
-- Triggers
--------------------------------------
function qTest()
	qMob("Ddrei Goch")
	qRoom("The Maze of Mirrors")
    qArea("Tir na nOg")
end

function qGoto() 
	lastRoomIndex = 0
	qNext()
end

function qNext()
	if questRooms == nil then
		print ("No rooms have been found, Try typing 'quest info' to see if it is an update problem.")
		return
	end--if

	if #questRooms > lastRoomIndex then
		lastRoomIndex = lastRoomIndex + 1
		Execute('mapper goto '.. questRooms[1].id)
	else
		print ("No more quest rooms.")
	end
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
	areaRooms = getAreaRooms()
	killRooms = getKillRooms()
	
	questRooms = {}
    for i = 1, #areaRooms do
		questRooms[i] = { id = areaRooms[i].roomId, killCount = 0 }

		for k = 1, #killRooms do
			if killRooms[k].roomId == tonumber(areaRooms[i].roomId) then
				questRooms[i].killCount = killRooms[k].timeskilled;
			end
		end	
    end

	table.sort(questRooms, function(left, right) return left.killCount > right.killCount end)
		
	lastRoomIndex = 0

	if #questRooms == 0 then
		print("The specified room cannot be found and is probably not mapped.")
	else
		DebugNote("Best room: " .. questRooms[1].id .. ", Kills: " .. questRooms[1].killCount)
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
			" select room_id  as roomId      " ..
			"      , count(*) as timeskilled " ..     
			"   from mobkills                " ..
			"  where name = %s               " ..
			"  group by room_id              ",
			fixsql(questMob))

		c = 0
		for killRoom in dbKill:nrows(qryKill) do
			c = c+1
			DebugNote("Kill room: " .. killRoom.roomId .. ", Kills: " .. killRoom.timeskilled)
			killRooms[c] = killRoom
		end

		dbKill:close()
	end

	return killRooms
end