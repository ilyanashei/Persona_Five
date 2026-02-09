local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local DEBUG = true

local function dprint(...)
	if DEBUG then print("[WallRemover]", ...) end
end

local function disableWall(wall)
	if wall and wall:IsA("BasePart") then
		dprint("═══════════════════════════════")
		dprint("Found Wall!")
		dprint("Path:", wall:GetFullName())
		dprint("Position:", wall.Position)
		dprint("CanCollide was:", wall.CanCollide)
		
		wall.CanCollide = false
		
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

-- Continuously monitor in case collision gets re-enabled
RunService.Heartbeat:Connect(function()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Wall" and obj:IsA("BasePart") and obj.CanCollide then
			obj.CanCollide = false
		end
	end
end)

dprint("═══════════════════════════════")
dprint("WALL REMOVER ACTIVE")
dprint("═══════════════════════════════")
dprint("Monitoring and disabling all Wall parts")
dprint("Try walking through the net now!")
dprint("═══════════════════════════════")
