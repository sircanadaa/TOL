function lookup(name1, line, wildcards)--Looks up mobs from the CPmobs database based off of name, level, area, or room
  local modifiers = {'name', 'level', 'area', 'room'}
  local ptr = 0
  local ptrkeep = 1
  local mobbuff ={}
  local decideQ = 0
  local level = 0
  local modanddata = {}
  for i, p in pairs (modifiers) do
    local x, a = 0
   a,x = string.find(wildcards[1], p.." ")
    if a ~= nil and x ~= nil then 
      
        
        tmp = string.sub (wildcards[1], x)
        ptr = string.len(tmp)
        for j, k in pairs(modifiers) do
          y, w = string.find(tmp, k.." ")
          if y~= nil and y< ptr then
            -- print (y)
            ptr = y -2
          end
        end
        modanddata[i] = string.sub(tmp, 2, ptr)
        prt = 1
      if x ~= nil and x > ptr then 
        ptr = x 
      end
       ptr = 0
    else 
      modanddata [i] = -1
    end
  end
  -- modanddata will always be in the form 1 = name, 2 = level, 3 = area, 4 = room
  local name =""
  local levela = 0
  local levelb = 0
  local room = ""
  local area = ""
  if modanddata[1] ~= -1 then --name
   name = modanddata[1] 
   decideQ = decideQ +1
  end
  if modanddata[2] ~= -1  then --level
    if tonumber(modanddata[2]) == nil then
      print ("Level needs to be a number")
      return
    end
   levela = tonumber(modanddata[2]) +11 
   levelb = tonumber(modanddata[2]) -11
   decideQ = decideQ + 9
  end
  if modanddata[3] ~= -1  then area = modanddata[3] decideQ = decideQ +12 end -- area
  if modanddata[4] ~= -1  then room = modanddata[4] decideQ = decideQ +15 end -- room
  --print (decideQ)
  if decideQ == 0 then print('Nothing found try something else or check your usage') return end
  if decideQ == 1 then -- name or default
    query = string.format("SELECT * from CPMobs where name like %s", fixsql(name))
  elseif decideQ == 9 then-- level only
    query = string.format("SELECT * from CPMobs where level <= %d and level >= %d", levela, levelb)
  elseif decideQ == 12 then -- area only
    query = string.format("SELECT * from CPMobs where area_name like %s", fixsql(area))
  elseif decideQ == 15 then -- room only
    query = string.format("SELECT * from CPMobs where room_name like %s", fixsql(room))
  elseif decideQ == 10 then -- name and level
    query = string.format("SELECT * from CPMobs where name like %s and level <= %d and level >= %d", fixsql(name), levela, levelb)
  elseif decideQ == 13 then -- name and area
    query = string.format("SELECT * from CPMobs where name like %s and area_name like %s", fixsql(name), fixsql(area))
  elseif decideQ == 16 then -- name and room
    query = string.format("SELECT * from CPMobs where name like %s and room_name like %s", fixsql(name), fixsql(room))
  elseif decideQ == 21 then -- level and area
    query = string.format("SELECT * from CPMobs where level <= %d and level >= %d and area_name like %s",levela, levelb, fixsql(area))
  elseif decideQ == 24 then -- level and room
    query = string.format("SELECT * from CPMobs where level <= %d and level >= %d and room_name like %s", levela, levelb, fixsql(room))
  elseif decideQ == 27 then -- area and room this shouldn't really happen but fuck it, its an option now
    query = string.format("SELECT * from CPMobs where area_name like %s and room_name like %s", fixsql(area), fixsql(room))
  elseif decideQ == 25 then -- name, level, room
    query = string.format("SELECT * from CPMobs where name like %s and level <= %d and level >= %d and room_name like %s", fixsql(name), levela, levelb, fixsql(room))
  elseif decideQ == 37 then -- name, level, room, area
    query = string.format("SELECT * from CPMobs where name like %s and level <= %d and level >= %d and room_name like %s and area_name like %s", fixsql(name), levela, levelb,fixsql(room), fixsql(area))
  elseif decideQ == 28 then -- name, room, area
    query = string.format("SELECT * from CPMobs where name like %s and room_name like %s and area_name like %s", fixsql(name), fixsql(room), fixsql(area))
  elseif decideQ == 22 then -- name, level, area 
    query = string.format("SELECT * from CPMobs where name like %s and level <= %d and level >= %d and area_name like %s", fixsql(name), levela, levelb, fixsql(area))
  elseif decideQ == 36 then -- level, room, area
    query = string.format("SELECT * from CPMobs where level <= %d and level >= %d and room_name like %s and area_name like %s", levela, levelb,fixsql(room), fixsql(area))

  end
  print(query)
  for p in dbkt:nrows(query) do
    table.insert(mobbuff, p )
  end
  tprint (mobbuff)
  if decideQ == 1 and #mobbuff <1 then 
    -- print ('test')
    query = string.format("SELECT * from mobkills where name like %s group by room_id", fixsql(name))
    for p in dbkt:nrows(query) do
      table.insert(mobbuff, p)
    end
  tprint(mobbuff)
  end
  print (#mobbuff)
  if #mobbuff<1 then
    print ("OKYDOKY BOSS NOTHING TO SEE HERE")
    print ("seriously though we found nothing")
  end
end