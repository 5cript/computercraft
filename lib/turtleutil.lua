package.path = "../?.lua;" .. package.path

local tableUtil = require("lib.table")

local Rotation = {
    FORWARD = 0,
    RIGHT = 1,
    BACKWARD = 2,
    LEFT = 3
}

local Direction = {
    UP = 0,
    FORWARD = 1,
    DOWN = 2
}

-- Keeps track of the turtle's current direction, just relative to initial position facing down the bridge
local currentRotation = Rotation.FORWARD

function setRotation(targetRotation)
    -- Calculate the number of turns needed
    local turnDifference = (targetRotation - currentRotation + 4) % 4

    -- Perform the minimal number of turns
    if turnDifference == 1 then
        turtle.turnRight()
    elseif turnDifference == 2 then
        turtle.turnRight()
        turtle.turnRight()
    elseif turnDifference == 3 then
        turtle.turnLeft()
    end

    -- Update the current direction
    currentRotation = targetRotation
end

local function turnAround()
    setRotation((currentRotation + 2) % 4)
end

local function safeMove(args)
    args = tableUtil.fillDefaults(args, {
        doDig = false,
        direction = Direction.FORWARD,
        retries = 1,
        sleepTime = 0,
        attack = false,
        attackSide = nil,
        errorOut = false
    })

    local move = turtle.forward
    local dig = turtle.dig
    if args.direction == Direction.UP then
        move = turtle.up
        dig = turtle.digUp
    elseif args.direction == Direction.DOWN then
        move = turtle.down
        dig = turtle.digDown
    end

    for i = 1, args.retries do
        if move() then
            return true
        end
        if args.doDig and dig() and move() then
            return true
        end
        if args.attack then
            turtle.attack(args.attackSide)
        end
        if args.sleepTime > 0 then
            os.sleep(args.sleepTime)
        end
    end
    if args.errorOut then
        if args.direction == Direction.FORWARD then
            error("Failed to move forward after retries")
        elseif args.direction == Direction.UP then
            error("Failed to move up after retries")
        elseif args.direction == Direction.DOWN then
            error("Failed to move down after retries")
        end
    end
    return false
end

local function findBlock(placeableBlocks)
    -- if not array then make placeableBlocks an array
    if placeableBlocks ~= nil and type(placeableBlocks) ~= "table" then
        placeableBlocks = {placeableBlocks}
    end

    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            if placeableBlocks == nil then
                turtle.select(slot)
                return true
            end

            local detail = turtle.getItemDetail(slot)
            if detail and detail.name then
                for _, block in ipairs(placeableBlocks) do
                    if detail.name == block then
                        turtle.select(slot)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function findBlockAndPlace(args)
    args = tableUtil.fillDefaults(args, {
        placeableBlocks = nil, -- any
        place = turtle.place
    })
    if findBlock(args.placeableBlocks) then
        return args.place()
    end
    return false, "Cannot find block"
end

local function ensurePlace(args)
    args = tableUtil.fillDefaults(args, {
        direction = Direction.FORWARD,
        placeableBlocks = nil, -- any
        retries = 1,
        attack = false,
        sleepTime = 0,
        attackSide = nil,
        errorOut = false
    })

    local place = nil
    if args.direction == Direction.FORWARD then
        place = turtle.place
    elseif args.direction == Direction.UP then
        place = turtle.placeUp
    elseif args.direction == Direction.DOWN then
        place = turtle.placeDown
    end

    if place == nil then
        error("Invalid direction for ensurePlace")
    end

    for i = 1, args.retries do
        local result = findBlockAndPlace({
            placeableBlocks = args.placeableBlocks,
            place = place
        })
        if result then
            return true
        end

        if args.attack then
            turtle.attack(args.attackSide)
        end

        if args.sleepTime > 0 then
            os.sleep(args.sleepTime)
        end
    end
    if args.errorOut then
        error("Failed to place block after retries")
    end
    return false, "Failed to place block after retries"
end

local function ensureDig(args)
    args = tableUtil.fillDefaults(args, {
        direction = Direction.FORWARD,
        retries = 1,
        sleepTime = 0,
        errorOut = false
    })

    local dig = nil
    if args.direction == Direction.FORWARD then
        dig = turtle.dig
    elseif args.direction == Direction.UP then
        dig = turtle.digUp
    elseif args.direction == Direction.DOWN then
        dig = turtle.digDown
    end

    if dig == nil then
        error("Invalid direction for ensureDig")
    end

    for i = 1, args.retries do
        local hasDug, reason = dig()
        if hasDug then
            return true
        elseif reason == "Nothing to dig here" then
            return true
        end

        if args.sleepTime > 0 then
            os.sleep(args.sleepTime)
        end
    end
    if args.errorOut then
        if args.direction == Direction.FORWARD then
            error("Failed to dig forward after retries")
        elseif args.direction == Direction.UP then
            error("Failed to dig up after retries")
        elseif args.direction == Direction.DOWN then
            error("Failed to dig down after retries")
        end
    end
    return false, "Failed to dig after retries"
end

local function oppositeDirection(direction)
    return (direction + 2) % 4
end

local function ensureReplace(args)
    args = tableUtil.fillDefaults(args, {
        direction = Direction.FORWARD,
        placeableBlocks = nil, -- any
        retries = 1,
        attack = false,
        sleepTime = 0,
        attackSide = nil,
        errorOut = false
    })

    -- turn placeableBlocks into array
    if args.placeableBlocks ~= nil and type(args.placeableBlocks) ~= "table" then
        args.placeableBlocks = {args.placeableBlocks}
    end

    local inspect = nil
    if args.direction == Direction.FORWARD then
        inspect = turtle.inspect
    elseif args.direction == Direction.UP then
        inspect = turtle.inspectUp
    elseif args.direction == Direction.DOWN then
        inspect = turtle.inspectDown
    end

    local replace = function()
        return ensureDig(args) and ensurePlace(args)
    end

    if replace == nil or inspect == nil then
        error("Invalid direction for ensureReplace")
    end

    for i = 1, args.retries do
        local hasBlock, inspectResult = inspect()
        if hasBlock and inspectResult.name ~= nil and
            (args.placeableBlocks == nil or tableUtil.contains(args.placeableBlocks, inspectResult.name)) then
            return true
        end

        local result = replace()
        if result then
            return true
        end

        if args.attack then
            turtle.attack(args.attackSide)
        end

        if args.sleepTime > 0 then
            os.sleep(args.sleepTime)
        end
    end
    if args.errorOut then
        error("Failed to replace block after retries")
    end
    return false, "Failed to replace block after retries"
end

return {
    setRotation = setRotation,
    Rotation = Rotation,
    Direction = Direction,
    oppositeDirection = oppositeDirection,
    safeMove = safeMove,
    findBlock = findBlock,
    ensurePlace = ensurePlace,
    ensureDig = ensureDig,
    ensureReplace = ensureReplace,
    turnAround = turnAround,
    currentRotation = function() return currentRotation end
}
