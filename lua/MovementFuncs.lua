local xrun_to_sql1 =  
    "SELECT r.uid, r.name as room, a.name as area " ..
    "FROM rooms r " ..
    "INNER JOIN areas a ON a.uid = r.area " ..
    "WHERE a.uid like %s " ..
    "ORDER BY r.uid "
    
  local xrun_to_sql2 =  
    "SELECT r.uid, r.name as room, a.name as area " ..
    "FROM rooms r " ..
    "INNER JOIN areas a ON a.uid = r.area " ..
    "WHERE a.uid like %s " ..
    "OR a.name like %s " ..
    "ORDER BY r.uid "

    local xrun_to_sql_FR = 
      " SELECT b.uid, b.notes "..
      " FROM bookmarks b "..
      " INNER JOIN rooms r on r.uid = b.uid "..
      " WHERE r.area like %s " ..
      " AND b.notes = 'Tstart' "

  function xrun_to1(name, line, wildcards)
    local index1 = 1
    local worldPath = GetInfo(66)..Trim(sanitize_filename(WorldName()))
    local db = assert(sqlite3.open(worldPath .. ".db"))
    db:busy_handler(myHandler)

    -- HACK for ftii
    if (wildcards[1] == "ft2") then
      wildcards[1] = "ftii"
    end
    local like = fixsql("%" .. wildcards[1] .. "%")
    -- try exact hit first
    local select1 = string.format (xrun_to_sql1, fixsql(wildcards[1]))
    DebugNote("xrun_to (1)- " .. select1)
    local select2 = string.format (xrun_to_sql_FR, like)
    DebugNote("xrun_to (1)- " .. select2)
    for row in db:nrows(select2) do 
      DebugNote(row)
      goto_roomid(row.uid)
      index1 = index1 +1
      db:close()
      return
    end
    
    --Note(string.format (sql, fixsql(wildcards[1])))
    for row in db:nrows(select1) do

      ColourNote("darkorange", "", "x-runto (" .. row.uid .. ") " .. row.room .. " in " .. row.area)
      goto_roomid(row.uid)
      
      index1 = index1 + 1
      db:close()
      return
    end
    

    
    select1 = string.format (xrun_to_sql2, like, like)
    DebugNote("xrun_to (2)- " .. select1)

    for row in db:nrows(select1) do
      ColourNote("darkorange", "", "x-runto (" .. row.uid .. ") " .. row.room .. " in " .. row.area)
      goto_roomid(row.uid)
      
      index1 = index1 + 1
      db:close()
      return
    end

    if (index1 == 1) then

      ColourNote("darkorange", "", "No matching rooms found. Using aardwolf runto...")
      Execute("xmapper1 move 32418") -- recall
      Execute("runto " .. wildcards[1])
    end
    db:close()
  end

  function goto_roomid(roomid)
      Execute("xmapper1 move " .. roomid)
  end
  local execute_in_area_array = {}

  function execute_in_area(id, areaId, functionPointer)

    execute_in_area_array[id] = { 
      areaId = areaId, 
      func = functionPointer, 
      index = 0, 
      active = true,
      lastState = 3, -- standing
      standIndex = 0 -- count of stands in a row
      }
    EnableTimer("execute_in_area_timer", true)

  end

  function execute_in_area_tick(name, line, wildcards)
    local localRoom = currentRoom
    local localState
    if (localRoom == nil) then
      return
    end
    
    if (char_status == nill) then
      return
    else
      localState = tonumber(char_status.state)
    end

    local isActive = false
    for index, value in pairs(execute_in_area_array) do
      if (value.active == true) then
    
        value.index = value.index + 1

        if (value.index > 100) then
          value.active = false
          print("** aborting quickwhere timer for " .. index1 .. ", took too long to get to destination")
          
        else


          if ((localState == 3 and value.lastState == 3) 
            and value.areaId == localRoom.areaid) then

            -- skip first timer tick
            value.index = value.index + 1
            value.standIndex = value.standIndex + 1
            if (value.standIndex < 2) then
            else
              value.func()
              value.active = false            
            end
          else
            -- still moving.. reset index
            value.standIndex = 0
          end
        end
      end
      
      value.lastState = localState
      
      if (value.active == true) then
        isActive = true
      end
      
    end
    
    -- no timer items active.. disable
    if (isActive == false) then
      --DebugNote("disable timer")
      EnableTimer("execute_in_area_timer", false)
    end
  end

  local speed = "run"
    function move_trigger(name, line, wildcards)
    
    if (wildcards.roomid ~= "") then
      move(wildcards.roomid, wildcards.speed)
    end
    
  end
  
  function move(roomid, temp_speed)
  
    if (temp_speed == nil or temp_speed == "") then
      temp_speed = speed
    end
    if (temp_speed == "walk") then
      Note("walking to " .. roomid)
      Execute("mapper walkto " .. roomid)
    else
      Execute("mapper goto " .. roomid)
    end
  end
  function sanitize_filename(str)
    str = string.gsub(str, "[^%w%s()_-]", "")
    return str
  end