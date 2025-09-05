local modem = peripheral.find("modem") or error("No modem found")

print("Opening modem: " .. os.getComputerID())
modem.open(os.getComputerID())

while true do
    local event, side, freq, replyFreq, msg, dist = os.pullEvent("modem_message")
    print("Received message: ", msg)
    if msg == "bottomOn" then
        print("Turning bottom on")
        redstone.setOutput("bottom", true)
    end
    if msg == "bottomOff" then
        print("Turning bottom off")
        redstone.setOutput("bottom", false)
    end
    if msg == "topOn" then
        print("Turning on top")
        redstone.setOutput("top", true)
    end
    if msg == "topOff" then
        print("Turning top off")
        redstone.setOutput("top", false)
    end
    if msg == "frontOn" then
        print("Turning front on")
        redstone.setOutput("front", true)
    end
    if msg == "frontOff" then
        print("Turning front off")
        redstone.setOutput("front", false)
    end
    if msg == "backOn" then
        print("Turning back on")
        redstone.setOutput("back", true)
    end
    if msg == "backOff" then
        print("Turning back off")
        redstone.setOutput("back", false)
    end
    if msg == "leftOn" then
        print("Turning left on")
        redstone.setOutput("left", true)
    end
    if msg == "leftOff" then
        print("Turning left off")
        redstone.setOutput("left", false)
    end
    if msg == "rightOn" then
        print("Turning right on")
        redstone.setOutput("right", true)
    end
    if msg == "rightOff" then
        print("Turning right off")
        redstone.setOutput("right", false)
    end
end