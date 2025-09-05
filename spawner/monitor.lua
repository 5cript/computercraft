package.path = "../?.lua;" .. package.path

local basalt = require("basalt")
local tableUtil = require("lib.table")
local modem = peripheral.find("modem")
local ownChannel = os.getComputerID()
local file = fs.open('/config/spawnerControl.lua', 'r')

if not modem then
    print("No modem found")
    return
end

modem.open(ownChannel)

local spawners = {}

if file then
    local contents = file.readAll()
    local config = textutils.unserialize(contents)
    if config and type(config) == "table" then
        print("Loading config")
        for name, spawnerConfig in pairs(config.spawners) do
            print(" - " .. name)
            spawners[name] = tableUtil.fillDefaults(spawnerConfig, {
                channel = 1,
                status = false,
                displayName = name,
                command = "top"
            })
            tableUtil.dump(spawners[name])
        end
    end
    tableUtil.dump(spawners)
    file.close()
else
    error("Create a config at /config/spawnerControl.lua")
end


local main = basalt.createFrame()
local spawnerCounter = 0

function addSpawnerControl(info)
    local button = main:addButton()
    button:setPosition(2, spawnerCounter * 4 + 2)
    spawnerCounter = spawnerCounter + 1
    button:setSize(16, 3)
    button:setText(info.displayName .. " Off")

    local renderStatus = function()
        if info.status then
            button:setText(info.displayName .. " On")
            button:setBackground(colors.green)
            modem.transmit(info.channel, ownChannel, info.command .. "On")
        else
            button:setText(info.displayName .. " Off")
            button:setBackground(colors.red)
            modem.transmit(info.channel, ownChannel, info.command .. "Off")
        end
    end
    renderStatus()

    button:setBackground(colors.red)
    button:onClick(function()
        info.status = not info.status
        renderStatus()
    end)
end

for name, spawner in pairs(spawners) do
    addSpawnerControl(spawner)
end

main:setBackground(colors.black)
basalt.run()
