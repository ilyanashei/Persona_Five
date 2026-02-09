local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local DEBUG = true

local function dprint(...)
	if DEBUG then print("[WallRemover]", ...) end
end

-- Track all walls we've found
local trackedWalls = {}

local function disableWall(wall)
	if wall and wall:IsA("BasePart") then
		dprint("═══════════════════════════════")
		dprint("Found Wall!")
		dprint("Path:", wall:GetFullName())
		dprint("Position:", wall.Position)
		dprint("CanCollide was:", wall.CanCollide)
		
		wall.CanCollide = false
		
		-- Add to tracked list
		trackedWalls[wall] = true
		
		dprint("CanCollide now:", wall.CanCollide)
		dprint("✓ WALL DISABLED!")
		dprint("═══════════════════════════════")
		return true
	end
	return false
end

-- Search for Wall part
local function findAndDisableWalls()
	local found = 0
	
	-- Check common parent locations
	local searchLocations = {
		workspace:FindFirstChild("Net"),
		workspace:FindFirstChild("Collision"),
		workspace:FindFirstChild("Map"),
		workspace,
	}
	
	for _, location in ipairs(searchLocations) do
		if location then
			-- Look for "Wall" parts
			for _, child in ipairs(location:GetDescendants()) do
				if child.Name == "Wall" and child:IsA("BasePart") then
					if disableWall(child) then
						found = found + 1
					end
				end
			end
		end
	end
	
	return found
end

-- Initial search
dprint("Searching for Wall parts...")
local found = findAndDisableWalls()
dprint("Disabled", found, "walls")

-- Monitor for new Wall parts being added
workspace.DescendantAdded:Connect(function(obj)
	if obj.Name == "Wall" and obj:IsA("BasePart") then
		task.wait(0.1)  -- Wait a moment for it to fully load
		disableWall(obj)
	end
end)

-- Monitor for walls being removed from tracking
workspace.DescendantRemoving:Connect(function(obj)
	if trackedWalls[obj] then
		trackedWalls[obj] = nil
	end
end)

-- OPTIMIZED: Only check tracked walls, not all descendants
-- Run less frequently (every 0.5 seconds instead of every frame)
local lastCheck = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastCheck < 0.5 then return end -- Only check twice per second
	lastCheck = now
	
	-- Clean up destroyed walls
	for wall, _ in pairs(trackedWalls) do
		if not wall.Parent then
			trackedWalls[wall] = nil
		elseif wall.CanCollide then
			wall.CanCollide = false
		end
	end
end)

dprint("═══════════════════════════════")
dprint("WALL REMOVER ACTIVE (OPTIMIZED)")
dprint("═══════════════════════════════")
dprint("Monitoring and disabling all Wall parts")
dprint("Try walking through the net now!")
dprint("═══════════════════════════════")
