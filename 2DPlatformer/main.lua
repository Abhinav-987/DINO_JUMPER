local gamestate = "start"
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest") 
    love.window.setMode(1000, 768)
    anim8 = require 'libraries/anim8'
    sti = require 'libraries/sti'
    cameraFile = require'libraries/camera'
    cam = cameraFile()

    sounds = {}
    sounds.jump = love.audio.newSource("audio/jump.wav", "static")
    sounds.music = love.audio.newSource("audio/music.mp3", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.5)
    sounds.music:play()

    font2 = love.graphics.newFont("fonts/Super Foods.ttf", 150)
    font1 = love.graphics.newFont("fonts/Super Foods.ttf", 40)

    sprites = {}
    sprites.idleSheet = love.graphics.newImage('sprites/Idle.png')
    sprites.jumpSheet = love.graphics.newImage('sprites/Jump.png')
    sprites.runSheet = love.graphics.newImage('sprites/Run.png')
    sprites.enemySheet = love.graphics.newImage('sprites/enemySheet.png')
    sprites.background = love.graphics.newImage('sprites/Forest.png')

    local grid1 = anim8.newGrid(680, 472, sprites.idleSheet:getWidth(), sprites.idleSheet:getHeight())
    local grid2 = anim8.newGrid(680, 472, sprites.jumpSheet:getWidth(), sprites.jumpSheet:getHeight())
    local grid3 = anim8.newGrid(680, 472, sprites.runSheet:getWidth(), sprites.runSheet:getHeight())
    local enemyGrid = anim8.newGrid(100, 70, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight())

    animations = {}
    animations.idle = anim8.newAnimation(grid1('1-10', 1), 0.05)
    animations.jump = anim8.newAnimation(grid2('1-12', 1), 0.12)
    animations.run = anim8.newAnimation(grid3('1-8', 1), 0.05)
    animations.enemy = anim8.newAnimation(enemyGrid('1-2', 1), 0.03)

    wf = require 'libraries/windfield/windfield'
    world = wf.newWorld(0, 800, false) -- newWorld(x-dir gravity, y-dir gravity, sleep)
    --sleep parameter tells wether the body is allowed to sleep
    world:setQueryDebugDrawing(true)

    world:addCollisionClass('Platform')
    world:addCollisionClass('Player'--[[, {ignores = {'Platform'}}]])
    world:addCollisionClass('Danger')

    require('player')
    require('enemy')
    require('libraries/show')

    dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, {collision_class = 'Danger'})
    -- collider is physics object
    --(xpos, ypos, width, height)
    dangerZone:setType('static')--by default colliders are dynamic affected by colliders and the forces

    platforms = {}

    flagX = 0
    flagY = 0

    saveData = {}
    saveData.currentLevel = "level1"

    if love.filesystem.getInfo("data.lua") then
        local data = love.filesystem.load("data.lua")
        data()
    end

    loadMap(saveData.currentLevel)
    
end

function love.update(dt)
    if gamestate == "play" then
        world:update(dt)
        gameMap:update(dt)
        playerUpdate(dt)
        updateEnemies(dt)

        local px, py = player:getPosition()
        cam:lookAt(px, love.graphics.getHeight()/2)
        local colliders = world:queryCircleArea(flagX, flagY, 10, {'Player'})
        if #colliders > 0 then
            if saveData.currentLevel == "level1" then
                loadMap("level2")
            elseif saveData.currentLevel == "level2" then
                loadMap("level1")
            end
        end
    end
end

function love.draw()
    love.graphics.draw(sprites.background, 0, 0)
    local fps = love.timer.getFPS()
    love.graphics.print("FPS: " .. fps, 10, 10)
    if gamestate == "start" then
        love.graphics.setFont(font2)
        love.graphics.setColor(255, 255, 0)
        love.graphics.printf("DINO JUMPER", 0, love.graphics.getHeight()/4, love.graphics.getWidth(), "center")
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(font1)
        love.graphics.setColor(255, 255, 0)
        love.graphics.printf("Press Enter to view instructions", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), "center")
        love.graphics.setColor(255, 255, 255)
    elseif gamestate == "instructions" then
        love.graphics.setFont(font1)
        love.graphics.setColor(255, 255, 0)
        love.graphics.printf("Instructions:\n So in this game u have the goal to reach the flag" .. 
        "\n As soon as you reaches the flag the level changes." ..
        "\n Use left and right arrow key to move forward and backward." ..
        "\n Use UP arrow key to jump." .. 
        "\n You have to stay away from the enemy otherwise u will again start from start of the level." ..
        "\n\nPress Space to start the game", 0, love.graphics.getHeight()/4, love.graphics.getWidth(), "center")
        love.graphics.setColor(255, 255, 255)
    else
        -- The rest of your code for the "play" state
        cam:attach()
        gameMap:drawLayer(gameMap.layers['Tile Layer 1'])
        --world:draw()
        drawPlayer()
        drawEnemies()
        cam:detach()
    end
end


-- function love.mousepressed(x, y, button)
--     if gamestate == "start" and button == 1 then
--         -- Switch to the "play" state on left mouse button click
--         gamestate = "play"
--     end
-- end
-- function love.mousepressed(x, y, button)
--     if button == 1 then
--         local colliders = world:queryCircleArea(x, y, 200, {'Platform', 'Danger'})
--         for i, c in ipairs(colliders) do
--             c:destroy()
--         end
--     end
-- end

function spawnPlatform(x, y, width, height)
    if height > 0 and width > 0 then
        local platform = world:newRectangleCollider(x, y, width, height, {collision_class = 'Platform'})
        platform:setType('static')
        table.insert(platforms, platform)
    end
end

function destroyAll()
    local i = #platforms
    while i > -1 do
        if platforms[i] ~= nil then
            platforms[i]:destroy()
        end
        table.remove(platforms, i)
        i = i - 1
    end

    local i = #enemies
    while i > -1 do
        if enemies[i] ~= nil then
            enemies[i]:destroy()
        end
        table.remove(enemies, i)
        i = i - 1
    end
end

function loadMap(mapName)
    saveData.currentLevel = mapName
    love.filesystem.write("data.lua", table.show(saveData, "saveData"))
    destroyAll()
    gameMap = sti('maps/' .. mapName .. '.lua')
    for i, obj in pairs(gameMap.layers['Start'].objects) do
        playerStartX = obj.x
        playerStartY = obj.y
    end
    player:setPosition(playerStartX, playerStartY)
    for i, obj in pairs(gameMap.layers['Platforms'].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height)
    end
    for i, obj in pairs(gameMap.layers['Enemies'].objects) do
        spawnEnemy(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers['Flag'].objects) do
        flagX = obj.x
        flagY = obj.y
    end
end

function love.keypressed(key)
    if gamestate == "start" then
        if key == 'return' then
            gamestate = "instructions"
        end
    elseif gamestate == "instructions" then
        if key == 'space' then
            gamestate = "play"
        end
    end
    if key == 'up' then
        if player.grounded then
            player:applyLinearImpulse(0, -4500)-- applies force (here negative denotes that it is in upward direcrion)
            sounds.jump:play()
        end
    end
end