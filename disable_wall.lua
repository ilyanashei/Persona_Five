local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local DEBUG = true

local function dprint(...)
	if DEBUG then print("[WallRemover]", ...) end
end

local function deleteWall(wall)
	if wall and wall:IsA("BasePart") then
		dprint("═══════════════════════════════")
		dprint("Found Wall!")
		dprint("Path:", wall:GetFullName())
		dprint("Position:", wall.Position)
		
		wall:Destroy()
		
		dprint("✓ WALL DELETED!")
		dprint("═══════════════════════════════")
		return true
	end
	return false
end

-- Search for Wall parts in all courts
local function findAndDeleteWalls()
	local found = 0
	
	-- Find Courts folder
	local courtsFolder = workspace:FindFirstChild("Courts")
	
	if courtsFolder then
		dprint("Found Courts folder, scanning all courts...")
		
		-- Go through every court
		for _, court in ipairs(courtsFolder:GetChildren()) do
			dprint("Scanning court:", court.Name)
			
			-- Look for "Wall" parts in this court
			for _, child in ipairs(court:GetDescendants()) do
				if child.Name == "Wall" and child:IsA("BasePart") then
					if deleteWall(child) then
						found = found + 1
					end
				end
			end
		end
	else
		dprint("WARNING: Courts folder not found in Workspace!")
	end
	
	return found
end

-- Initial search
dprint("Searching for Wall parts in all courts...")
local found = findAndDeleteWalls()
dprint("Deleted", found, "walls across all courts")

-- Monitor for new courts or walls being added
workspace.DescendantAdded:Connect(function(obj)
	-- Check if it's a wall being added to any court
	if obj.Name == "Wall" and obj:IsA("BasePart") then
		-- Verify it's inside a court
		local parent = obj.Parent
		while parent do
			if parent.Parent == workspace:FindFirstChild("Courts") then
				task.wait(0.1)
				deleteWall(obj)
				break
			end
			parent = parent.Parent
		end
	end
end)

dprint("═══════════════════════════════")
dprint("WALL REMOVER ACTIVE")
dprint("═══════════════════════════════")
dprint("Monitoring and deleting all Wall parts in all courts")
dprint("Including regular courts, ranked courts, and KOTC")
dprint("Try walking through any net now!")
dprint("═══════════════════════════════")
