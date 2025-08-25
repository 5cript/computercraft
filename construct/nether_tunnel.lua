package.path = "../?.lua;" .. package.path

-- Assumes to be placed at the bottom right corner of the tunnel, excluding the walls

-- K = corner, C = ceil, F = floor, E = edge1, D = edge2, W = window
-- KCCCCCK
-- D     D
-- W     W
-- W     W
-- E     E
-- KCCCCCK

-- Ask user for width and depth of the bridge
local turtleUtil = require("lib.turtleutil")

-- inside width, actual width including walls is width + 2
local width = 5
-- window height
local windowHeight = 2

print("Enter the depth of the tunnel (will round down to even number):")
local depth = tonumber(read())
depth = depth - depth % 2

local floorBlock = "minecraft:cobblestone"
local ceilingBlock = "minecraft:cobblestone"
local edge1Block = "minecraft:cobblestone"
local edge2Block = "minecraft:cobblestone"
local windowBlock = "minecraft:iron_bars"
local cornerBlock = "minecraft:cobblestone"

local fillCorners = true

local setRotation = turtleUtil.setRotation
local Rotation = turtleUtil.Rotation
local Direction = turtleUtil.Direction

local function safeMove(direction)
    return turtleUtil.safeMove({
        doDig = true,
        retries = 2,
        sleepTime = 0.5,
        errorOut = true,
        direction = direction
    })
end

local function safeForward()
    return safeMove(Direction.FORWARD)
end

local function safeUp()
    return safeMove(Direction.UP)
end

local function safeDown()
    return safeMove(Direction.DOWN)
end

local function ensureDig(direction)
    return turtleUtil.ensureDig({
        direction = direction,
        retries = 3,
        sleepTime = 0.5,
        errorOut = true
    })
end

local function ensureDigForward()
    return ensureDig(Direction.FORWARD)
end

local function ensureDigUp()
    return ensureDig(Direction.UP)
end

local function ensureDigDown()
    return ensureDig(Direction.DOWN)
end

local function ensurePlace(direction, placeableBlocks)
    turtleUtil.ensurePlace({
        direction = direction,
        placeableBlocks = placeableBlocks,
        retries = 3,
        attack = false,
        sleepTime = 0.5,
        errorOut = true
    })
end

local function checkFuel(amount)
    if turtle.getFuelLevel() < amount then
        error("Low on fuel!")
    end
end

local function moveDestroyLava(direction)
    local inspect, inspectResult = turtle.inspect()
    if direction == Direction.UP then
        inspect = turtle.inspectUp()
    elseif direction == Direction.DOWN then
        inspect = turtle.inspectDown()
    end

    local moveDirection = nil
    if direction == Direction.UP then
        moveDirection = Direction.UP
    elseif direction == Direction.DOWN then
        moveDirection = Direction.DOWN
    end

    local move = safeMove(moveDirection)
    local oppositeMove = safeMove(turtleUtil.oppositeDirection(moveDirection))

    local isLava = inspect and inspectResult.name == "minecraft:lava"

    if isLava then
        move()
        oppositeMove()
        return true
    end
    return false
end

local function ensureReplace(direction, placeableBlocks)
    return turtleUtil.ensureReplace({
        direction = direction,
        placeableBlocks = placeableBlocks,
        retries = 3,
        attack = false,
        sleepTime = 0.5,
        errorOut = true
    })
end
local function ensureReplaceDown(placeableBlocks)
    return turtleUtil.ensureReplace({
        direction = Direction.DOWN,
        placeableBlocks = placeableBlocks,
        retries = 3,
        attack = false,
        sleepTime = 0.5,
        errorOut = true
    })
end
local function ensureReplaceUp(placeableBlocks)
    return turtleUtil.ensureReplace({
        direction = Direction.UP,
        placeableBlocks = placeableBlocks,
        retries = 3,
        attack = false,
        sleepTime = 0.5,
        errorOut = true
    })
end

-- Intentionally unoptimized for moves, because if the turtle moves into lava, it
-- destroys the lava source and it does not remain
local function tunnelSlice()
    checkFuel(width * (windowHeight + 4) * 2)

    -- Right Side
    --       K
    --       D
    --       W
    --       W
    --       E
    --       K
    safeForward()
    setRotation(Rotation.RIGHT)
    safeForward()
    if fillCorners then
        ensureReplace(Direction.DOWN, {cornerBlock})
    end
    safeUp()
    ensurePlace(Direction.DOWN, {edge1Block})

    for i = 1, windowHeight do
        safeUp()
        ensurePlace(Direction.DOWN, {windowBlock})
    end

    local cornerUp = function()
        if fillCorners then
            ensureReplace(Direction.UP, {cornerBlock})
        else
            moveDestroyLava(Direction.UP)
        end
    end

    cornerUp()

    setRotation(Rotation.LEFT)
    safeForward()
    setRotation(Rotation.RIGHT)

    ensurePlace(Direction.FORWARD, {edge2Block})
    setRotation(Rotation.LEFT)

    for i = 1, width do
        ensureReplace(Direction.UP, {ceilingBlock})

        for j = 1, windowHeight do
            safeDown()
        end

        -- within lower edge level
        safeDown()
        ensureReplace(Direction.DOWN, {floorBlock})

        -- wasteful but simple, move back up:
        for j = 1, windowHeight do
            safeUp()
        end
        safeUp()

        if i < width then
            safeForward()
        end
    end

    -- Left Side
    safeForward()
    cornerUp()
    safeDown()
    ensurePlace(Direction.UP, {edge2Block})

    for i = 1, windowHeight do
        safeDown()
        ensurePlace(Direction.UP, {windowBlock})
    end

    if fillCorners then
        ensureReplace(Direction.DOWN, {cornerBlock})
    end

    -- Move inside and place edge block
    setRotation(Rotation.RIGHT)
    safeForward()
    setRotation(Rotation.LEFT)
    ensurePlace(Direction.FORWARD, {edge1Block})

    -- Go back into starting position for next segment
    setRotation(Rotation.RIGHT)
    for i = 1, width - 1 do
        safeForward()
    end
    setRotation(Rotation.FORWARD)
end

local function buildTunnel()
    for i = 1, depth do
        tunnelSlice()
    end
end

local function ensureEnoughBlocks()
    if not turtleUtil.findBlock(floorBlock) then
        error("Not enough floor blocks")
    end

    if not turtleUtil.findBlock(ceilingBlock) then
        error("Not enough ceiling blocks")
    end

    if not turtleUtil.findBlock(edge1Block) then
        error("Not enough edge1 blocks")
    end

    if not turtleUtil.findBlock(edge2Block) then
        error("Not enough edge2 blocks")
    end

    if not turtleUtil.findBlock(cornerBlock) then
        error("Not enough corner blocks")
    end

    if not turtleUtil.findBlock(windowBlock) then
        error("Not enough window blocks")
    end
end

ensureEnoughBlocks()
buildTunnel()
