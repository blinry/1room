function parseRoom(filename)
    local legend = {}
    legend[" "] = "empty"
    legend["#"] = "wall"
    legend["="] = "window"
    legend["^"] = "door_top"
    legend[">"] = "door_right"
    legend["v"] = "door_bottom"
    legend["<"] = "door_left"
    legend["."] = "floor"

    local room = {}
    room.floor = {}
    room.horizontal = {}
    room.vertical = {}
    room.doorX = {}
    room.doorY = {}
    room.name = string.match(string.match(filename, "[^/]+.txt"), "[^/.]+")

    for i = 1,101 do
        room.floor[i] = {}
        room.horizontal[i] = {}
        room.vertical[i] = {}

        for j = 1,101 do
            room.floor[i][j] = "empty"
            room.horizontal[i][j] = "empty"
            room.vertical[i][j] = "empty"
        end
    end

    local f = io.open(filename)

    local horizontal = true
    local lineNr = 1
    while true do
        local line = f:read()
        if line == nil then noObjectList() end

        if line == "---" then
            break
        end

        if horizontal then
            for i = 2, #line, 2 do
                local c = line:sub(i,i)
                room.horizontal[i/2][1+(lineNr-1)/2] = legend[c]
            end
        else
            for i = 1, #line, 2 do
                local c = line:sub(i,i)
                room.vertical[1+(i-1)/2][lineNr/2] = legend[c]
            end
            for i = 2, #line, 2 do
                local c = line:sub(i,i)
                room.floor[i/2][lineNr/2] = legend[c]
            end
        end
        horizontal = not horizontal
        lineNr = lineNr+1
    end

    room.objects = {}
    local x = 12
    local y = 1
    while true do
        local line = f:read()

        if line == nil then
            break
        end

        amount, what = string.match(line, "([0-9]+) (.+)")

        for j = 1, tonumber(amount) do
            table.insert(room.objects, {what = what, x = x, y = y, r = 1, errorStr = {}})
        end

        x = x+2
        if x > 18 then
            x = 12
            y = y+3
        end
    end

    return room
end

function loadRoom(i)
    room = rooms[i]
    objects = room.objects
    checkRules()
end

function drawRoom()
    room.doorX = {}
    room.doorY = {}
    for x = 1,100 do
        for y = 1,100 do
            love.graphics.setColor(255, 255, 255)
            if room.floor[x][y] == "floor" then
                love.graphics.draw(images.parquet, tilesize*x, tilesize*y, 0)
            end

            love.graphics.setColor(255, 255, 255)
            local top = room.horizontal[x][y]
            if top == "wall" then
                love.graphics.draw(images.wall, tilesize*x, tilesize*y+1, -math.pi/2)
            elseif top == "window" then
                love.graphics.draw(images.window, tilesize*x, tilesize*y+1, -math.pi/2)
            elseif top == "door_top" then
                love.graphics.draw(images.door, tilesize*x, tilesize*(y-1), 0) 
                table.insert(room.doorX, x);
                table.insert(room.doorY, y-1);
            elseif top == "door_bottom" then
                love.graphics.draw(images.door, tilesize*(x+1), tilesize*(y+1), math.pi)
                table.insert(room.doorX, x);
                table.insert(room.doorY, y);
            end

            love.graphics.setColor(255, 255, 255)
            local left = room.vertical[x][y]
            if left == "wall" then
                love.graphics.draw(images.wall, tilesize*x-1, tilesize*y, 0)
            elseif left == "window" then
                love.graphics.draw(images.window, tilesize*x-1, tilesize*y, 0)
            elseif left == "door_right" then
                love.graphics.draw(images.door, tilesize*(x+1), tilesize*(y), -3*math.pi/2)
                table.insert(room.doorX, x);
                table.insert(room.doorY, y);
            elseif left == "door_left" then
                love.graphics.draw(images.door, tilesize*(x-1), tilesize*(y+1), -math.pi/2)
                table.insert(room.doorX, x-1);
                table.insert(room.doorY, y);
            end
        end
    end
end

function drawDebug()
    for x = 1,100 do
        for y = 1,100 do
            if occupied(x, y) then
                love.graphics.setColor(0, 0, 255)
                love.graphics.circle("fill", tilesize*(x+0.5), tilesize*(y+0.5), tilesize/10)
            end
        end
    end
end

