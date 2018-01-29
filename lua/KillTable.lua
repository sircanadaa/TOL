function init()
 rc= dbkt:exec([[
  		  CREATE TABLE mobkills(
          mk_id INTEGER NOT NULL PRIMARY KEY autoincrement,
          name TEXT default "Unknown",
          room_id INTEGER default 0); 
  		]])
 
 if rc ~= 0 then
 note (DatabaseError('dbkt'))
  end--if
end

function Add_Kill_Table( kill_table )
  if dbkt:isopen()== false then
    print ('table not open')
    return
  end --if 
   DebugNote(kill_table.name)
   DebugNote(kill_table.room_id)
  if dbkt:isopen() then
   -- print ("database is open")
  end--if
  rc = nil
  stmt1 = 'select name, room_id, count(*) as count from mobkills where name = %s and room_id = %s order by count'
  stmt1 = string.format(stmt1, fixsql(kill_table.name), fixsql(kill_table.room_id))
  for rows in dbkt:nrows(stmt1) do
    if tonumber(rows.count) >20 then
      DebugNote(true)
      DebugNote(rows.count)
      return
    else
      DebugNote('count ='..rows.count)
    end--if
  end -- for
  room_id = tonumber(kill_table.room_id)
	stmt="INSERT INTO mobkills(name, room_id) VALUES(%s,%s);"
  stmt = string.format(stmt, fixsql(kill_table.name), fixsql(kill_table.room_id))
  DebugNote(kill_table.name)
	rc= dbkt:exec(stmt)
	--print (rc)
  if rc ~= 0 then
  Note ( DatabaseError('dbkt'))
  end--if
end

function check_column(str, db)
    local query = 'pragma table_info(cpmobs)'
    for row in db:nrows(query) do
        if row.name == str then
            print('true')
            return true
        end
    end
    print('false')
    return false
end

function Clean_Kill_Table( )
    local dbktcp = sqlite3.open(GetPluginInfo (GetPluginID (), 20) .. 'KillTable.db')
    if check_column('timeskilled', dbktcp) ~= false then
        print('will not update table, already is updated.')
        return
    end
    local query = " select *, count(*) as timeskilled from CPMobs group by name, room_id order by timeskilled desc"
    local table_holder = {}
    local counter = 0
    for v in dbktcp:nrows(query) do
        counter = counter + 1
        
        --tprint(v)
        table_holder[counter] = {
            name        = v.name,
            room_id     = v.room_id,
            room_name   = v.room_name,
            area_name   = v.area_name,
            level       = v.level,
            keywords    = v.keywords,
            timeskilled = v.timeskilled
        }
    end
    print(#table_holder)
    rc = dbktcp:exec("alter table CPMobs add column timeskilled INTEGER")
    if rc ~= 0 then
            print('alter table error:')
            Note ( DatabaseError('dbkt'))
            return
        end--if
    rc = dbktcp:exec("delete from CPMobs")
    if rc ~= 0 then
            print('delete table error:')
            Note ( DatabaseError('dbkt'))
            return
        end--if
    rc = dbktcp:exec("commit")
    dbktcp:exec('begin')
    for i,v in ipairs(table_holder) do
        stmt = "INSERT INTO CPMobs (name, room_id, room_name, area_name, level, keywords, timeskilled) VALUES (%s,%s,%s,%s,%s,%s,%s)"
        ex_stmt = string.format(stmt, fixsql(v.name), fixsql(v.room_id), fixsql(v.room_name), fixsql(v.area_name), fixsql(v.level),
         fixsql(v.keywords), fixsql(v.timeskilled))
        rc = dbktcp:exec(ex_stmt)
        if rc ~= 0 then
            print(i)
            print(v)
            print('insert table error:')
            Note ( DatabaseError('dbkt'))
            dbktcp:exec("ROLLBACK")
            
            return
        end--if
    end 
    dbktcp:exec('end')
  dbktcp:close()
end

function fixsql (s)
   if s then
      return "'" .. (string.gsub (s, "'", "''")) .. "'" -- replace single quotes with two lots of single quotes
   else
      return "NULL"
   end -- if
end -- fixsql

