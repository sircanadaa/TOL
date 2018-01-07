local curRoom
local curArea
local curName
function qArea( area)
	-- print (area)
	curArea = area
	--Execute ('rt '.. area)
	--Qwhere()
	 getRoomIdAreaQuest()
end
function qRoom(room)
	curRoom = room
	-- print (room)
  
	--Execute('mapper find "'.. room..'"' )
	--Execute('mapper next')
end

function Qwhere()
  if curRoom ~= nil then
    Execute('mapper area ' .. curRoom)
    Execute('mapper next')
  else
  	Execute ('where')
  	EnableTrigger("questTest", true)
  end--if
end

function QWhereret(name, line, wildcards)
    if wildcards[2] ~= curArea then
    	Execute("mapper next")
	end --if
 	Execute ('mapper area "'.. curRoom.. '"')
 	--print ("here")
	Execute ('mapper next')
	EnableTrigger("questTest", false)
end
local Qroom
local nameHolder
function qName(name)
	nameHolder = name
	-- print (curName)
end

local roomTemp

function getRoomIdAreaQuest()
  print (curArea)
  print (curRoom)
  print (nameHolder)
--local nameHolder= nil
local loc = curArea
    dbA=sqlite3.open(GetInfo (66) ..'Aardwolf.db')
      DebugNote (dbA:isopen())
      if dbA:isopen() then
        query1 = string.format("select rooms.uid as uid,rooms.name as Rname, areas.name as areaName "..
          "from rooms, areas "..
          "where areas.uid = rooms.area and Rname = %s ",fixsql(curRoom))
        DebugNote (loc)
        for rows in dbA:nrows(query1) do
          DebugNote(rows)

          DebugNote (string.lower(loc) == string.lower(rows.areaName))
          if loc == rows.areaName then
            Qroom = rows.uid
          end--if
        end -- for
      end--if
    dbA:close()
    print (Qroom)
end

function gotoQuest()
  DebugNote(curArea)
  
  if curArea== nil and nameHolder == nil then
    print ('Try typing quest info to see if it is an update problem.')
    return
  end--if
  if Qroom ~= nil  then
    Execute('mapper goto '.. Qroom)
    curName = nameHolder

  end--if
  
end