function drawObject(object)
    local what = object.what
    local x = object.x
    local y = object.y
    local r = object.r

    love.graphics.push()
    love.graphics.translate(tilesize*(x+0.5), tilesize*(y+0.5))
    love.graphics.rotate(r/2*math.pi)

    if object.dirty then
        love.graphics.setColor(255, 0, 0)
    else
        love.graphics.setColor(255, 255, 255)
    end

    if what == "plant" then
        love.graphics.draw(images.plant, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "armchair" then
        love.graphics.draw(images.armchair, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "officechair" then
        love.graphics.draw(images.officechair, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "table" then
        love.graphics.draw(images.couchtable, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "shelf" then
        love.graphics.draw(images.bookshelf, 3*tilesize/2, -tilesize/2, math.pi/2)
    elseif what == "couch" then
        love.graphics.draw(images.couch, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "desk" then
        love.graphics.draw(images.desk, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "bed" then
        love.graphics.draw(images.bed, -tilesize/2, 3*tilesize/2, -math.pi/2)
    else
        unknownObjectType()
    end
    love.graphics.pop()
end

function isInTable(tableX, tableY, x, y)
    for i=1, #tableX do
        if tableX[i] == x and tableY[i] == y then 
            return true
        end
    end

    return false
end

function neighborybility(posX, posY)
    accessibleNeighbors = {}
    accessX = {}
    accessY = {}

    -- left
    if posX > 1 then
        local bla = "false"
        if accessible(posX-1, posY) then bla = "true" end
        local bla2 = "false"
        local bla3 = "false"
        if room.vertical[posX][posY] == "window" then bla2 = "true" end
        if not (room.vertical[posX][posY] == "window") then bla3 = "true" end
        --nopeText = "neee "..bla.." "..bla2.." "..bla3..""
        
        if accessible(posX-1, posY) and room.vertical[posX][posY] ~= "window" and room.vertical[posX][posY] ~= "wall" then
            --nopeTest = "WOOT"
            table.insert(accessX, posX-1)
            table.insert(accessY, posY)
        end
    end
    -- right
    if posX < 100 then
        if accessible(posX+1, posY) and room.vertical[posX+1][posY] ~= "window" and room.vertical[posX+1][posY] ~= "wall" then
            table.insert(accessX, posX+1)
            table.insert(accessY, posY)
        end
    end
    -- top
    if posY > 1 then
        if accessible(posX, posY-1) and room.horizontal[posX][posY] ~= "window" and room.horizontal[posX][posY] ~= "wall" then
            table.insert(accessX, posX)
            table.insert(accessY, posY-1)
        end
    end
    -- bottom
    if posY < 100 then
        if accessible(posX, posY+1) and room.horizontal[posX][posY+1] ~= "window" and room.horizontal[posX][posY+1] ~= "wall" then
            table.insert(accessX, posX)
            table.insert(accessY, posY+1)
        end
    end


    table.insert(accessibleNeighbors, accessX)
    table.insert(accessibleNeighbors, accessY)
    return accessibleNeighbors
end

function doorybility(startx, starty)
    local toCheckX = {}
    local toCheckY = {}

    local accessiblePoints = {}
    local accessibleX = {}
    local accessibleY = {}

    if(accessible(startx, starty)) then
        table.insert(toCheckX, startx)
        table.insert(toCheckY, starty)
        table.insert(accessibleX, startx)
        table.insert(accessibleY, starty)
    end

    while #toCheckX > 0 do
        local testX = table.remove(toCheckX)
        local testY = table.remove(toCheckY)
        ins = neighborybility(testX, testY)
        --nopeText = "neee "..#ins[1].." "..testX.." "..testY..""

        for i=1, #ins[1] do
            if not isInTable(accessibleX, accessibleY, ins[1][i], ins[2][i]) then
                table.insert(accessibleX, ins[1][i])
                table.insert(accessibleY, ins[2][i])
                table.insert(toCheckX, ins[1][i])
                table.insert(toCheckY, ins[2][i])
            end
        end
    end

    table.insert(accessiblePoints, accessibleX)
    table.insert(accessiblePoints, accessibleY)
    return accessiblePoints
end


function checkRules()
    -- nopeText = ""

    local accessibleX = {}
    local accessibleY = {}
    local ac = {}
    
    for i=1, #room.doorX do
        ac = doorybility(room.doorX[i], room.doorY[i]);
        table.insert(accessibleX, ac[1])
        table.insert(accessibleY, ac[2])
    end

    allVisibleX = {}
    allVisibleY = {}

    --nopeText = "ABC "..#allVisibleX.." "..#ac.." "..#accessibleX.." "..#doorybility(room.doorX[1], room.doorY[1])[1]..""
    local allVis = true
    if #accessibleX > 0 then
        for i=1, #accessibleX[1] do
            for j=2, #accessibleX do
                if not isInTable(accessibleX[j], accessibleY[j], accessibleX[1][i], accessibleY[1][i]) then
                    allVis = false
                    break
                end
            end
            if allVis == true then
                table.insert(allVisibleX, accessibleX[1][i])
                table.insert(allVisibleY, accessibleY[1][i])
            end
        end
    end
    nopeText = "ABC "..#allVisibleX..""


    for i=1,#objects do
        objects[i].errorStr = {}
        objects[i].dirty = not allowed(objects[i])
    end

    for x = 1,100 do
        for y = 1,99 do
            what = occupied(x,y)
            if what then
                if (doorypied(x,y)) then
                    for i=1,#what do
                        what[i].dirty = true
                        table.insert(what[i].errorStr,"All doors need to be accessible.")
                    end
                end
                if (windowypied(x,y)) then
                    for i=1,#what do
                        if what[i].what == "shelf" then
                            what[i].dirty = true
                            table.insert(what[i].errorStr,"Shelves must not block windows.")
                        end
                    end
                end
                if (#what > 1 and room.floor[x][y] == "floor") then
                    for i=1,#what do
                        what[i].dirty = true
                        table.insert(what[i].errorStr,"Objects must not overlap.")
                    end
                else
                if room.floor[x][y] == "empty" then
                  for i=1,#what do
                    what[i].dirty = true
                    table.insert(what[i].errorStr,"All objects must be inside of the room.")
                  end
                end
                    -- TODO: degenerate walls
                end
            end
        end
    end
end

function occupies(object, x, y)
    local what = object.what
    local ox = round(object.x)
    local oy = round(object.y)
    local r = object.r

    if what == "plant" or what == "armchair" or what == "officechair" or what == "table"  then
        return ox == x and oy == y
    elseif what == "shelf" or what == "couch" or what == "desk" then
        return (x == ox and y == oy) or
            (r == 0 and x == ox+1 and y == oy) or
            (r == 1 and x == ox and y == oy+1) or
            (r == 2 and x == ox-1 and y == oy) or
            (r == 3 and x == ox and y == oy-1)
    elseif what == "bed" then
        if r == 0 then
            return x >= ox and x <= ox+1 and y >= oy and y <= oy+1
        elseif r == 1 then
            return x >= ox-1 and x <= ox and y >= oy and y <= oy+1
        elseif r == 2 then
            return x >= ox-1 and x <= ox and y >= oy-1 and y <= oy
        elseif r == 3 then
            return x >= ox and x <= ox+1 and y >= oy-1 and y <= oy
        end
    else
        unknownObjectType()
    end
end

function pathTo(fromX, fromY, toX, toY)
    return true
end

function allowed(object)
    local ox = round(object.x)
    local oy = round(object.y)

    if object.what == "armchair" then
        if not (object.r == 1 and isInTable(allVisibleX, allVisibleY, ox+1, oy)
                or object.r == 2 and isInTable(allVisibleX, allVisibleY, ox, oy+1)
                or object.r == 3 and isInTable(allVisibleX, allVisibleY, ox-1, oy)
                or object.r == 0 and isInTable(allVisibleX, allVisibleY, ox, oy-1)) then
                table.insert(object.errorStr,"An armchair needs to be accessible from the front.")
            return false
        end

    elseif object.what == "couch" or object.what == "shelf" then
        if not (object.r == 0 and (isInTable(allVisibleX, allVisibleY, ox, oy-1) or isInTable(allVisibleX, allVisibleY, ox+1, oy-1))
                or object.r == 1 and (isInTable(allVisibleX, allVisibleY, ox+1, oy) or isInTable(allVisibleX, allVisibleY, ox+1, oy+1))
                or object.r == 2 and (isInTable(allVisibleX, allVisibleY, ox, oy+1) or isInTable(allVisibleX, allVisibleY, ox-1, oy+1))
                or object.r == 3 and (isInTable(allVisibleX, allVisibleY, ox-1, oy) or isInTable(allVisibleX, allVisibleY, ox-1, oy-1))) then
                table.insert(object.errorStr,"A "..object.what.."'s front needs to be accessible.")
            return false
        end
    elseif object.what == "officechair" then
        return isInTable(allVisibleX, allVisibleY, ox+1,oy) or isInTable(allVisibleX, allVisibleY, ox-1, oy) or isInTable(allVisibleX, allVisibleY, ox, oy+1)  or isInTable(allVisibleX, allVisibleY, ox,oy-1)  
    elseif object.what == "table" then
        what = occupied(ox+1,oy)
        if what then
          if what[1].what == "couch" and what[1].r ~= 1 then
             ok = true 
          end
        end
        what = occupied(ox-1,oy)
        if what then
          if what[1].what == "couch" and what[1].r ~= 3 then
            ok = true
          end
        end
        what = occupied(ox,oy+1)
        if what then
          if what[1].what == "couch" and what[1].r ~= 0 then
            ok = true
          end
        end
        what = occupied(ox,oy-1)
        if what then
          if what[1].what == "couch" and what[1].r ~= 2 then
            ok = true
          end
        end
        if not ok then
            table.insert(object.errorStr, "A "..object.what.." needs to be in front or next to a couch.")
        end
        return ok
    elseif object.what == "bed" then
        if not ( object.r == 0 and (isInTable(allVisibleX, allVisibleY, ox, oy-1) or isInTable(allVisibleX, allVisibleY, ox+1, oy-1) or isInTable(allVisibleX, allVisibleY, ox, oy+2) or isInTable(allVisibleX, allVisibleY, ox+1, oy+2) or isInTable(allVisibleX, allVisibleY, ox-1, oy) or isInTable(allVisibleX, allVisibleY, ox-1, oy+1) or isInTable(allVisibleX, allVisibleY, ox+2, oy) or isInTable(allVisibleX, allVisibleY, ox+2, oy+1))
                 or object.r == 1 and (isInTable(allVisibleX, allVisibleY, ox+1, oy) or isInTable(allVisibleX, allVisibleY, ox+1, oy+1) or isInTable(allVisibleX, allVisibleY, ox-2, oy) or isInTable(allVisibleX, allVisibleY, ox-2, oy+1) or isInTable(allVisibleX, allVisibleY, ox, oy-1) or isInTable(allVisibleX, allVisibleY, ox-1, oy-1) or isInTable(allVisibleX, allVisibleY, ox, oy+2) or isInTable(allVisibleX, allVisibleY, ox-1, oy+2))
                 or object.r == 2 and (isInTable(allVisibleX, allVisibleY, ox, oy+1) or isInTable(allVisibleX, allVisibleY, ox-1, oy+1) or isInTable(allVisibleX, allVisibleY, ox, oy-2) or isInTable(allVisibleX, allVisibleY, ox-1, oy-2) or isInTable(allVisibleX, allVisibleY, ox-2, oy) or isInTable(allVisibleX, allVisibleY, ox-2, oy-1) or isInTable(allVisibleX, allVisibleY, ox+1, oy) or isInTable(allVisibleX, allVisibleY, ox+1, oy-1))
                 or object.r == 3 and (isInTable(allVisibleX, allVisibleY, ox-1, oy) or isInTable(allVisibleX, allVisibleY, ox-1, oy-1) or isInTable(allVisibleX, allVisibleY, ox+2, oy) or isInTable(allVisibleX, allVisibleY, ox+2, oy-1)) or isInTable(allVisibleX, allVisibleY, ox, oy+1) or isInTable(allVisibleX, allVisibleY, ox+1, oy+1) or isInTable(allVisibleX, allVisibleY, ox, oy-2) or isInTable(allVisibleX, allVisibleY, ox+1, oy-2)) then
            table.insert(object.errorStr, "A bed needs to be accessible from the side.")
            return false
        end
    end
    return true
end

function doorypied(x, y)
  if room.horizontal[x][y] == "door_bottom" or room.horizontal[x][y+1] == "door_top" or room.vertical[x][y] == "door_right" or room.vertical[x+1][y] == "door_left" then
    return true
  end
  return false
end

function windowypied(x, y)
  if room.horizontal[x][y] == "window" or room.horizontal[x][y+1] == "window" or room.vertical[x][y] == "window" or room.vertical[x+1][y] == "window" then
    return true
  end
  return false
end

function occupied(x, y)
    o = {}
    for i = 1, #objects do
        if occupies(objects[i], x, y) then
            table.insert(o, objects[i])
        end
    end
    if #o > 0 then
        return o
    else
        return false
    end
end

function accessible(x, y)
    o = occupied(x,y)
    return x > 0 and y > 0 and room.floor[x][y] == "floor" and not o
end

function nope(text)
    if nopeText == "" then
        nopeText = text
    end
end
