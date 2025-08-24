local args = { ... }

-- NORTH = 0
-- EAST = 1
-- SOUTH = 2
-- WEST = 3


directionFaceing = 0

function tryRefuel() 
  if (turtle.getFuelLevel() < 100) then
    turtle.select(1)
    turtle.refuel(1)
  end
end

function searchBlock()
  for i = 2, 15, 1 do
    if turtle.getItemCount(i) > 0 then
	  turtle.select(i)
	  return true
	end
  end
  return false
end

function changeDirection() 
  if directionFaceing == 0 then
    turtle.turnLeft()
  else 
    if directionFaceing == 1 then
      turtle.turnLeft()
    else 
	  if directionFaceing == 2 then
        turtle.turnRight()
      else
        turtle.turnRight()	 
      end
	end
  end
	
  directionFaceing = directionFaceing + 1
  
  if directionFaceing == 4 then
    directionFaceing = 0
  end
end

function quadPlatform(size)
  for i = 1, size, 1 do
    tryRefuel()
    for j = 0, size, 1 do
	  if (searchBlock() == false) then
	    os.shutdown()
	  end
      turtle.placeDown()
	  if j < (size - 1) then
	    turtle.forward()
      end
	end
	
	if i <= (size - 1) then
	  changeDirection()
	  turtle.forward()
	  changeDirection()
    end
  end
end

----- MAIN -----

quadPlatform(args[1])
