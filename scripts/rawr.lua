--- Turns 180 degrees in a direction of your choice
function turnAround(direction)
	if direction then
		turtle.turnRight()
		turtle.turnRight()

		return
	end

		turtle.turnLeft()
		turtle.turnLeft()

end

function nextInvSlot(startSlot, endSlot, minCount)
	local i = startSlot

	while i <= endSlot do
		if turtle.getItemCount(i)>minCount then
			return i
		end
	end
end

function blockPlace(top)
	turtle.select(nextInvSlot(2, 16, 1))

	turtle.turnLeft()
	turtle.place()
	turnAround(true)
	turtle.place()
	turtle.turnLeft()

	if top then
		turtle.placeUp()
	end

end

--- A really dumb way of refueling
function smartRefuel(minLevel)
	if turtle.getFuelLevel()<minLevel then
		turtle.select(1)
		turtle.refuel()
	end
end

--- Gets the first slot that has less than 64 values.
--- Returns -1 if no slots are availible.
function nextAvailibleSlot(slotArr)
	local i = 0

	while i < slotArr.length do
		if turtle.getItemCount(i+1) < 64 then
			return i + 1
		end
	end

	return -1
end

--- Uses recursion to mine ore when strip mining.
--- May miss ores that are spawned in oddly.
function oreHandler(blockData, checkUp)
	if data.name == "minecraft:flowing_lava" then
		if turtle.getItemCount(slot) == 64 then
			return
		end

		turtle.select(1)

		if checkUp then
			turtle.placeUp()
		else
			turtle.place()
		end

		turtle.refuel()
	else
		local slotArr = slotMap[data.name]

		if slotArr.length > 0 then
			turtle.select(slot)

			if checkUp then
				turtle.digUp()
			else
				turtle.dig()
			end
		end
	end
end

--- Function for strippin'
function strip(depth)
	local i = 0
	print(depth)

	while i<depth do
		turtle.dig()
		turtle.forward()

		success, data = turtle.inspect()
		if success then
			oreHandler(data, false)
		end

		blockPlace(false)

		turtle.digUp()
		turtle.up()

		success, data = turtle.inspect()
		if success then
			oreHandler(data, true)
		end

		blockPlace(true)

		turtle.down()

		i = i + 1
	end

	return 0

end

--- Travel forward 'dist' number of blocks
function travel(dist)
	local i = 0

	while i < dist do
		turtle.forward()

		i = i + 1
	end
end


--- This will make a turtle strip for you.
--- Make sure you pay it before you start,
--- otherwise you'll be dissapointed. <3
args = { ... }

stripDepth = tonumber(args[1])
spacing = tonumber(args[2])
spacing = spacing + 1

slotMap = {
	--- Bucket slot 1
	["minecraft:coal_ore"] = {2},
	["minecraft:cobblestone"] = {3, 4},
	["minecraft:iron_ore"] = {5, 6, 7, 8},
	["minecraft:lapis_ore"] = {10 ,11, 12},
	["minecraft:redstone_ore"] = {9, 13},
	["minecraft:gold_ore"] = {14},
	["minecraft:emerald_ore"] = {15},
	["minecraft:diamond_ore"] = {16},
}

--- These variables are used to navigate to and from storage
shaftCount = 0
depthCount = 0

turtle.refuel()

--- Main
while true do

	if strip(spacing) ~= 0 then
		turnAround(true)

		travel(spacing*shaftCount)
		turnAround()
		return
	end

	turtle.turnRight()
	shaftCount = shaftCount + 1

	if strip(stripDepth) ~= 0 then
		turnAround(true)

		travel(stripDepth)

		turtle.turnLeft()

		travel(spacing*shaftCount)
		turnAround()
		return
	end

	turnAround(false)

	travel(stripDepth)

	turtle.turnRight()

end