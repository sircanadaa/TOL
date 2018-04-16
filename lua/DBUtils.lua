function db_exec(connection_str, command)
    local db = sqlite3.open(connection_str)
    rc = db:exec(command)
    if rc ~= 0 then
        Note (DatabaseError('db'))
        print (db:errcode())
        print (db:errmsg())
        db:exec('ROLLBACK')
        db:close()
        return rc
    end--if
    db:close()
    return rc
end
function db_query_area(connection_str, sqlt)
    local return_table = {}
    local db = sqlite3.open(connection_str)
    for a in db:nrows(sqlt) do
        return_table[a.keyword] = {}
        return_table[a.keyword].keyword = a.keyword
        return_table[a.keyword].name = a.name
        return_table[a.keyword].minLevel = a.afrom
        return_table[a.keyword].maxLevel = a.ato
        return_table[a.keyword].lock = a.alock or ''
    end
    db:close()
    return return_table
end
function db_query_areas(connection_str, sqlt)
    local return_table = {}
    local db = sqlite3.open(connection_str)
    for a in db:nrows(sqlt) do
        return_table[a.uid] = {
            name = a.name
        }
    end
    db:close()
    return return_table
end
function db_query_rooms(connection_str, sqlt)
    local return_table = {}
    local db = sqlite3.open(connection_str)
    for row in db:nrows(sqlt) do
        return_table[row.uid] = {}
        return_table[row.uid] = {
            name = row.name,
            area = row.area,
            terrain = row.terrain,
            info = row.info,
            noportal = row.noportal,
            norecall = row.norecall,
            ignore_exits_mismatch = (row.ignore_exits_mismatch == 1),
            exits = {},
        exit_locks = {}}
    end
    db:close()
    return return_table
end
function db_query(connection_str, sqlt)
    local return_table = {}
    local db = sqlite3.open(connection_str)
    for a in db:nrows(sqlt) do
        table.insert(return_table, a)
    end
    db:close()
    return return_table
end
function fixsql (s)
    if s then
        return "'" .. (string.gsub (s, "'", "''")) .. "'" -- replace single quotes with two lots of single quotes
    else
        return "NULL"
    end -- if
end -- fixsql
