require "slam"
vector = require "hump.vector"
Timer = require "hump.timer"

require "helpers"
require "game"

scale = 4 -- how many screen pixels are the length of one game pixel?
tilesize = 16 -- what is the length of a tile in game pixels?

function love.load()
    boringLoad() -- see helpers.lua

    setScale(4)

    love.graphics.setFont(fonts.m5x7[16])

    rooms = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("levels")) do
        table.insert(rooms, parseRoom("levels/"..filename))
    end

    currentRoom = 1
    loadRoom(currentRoom)

    holding = nil
end

function love.update(dt)
    Timer.update(dt)
end

function love.keypressed(key)
    if key == "escape" then
        -- why did we need this again?
        -- love.window.setFullscreen(false)
        -- love.timer.sleep(0.1)
        love.event.quit()
    elseif key == "1" then
        setScale(1)
    elseif key == "2" then
        setScale(2)
    elseif key == "3" then
        setScale(4)
    elseif key == "4" then
        setScale(8)
    elseif key == "left" then
        currentRoom = 1 + (((currentRoom-2)) % #rooms)
        loadRoom(currentRoom)
    elseif key == "right" then
        currentRoom = 1 + (((currentRoom+0)) % #rooms)
        loadRoom(currentRoom)
    end
end

function love.mousepressed(x, y, button, touch)
    tx = math.floor(x/scale/tilesize)
    ty = math.floor(y/scale/tilesize)

    if button == 1 then
        what = occupied(tx, ty)
        if what then
            holding = what[1]
        end
    end
    if button == 2 then
        if holding then
            holding.r = (holding.r + 1) % 4
        else
            what = occupied(tx, ty)
            if what then
                what[1].r = (what[1].r + 1) % 4
            end
        end
    end
end

function love.mousereleased(x, y, button, touch)
    if button == 1 then
        if holding then
            holding.x = round(holding.x)
            holding.y = round(holding.y)
            holding = nil
        end
    end

    for x = 1,100 do
        for y = 1,100 do
            if room.floor[x][y] == "floor" then
                what = occupied(x,y)
                if what and #what > 1 then
                    for i=1,#what do
                        what[i].dirty = true
                    end
                end
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy, touch)
    if holding then
        holding.x = x/scale/tilesize-0.5
        holding.y = y/scale/tilesize-0.5
    end
end

function love.draw()
    love.graphics.scale(scale, scale)

    drawRoom(room)

    for i = 1, #objects do
        drawObject(objects[i])
    end

    drawDebug()

    love.graphics.print(room.name, 100, 0)
end
