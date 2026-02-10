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
		dprint("CanCollide was:", wall.CanCollide)
		dprint("CanTouch was:", wall.CanTouch)
		
		-- Disable collision and touch
		wall.CanCollide = false
		wall.CanTouch = false
		wall.CanQuery = false
		
		-- Make it invisible (optional - remove if you want to see it)
		wall.Transparency = 1
		
		-- Add to tracked list
		trackedWalls[wall] = true
		
		dprint("CanCollide now:", wall.CanCollide)
		dprint("CanTouch now:", wall.CanTouch)
		dprint("✓ WALL DISABLED!")
		dprint("═══════════════════════════════")
		return true
	end
	return false
end

-- Search for Wall parts in all courts
local function findAndDisableWalls()
	local found = 0
	
	-- Find Courts folder
	local courtsFolder = workspace:FindFirstChild("Courts")
	
	if courtsFolder then
		dprint("Found Courts folder, scanning all courts...")
		dprint("Number of courts found:", #courtsFolder:GetChildren())
		
		-- Go through every court
		for _, court in ipairs(courtsFolder:GetChildren()) do
			dprint("---")
			dprint("Checking court:", court.Name, "| Type:", court.ClassName)
			
			-- Look for Wall directly in Court
			local wall = court:FindFirstChild("Wall")
			if wall then
				dprint("  Found Wall in", court.Name, "!")
				if disableWall(wall) then
					found = found + 1
				end
			else
				dprint("  ERROR: No Wall found directly in court")
				local children = {}
				for _, child in ipairs(court:GetChildren()) do
					table.insert(children, child.Name)
				end
				dprint("  Court children:", table.concat(children, ", "))
			end
		end
	else
		dprint("WARNING: Courts folder not found in Workspace!")
	end
	
	return found
end

-- Initial search
dprint("Searching for Wall parts in all courts...")
local found = findAndDisableWalls()
dprint("Disabled", found, "walls across all courts")

-- Monitor for new walls being added
workspace.DescendantAdded:Connect(function(obj)
	if obj.Name == "Wall" and obj:IsA("BasePart") then
		-- Check if it's directly in a Court: Courts > Court > Wall
		local court = obj.Parent
		if court and court.Parent == workspace:FindFirstChild("Courts") then
			task.wait(0.1)
			disableWall(obj)
		end
	end
end)

-- Monitor for walls being removed from tracking
workspace.DescendantRemoving:Connect(function(obj)
	if trackedWalls[obj] then
		trackedWalls[obj] = nil
	end
end)

-- OPTIMIZED: Only check tracked walls
-- Run less frequently (every 0.5 seconds)
local lastCheck = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastCheck < 0.5 then return end
	lastCheck = now
	
	-- Re-disable walls if they get re-enabled
	for wall, _ in pairs(trackedWalls) do
		if not wall.Parent then
			trackedWalls[wall] = nil
		else
			if wall.CanCollide or wall.CanTouch then
				wall.CanCollide = false
				wall.CanTouch = false
				wall.CanQuery = false
			end
		end
	end
end)

dprint("═══════════════════════════════")
dprint("WALL REMOVER ACTIVE (NO COLLISION)")
dprint("═══════════════════════════════")
dprint("Walls are now passable - walk through the net!")
dprint("═══════════════════════════════")
