require "slam"
vector = require "hump.vector"
Timer = require "hump.timer"

require "helpers"
require "game"

scale = 4 -- how many screen pixels are the length of one game pixel?
tilesize = 16 -- what is the length of a tile in game pixels?

function love.load()
    boringLoad() -- see helpers.lua

    --music.blip_stream:setVolume(0.7)
    --soundtrack = love.audio.play(music.blip_stream)

    setScale(4)

    love.graphics.setFont(fonts.m5x7[16])

    rooms = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("levels")) do
        if string.match(filename, ".txt$") then
            table.insert(rooms, parseRoom("levels/"..filename))
        end
    end

    mode = "title"

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
        if mode == "game" then
            mode = "menu"
            love.audio.play(sounds.back)
        elseif mode == "menu" then
            mode = "title"
            love.audio.play(sounds.back)
        elseif mode == "title" then
            love.audio.play(sounds.back)
            love.event.quit()
        end
    elseif key == "1" then
        setScale(1)
    elseif key == "2" then
        setScale(2)
    elseif key == "3" then
        setScale(4)
    elseif key == "4" then
        setScale(8)
    elseif key == "left" then
        if mode == "game" then
            loadRoom(1 + (((currentRoom-2)) % #rooms))
        end
    elseif key == "right" then
        if mode == "game" then
            loadRoom(1 + (((currentRoom+0)) % #rooms))
        end
    end
end

function love.mousepressed(x, y, button, touch)
    if mode == "game" then
        if room.story[2] ~= nil then
          love.graphics.print(room.story[2], 200, 160)
          table.remove(room.story, 1)
        end
        tx = math.floor(x/scale/tilesize)
        ty = math.floor(y/scale/tilesize)-1

        if button == 1 then
            what = occupied(tx, ty)
            if what then
                holding = what[1]
                love.audio.play(sounds.pickup)
            end
        end
        if button == 2 then
            if holding then
                holding.r = (holding.r + 1) % 4
                love.audio.play(sounds.rotate)
            else
                what = occupied(tx, ty)
                if what then
                    for i=1,#what do
                        what[1].r = (what[1].r + 1) % 4
                        love.audio.play(sounds.rotate)
                    end
                end
            end
        end

        checkRules()
    elseif mode == "title" then
        mode = "menu"
    elseif mode == "menu" then
        if button == 1 then
            if menuIndex() then
                loadRoom(menuIndex())
                mode = "game"
                love.audio.play(sounds.menu)
            end
        end
    end
end

function love.mousereleased(x, y, button, touch)
    if mode == "game" then
        if button == 1 then
            if holding then
                holding.x = round(holding.x)
                holding.y = round(holding.y)
                holding = nil
                love.audio.play(sounds.drop)
            end
        end

        checkRules()
    end
end

function love.mousemoved(x, y, dx, dy, touch)
    if mode == "game" then
        if holding then
            holding.x = x/scale/tilesize-0.5
            holding.y = y/scale/tilesize-0.5-1
        end

        checkRules()
    end
end

function love.draw()
    love.graphics.scale(scale, scale)

    if mode == "game" then
        if room.solved then
            love.graphics.setColor(0, 200, 0)
            room.story = {}
            if room.won[1] ~= nil then
              love.graphics.print(room.won[1], 116, 8)
            end
        else
            love.graphics.setColor(255, 255, 255)
        end
        love.graphics.print(room.name, 16, 8)

        if room.story[1] ~= nil then
          love.graphics.print(room.story[1], 116, 8)
        end

        love.graphics.translate(0, 16)

        drawRoom()
        for i = 1, #objects do
            drawObject(objects[i])

            local w = occupied(objects[i].x,objects[i].y)
            if w and #w > 1 then
                love.graphics.setColor(255, 255, 255)
                love.graphics.print("x"..#w, (objects[i].x+1)*tilesize+2, objects[i].y*tilesize)
            end
        end
        --drawDebug()

        love.graphics.setColor(255, 0, 0)

        tx = math.floor(round(love.mouse.getX())/scale/tilesize)
        ty = math.floor(round(love.mouse.getY())/scale/tilesize)-1

        what = occupied(tx,ty)

        if what then
          for i = 1, #what do
            if what[i].errorStr ~= nil then
              for j = 1, #what[i].errorStr do
                love.graphics.print(what[i].errorStr[j], 16, 109 + 10 * i + 10 * j)
              end
            end
          end
        end
    elseif mode == "title" then
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(images.title, 0, 0)
    elseif mode == "menu" then
        love.graphics.setColor(0, 0, 255)
        love.graphics.printf("SELECT A LEVEL", 0, 8, 320, "center")

        local x = 16
        local y = 32
        for i=1,#rooms do
            if menuIndex() == i then
                if rooms[i].solved then
                    love.graphics.setColor(0, 200, 0)
                else
                    love.graphics.setColor(255, 255, 255)
                end
            else
                if rooms[i].solved then
                    love.graphics.setColor(0, 100, 0)
                else
                    love.graphics.setColor(100, 100, 100)
                end
            end
            love.graphics.print(rooms[i].name, x, y)
                y = y+23
            if y > 140 then
                x = x+85+16
                y = 32
            end
        end
    end
end
