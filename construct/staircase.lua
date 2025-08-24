-- Set the width and height of each step
local stepWidth = 3
local stepHeight = 5
local depth = 0
local lor = 1
local directionFlip = false

local function turnLeft()
    if (lor == 0 or directionFlip) then
        turtle.turnRight()
    else
        turtle.turnLeft()
    end
end

local function turnRight()
    if (lor == 0 or directionFlip) then
        turtle.turnLeft()
    else
        turtle.turnRight()
    end
end

local function resetDirection(x)
    if x % 2 == 0 then
        turnRight()
    else
        turnLeft()
        directionFlip = not directionFlip
    end
end

local function digRowInitial(digUp)
    if stepWidth > 1 then
        for i = 1, stepWidth - 1, 1 do
            turtle.dig()
            turtle.digDown()
            if digUp then
                turtle.digUp()
            end
            turtle.forward()
        end
        turtle.digDown()
        if digUp then
            turtle.digUp()
        end
    end
end


local function digRowSecondary(digUp)
    if stepWidth > 1 then
        for i = 1, stepWidth - 1, 1 do
            turtle.dig()
            if digUp then
                turtle.digUp()
            end
            turtle.forward()
        end
        if digUp then
            turtle.digUp()
        end
    end
end

local function digRow(y, h)
    local digUp = (h - y) >= 2
    if y == 1 then
        digRowInitial(digUp)
    else
        digRowSecondary(digUp)
    end
end

-- Function to build a single step
local function buildStep(depth)
    turtle.dig()
    turtle.forward()
    turnLeft()
    print("New Step")

    for i = 1, stepHeight - 1, 2 do
        print("Row: " .. (math.floor(i / 2) + 1))
        digRow(i, stepHeight)
        turnRight()
        turnRight()
        if i+1 < stepHeight - 1 then
            turtle.up()
            turtle.digUp()
            turtle.up()
        end
    end

    local rowsDug = math.floor(stepHeight / 2)
    print("Rows Dug: " .. rowsDug)
    resetDirection(rowsDug)

    print("Going Down")
    -- maybe wrong:
    for i = 1, (rowsDug - 1) * 2, 1 do
        turtle.down()
    end

    turtle.down()
end

-- Function to build the entire staircase
local function buildStaircase()
    for i = 1, depth, 1 do
        buildStep()
    end
end

local function askParameters()
    write ("Width: ")
	stepWidth = tonumber(read())

    if stepWidth < 1 then
        print ("stepWidth must be at least 1")
        shell.exit()
    end

	write ("Height: ")
	stepHeight = tonumber(read())

    if stepHeight < 2 then
        print ("Height must be at least 2")
        shell.exit()
    end

	write ("Depth: ")
	depth = tonumber(read())

    if depth < 1 then
        print ("Depth must be at least 1")
        shell.exit()
    end

    write ("Left or Right (l/r)?")
    local lor_pre = read()

	-- valid input?
	if lor_pre == "r" then
		lor = 0
	elseif lor_pre == "l" then
		lor = 1
	else
		print ("invalid input")
		shell.exit()
	end
end

askParameters()
buildStaircase()