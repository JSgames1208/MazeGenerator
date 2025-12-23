--!strict

--[[


DEMO VIDEO:

https://drive.google.com/file/d/1Jvolb5DOQJ1Mh5wmxF1DcH-S1w-6vyqn/view?usp=sharing


]]

local MazeGenerator = {}
MazeGenerator.__index = MazeGenerator

------------------------
-- EXAMPLE USAGE
------------------------

--[[

local MazeGenerator = require($path_to_MazeGenerator)

local width = 10
local height = 10
MazeGenerator.generate(width, height)

MazeGenerator.cleanup()

]]

------------------------
-- DEFAULT CONFIG
------------------------

MazeGenerator.cellSize = 4
MazeGenerator.wallThickness = 0.5
MazeGenerator.wallHeight = 10
MazeGenerator.wallColor = Color3.fromRGB(100, 100, 100)
MazeGenerator.parentFolderName = "mazeParts"

-------------------------
-- TYPE DEF
------------------------

export type Cell = {
	x: number,
	y: number,
	visited: boolean,
	walls: {
		top: boolean,
		right: boolean,
		bottom: boolean,
		left: boolean,
	},
}

-------------------------
-- INTERNAL STATE
-------------------------

local grid: { { Cell } } = {}
local mazeParts: { Instance } = {}
local parentFolder: Folder? = nil
local currentWidth = 0
local currentHeight = 0

--------------------------
-- DIRECTION TABLE
--------------------------

local directions = {
	{ dx = 0, dy = -1, name = "top", opposite = "bottom" },
	{ dx = 0, dy = 1, name = "bottom", opposite = "top" },
	{ dx = -1, dy = 0, name = "left", opposite = "right" },
	{ dx = 1, dy = 0, name = "right", opposite = "left" },
}

--------------------------
-- UTILS
--------------------------

