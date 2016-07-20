local inspect 	= require "inspect"
local class 	= require "middleclass"
local Dungeon 	= require "dungeon"

--Union-Find "class"
local SetMap = {}

function MakeSet(value)
	local set = {}
	set.value = value
	set.rank = 0
	set.parent = set
	SetMap[set] = set
	return set
end

function FindSet(x)
	local parent = x
	if parent ~= parent.parent then
		parent = FindSet(parent.parent)
	end
	return parent
end

function getSetByValue(x)
	for i = 1, #SetMap do
		local set = SetMap[i]
		if set.value == x then
			return set
		end
	end
end

function Union(x, y)
	local xRoot = FindSet(x)
	local yRoot = FindSet(y)

	if xRoot.value == yRoot.value then return end

	if xRoot.rank >= yRoot.rank then
		if xRoot.rank == yRoot.rank then xRoot.rank = xRoot.rank + 1 end
		yRoot.parent = xRoot
	else
		xRoot.parent = yRoot
	end
end

local function getPointsIndex(points, point)
	for i = 1, #points do
		local p = points[i]
		if p == point then return i end
	end
end

-- Make set takes a value, stores the set under SetMap[set], and outputs the set
-- local u = MakeSet(3)
-- local v = MakeSet(4)
-- print(inspect(SetMap))
-- print(FindSet(u))
-- print(FindSet(v))
-- Union(u, v)
-- print(FindSet(u))
-- print(FindSet(v))

--[[
What Do I Need:
	* First of all I need the union the start and end points of a edge
	* Store the edge length as the value for both sets
	* Krukals algorithm
	* Sort through the values and add an edge to a table that its length matches the given value
	* Draw it!
]]

local function generate()
	DungeonMap = Dungeon:initialize()
	local points = Dungeon:getPoints()
	local sets = {}
	for i = 1, #points do
		local point = points[i]
		table.insert(sets, MakeSet(point))
	end

	for i = 1, #sets do
		print(sets[i].value, i, getPointsIndex(points, sets[i].value))
	end

	triangles = Dungeon:getTriangles(points)

	MSTEdges = {}
	edges = Dungeon:getEdges(triangles)
	for i = 1, #edges do
		local p1, p2 = edges[i].p1, edges[i].p2
		local i1, i2 = getPointsIndex(points, p1), getPointsIndex(points, p2)
		if FindSet(sets[i1]) ~= FindSet(sets[i2]) then
			table.insert(MSTEdges, edges[i])
			Union(sets[i1], sets[i2])
		end
	end
	print(#edges, #MSTEdges)
end

function love.load()
	generate()
end

function love.draw()
	Dungeon:draw(DungeonMap)
	Dungeon:drawTriangles(triangles)
	Dungeon:drawEdges(MSTEdges)
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
end