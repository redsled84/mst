local class 	= require "middleclass"
local inspect   = require "inspect"
local Dungeon 	= class("Dungeon")

local Delaunay  = require 'delaunay'
local Point 	= Delaunay.Point
local Edge  	= Delaunay.Edge

math.randomseed(os.time())
math.random();math.random();math.random();

local tile_size = 10
local map = {}
local mapWidth = 100
local mapHeight = 100

local function makeMap()
	for y = 1, mapHeight do
		local temp = {}
		for x = 1, mapWidth do
			temp[#temp+1] = 0
		end
		table.insert(map, temp)
	end
end

local Rooms = {}

local function newArea(x, y, w, h)
	for my = y, y + h - 1 do
		for mx = x, x + w - 1 do
			map[my][mx] = 1
		end
	end
	table.insert(Rooms, {x = x, y = y, w = w, h = h, midpoint = {x = x + w / 2, y = y + h / 2}})
end

local function checkArea(x, y, w, h)
	for my = y, y + h - 1 do
		for mx = x, x + w - 1 do
			if map[my][mx] == 1 then
				return true
			end
		end
	end
	return false
end

local function getPosition(w, h)
	return math.random(1, mapWidth-w), math.random(1, mapHeight-h)
end

local function getDimensions(minRoomSize, maxRoomSize)
	return math.random(minRoomSize, maxRoomSize), math.random(minRoomSize, maxRoomSize)
end

local function shallowCopy(t1)
	local t2 = {}
	for k=1, #t1 do
		t2[k] = t1[k]
	end
	return t2
end

local failure = false
local maxRooms = 20
local numrooms = 0

local maxAttempts = 240
local attempts = 0
local minRoomSize, maxRoomSize = math.ceil(mapWidth * .06) , math.ceil(mapWidth * .15)

function Dungeon:initialize()
	makeMap()
	while not failure and numrooms < maxRooms do
		local w, h = getDimensions(minRoomSize, maxRoomSize)
		local x, y = getPosition(w, h)
		repeat
			w, h = getDimensions(minRoomSize, maxRoomSize)
			x, y = getPosition(w, h)

			if attempts >= maxAttempts then
				failure = true
				break
			end
			
			attempts = attempts + 1
		until not checkArea(x, y, w, h)

		if attempts >= maxAttempts then
			failure = true
			break
		end

		newArea(x, y, w, h)
		numrooms = numrooms + 1
	end

	return map
end

function Dungeon:getPoints()
	local points = {}
	for i = 1, #Rooms do
		local room = Rooms[i]
		local x = math.ceil(room.x + room.w / 2)
		local y = math.ceil(room.y + room.h / 2)
		points[i] = Point(x * tile_size, y * tile_size)
	end
	return points
end

function Dungeon:getTriangles(points)
	return Delaunay.triangulate(unpack(points))
end

local function compare(a, b) if a:length() < b:length() then return a end end
function Dungeon:getEdges(triangles)
	local edges = {}
	for i, triangle in ipairs(triangles) do
		table.insert(edges, Edge(triangle.p1, triangle.p2))
		table.insert(edges, Edge(triangle.p2, triangle.p3))
		table.insert(edges, Edge(triangle.p1, triangle.p3))
	end

	table.sort(edges, compare)

	--take care of dup edges
	--really inefficent, best way is just to load edges correctly without dupes
	local edgesDup = shallowCopy(edges)
	for i = #edges, 1, -1 do
		table.remove(edgesDup, i)

		for j = #edgesDup, 1, -1 do
			if edges[i]:same(edgesDup[j]) then
				table.remove(edges, i)
			end
		end

		edgesDup = shallowCopy(edges)
	end

	return edges
end

function Dungeon:draw(map)
	for y = 1, #map do
		local row = map[y]
		for x = 1, #row do
			if map[y][x] == 0 then
				love.graphics.setColor(0,0,0,255)
				love.graphics.rectangle('fill', x * tile_size, y * tile_size, tile_size, tile_size)
			end
			if map[y][x] == 1 then
				love.graphics.setColor(255,255,255)
				love.graphics.rectangle('fill', x * tile_size, y * tile_size, tile_size, tile_size)
				love.graphics.setColor(0,0,255,100)
				love.graphics.rectangle('line', x * tile_size, y * tile_size, tile_size, tile_size)
			end
			if map[y][x] == 2 then
				love.graphics.setColor(0,255,0)
				love.graphics.rectangle('fill', x * tile_size, y * tile_size, tile_size, tile_size)
			end
		end
	end

	for i = 1, #Rooms do
		local room = Rooms[i]
		love.graphics.setColor(255,0,0)
		love.graphics.rectangle('line', room.x * tile_size, room.y * tile_size, room.w * tile_size, room.h * tile_size)
	end
end

function Dungeon:drawTriangles(triangles)
	for i, triangle in ipairs(triangles) do
  		love.graphics.setColor(0,255,255,75)
  		love.graphics.polygon('line', triangle.p1.x, triangle.p1.y, triangle.p2.x, triangle.p2.y, triangle.p3.x, triangle.p3.y)
	end
end

function Dungeon:drawEdges(edges)
	for i = 1, #edges do
		local p1 = edges[i].p1
		local p2 = edges[i].p2
		love.graphics.setColor(0,255,0)
		love.graphics.line(p1.x - 1, p1.y - 1, p2.x - 1, p2.y - 1)
		love.graphics.line(p1.x, p1.y, p2.x, p2.y)
		love.graphics.line(p1.x + 1, p1.y + 1, p2.x + 1, p2.y + 1)
	end
end

return Dungeon