local function ensureParent()
	if parentFolder and parentFolder.Parent then
		return parentFolder
	end

	local folder = workspace:FindFirstChild(MazeGenerator.parentFolderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = MazeGenerator.parentFolderName
		folder.Parent = workspace
	end

	parentFolder = folder
	return parentFolder :: Folder -- This is always a folder because we ensure it exists above
end

--------------------------
-- GRID CREATION & HELPERS
--------------------------

local function initGrid(width: number, height: number)
	width = math.floor(math.clamp(width, 1, 200))
	height = math.floor(math.clamp(height, 1, 200))

	grid = {}
	for x = 1, width do
		grid[x] = {}
		for y = 1, height do
			grid[x][y] = {
				x = x,
				y = y,
				visited = false,
				walls = {
					top = true,
					right = true,
					bottom = true,
					left = true,
				},
			}
		end
	end

	currentWidth = width
	currentHeight = height
end

local function cellExists(x: number, y: number): boolean
	return grid[x] ~= nil and grid[x][y] ~= nil
end

--------------------------
-- MAZE GENERATION
--------------------------

local function shuffleTable(t: { any })
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function carve(x: number, y: number)
	local cell = grid[x][y]
	cell.visited = true

	local ds = {}
	for _, d in ipairs(directions) do
		table.insert(ds, d)
	end
	ds = shuffleTable(ds)

	for _, d in ipairs(ds) do
		local nx = x + d.dx
		local ny = y + d.dy

		if cellExists(nx, ny) and not grid[nx][ny].visited then
			cell.walls[d.name] = false
			grid[nx][ny].walls[d.opposite] = false
			carve(nx, ny)
		end
	end
end

--------------------------
-- SPAWNING HELPERS
--------------------------

local function makeWallPart(size: Vector3, pos: Vector3): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.Position = pos
	part.Color = MazeGenerator.wallColor
	part.Name = "mazeWall"
	return part
end

local function cellCenterPosition(cellX: number, cellY: number): Vector3
	local cellSize = MazeGenerator.cellSize
	local offsetX = (currentWidth + 1) * cellSize * 0.5
	local offsetY = (currentHeight + 1) * cellSize * 0.5
	local xPos = cellX * cellSize - offsetX
	local yPos = cellY * cellSize - offsetY
	return Vector3.new(xPos, 0, yPos)
end

local function spawnWallForCell(cell: Cell, dir: string)
	local cellSize = MazeGenerator.cellSize
	local halfSize = cellSize * 0.5
	local thickness = MazeGenerator.wallThickness
	local height = MazeGenerator.wallHeight
	local center = cellCenterPosition(cell.x, cell.y)
	local size: Vector3
	local pos: Vector3

	if dir == "top" then
		size = Vector3.new(cellSize, height, thickness)
		pos = center + Vector3.new(0, 0, -halfSize)
	elseif dir == "bottom" then
		size = Vector3.new(cellSize, height, thickness)
		pos = center + Vector3.new(0, 0, halfSize)
	elseif dir == "left" then
		size = Vector3.new(thickness, height, cellSize)
		pos = center + Vector3.new(-halfSize, 0, 0)
	elseif dir == "right" then
		size = Vector3.new(thickness, height, cellSize)
		pos = center + Vector3.new(halfSize, 0, 0)
	end

	local part = makeWallPart(size, pos)
	part.Parent = ensureParent()
	table.insert(mazeParts, part)
end

--------------------------
-- SPAWNING & REMOVAL
--------------------------

local function spawnMazeFromGrid()
	for x = 1, currentWidth do
		for y = 1, currentHeight do
			local cell = grid[x][y]
			for dir, exists in pairs(cell.walls) do
				if exists then
					spawnWallForCell(cell, dir)
				end
			end
		end
	end
end

local function removeAllParts()
	for i = #mazeParts, 1, -1 do
		local part = mazeParts[i]
		if part and part.Parent then
			part:Destroy()
		end
		table.remove(mazeParts, i)
	end
end

--------------------------
-- PUBLIC API
--------------------------

function MazeGenerator.generate(width: number, height: number)
	if typeof(width) ~= "number" or typeof(height) ~= "number" then
		error("width or height are not numbers!")
	end

	-- clamp width and height to 1-100 for sanity
	width = math.floor(math.clamp(width, 1, 100))
	height = math.floor(math.clamp(height, 1, 100))

	MazeGenerator.cleanup()

	initGrid(width, height)

	carve(1, 1)
	spawnMazeFromGrid()
end

function MazeGenerator.cleanup()
	removeAllParts()
	table.clear(mazeParts)
	table.clear(grid)
	currentHeight = 0
	currentWidth = 0
end

-- change config
function MazeGenerator.setCellSize(size: number)
	assert(type(size) == "number" and size > 0, "cell size must be a non-zero positive number")
	MazeGenerator.cellSize = size
end

function MazeGenerator.setWallThickness(thickness: number)
	assert(type(thickness) == "number" and thickness > 0, "thickness size must be a non-zero positive number")
	MazeGenerator.wallThickness = thickness
end

function MazeGenerator.setWallHeight(height: number)
	assert(type(height) == "number" and height > 0, "thickness size must be a non-zero positive number")
	MazeGenerator.wallHeight = height
end

function MazeGenerator.setWallColor(color: Color3)
	MazeGenerator.wallColor = color
end

function MazeGenerator.setParentFolderName(name: string)
	assert(type(name) == "string", "name must be a string")
	MazeGenerator.parentFolderName = name
end

-- getters
function MazeGenerator.getWidth(): number
	return currentWidth
end

function MazeGenerator.getHeight(): number
	return currentHeight
end

function MazeGenerator.getCell(x: number, y: number): Cell?
	if not cellExists(x, y) then
		return nil
	end
	return grid[x][y]
end

function MazeGenerator.getAllCells(): { Cell }
	local cells = {}
	for x = 1, currentWidth do
		for y = 1, currentHeight do
			table.insert(cells, grid[x][y])
		end
	end
	return cells
end

return MazeGenerator
