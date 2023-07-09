playerStartX = 360
playerStartY = 200

player = world:newRectangleCollider(playerStartX, playerStartY, 40, 100, {collision_class = 'Player'})
player:setFixedRotation(true) -- collider cannot rotate
player.speed = 240
player.animation = animations.idle
player.isMoving = false
player.direction = 1
player.grounded = true

function playerUpdate(dt)
    if player.body then
        local colliders = world:queryRectangleArea(player:getX() - 20, player:getY() + 50, 40, 2, {'Platform'})
        if #colliders > 0 then
            player.grounded = true
        else
            player.grounded = false
        end
        player.isMoving = false
        local px, py = player:getPosition()
        if love.keyboard.isDown('right')then
            player:setX(px + player.speed*dt)
            player.isMoving = true
            player.direction = 1
        end
        if love.keyboard.isDown('left') then
            player:setX(px - player.speed*dt)
            player.isMoving = true
            player.direction = -1
        end
    end

    if player:enter('Danger') then
        player:setPosition(playerStartX, playerStartY)
    end

    if player.grounded then
        if player.isMoving then
            player.animation = animations.run
        else
            player.animation = animations.idle
        end
    else
        player.animation = animations.jump
    end

    player.animation:update(dt)
end

function drawPlayer()
    local px, py = player:getPosition()
    if player.animation == animations.run then
        player.animation:draw(sprites.runSheet, px, py, nil, 0.25 * player.direction, 0.25, 200, 230)
    elseif player.animation == animations.jump then
        player.animation:draw(sprites.jumpSheet, px, py, nil, 0.25 * player.direction, 0.25, 200, 230)
    elseif player.animation == animations.idle then
        player.animation:draw(sprites.idleSheet, px, py, nil, 0.25 * player.direction, 0.25, 200, 230)
    end
end