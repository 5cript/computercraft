turtle.select(1)

local timeout = 1000
while turtle.getItemCount(1) > 0 do
  turtle.place()
  turtle.dig()
  timeout = timeout-1
  if timeout == 0 then
    break
  end
end
