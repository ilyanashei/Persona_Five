-- QUEUE SYSTEM - BACK TO WHAT WORKED
print("════════════════════════════════════════")
print("QUEUE SYSTEM LOADING")
print("════════════════════════════════════════")

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

getgenv().QUEUE_SYSTEM_RUNNING = true

-- Hash
local function hash(name)
    local h = 0
    for i = 1, #name do
        h = (h * 31 + string.byte(name, i)) % 1000000
    end
    return h
end

-- Get spots
local function getAllSpots()
    local courts = workspace:FindFirstChild("Courts")
    if not courts then return {} end
    
    local char = player.Character
    if not char then return {} end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    
    local closest = nil
    local closestDist = math.huge
    for _, court in ipairs(courts:GetChildren()) do
        local qs = court:FindFirstChild("QueueSpots")
        if qs then
            local dist = (hrp.Position - court:GetPivot().Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = court
            end
        end
    end
    
    if not closest then return {} end
    
    local spots = {}
    local qs = closest:FindFirstChild("QueueSpots")
    for team = 1, 2 do
        local folder = qs:FindFirstChild(tostring(team))
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("BasePart") then
                    table.insert(spots, child)
                end
            end
        end
    end
    
    return spots
end

-- Check occupied - MUST BE ON THE SPOT
local function isOccupied(spot)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if (hrp.Position - spot.Position).Magnitude < 3 then
                    return true
                end
            end
        end
    end
    return false
end

-- MAIN LOOP
print("════════════════════════════════════════")
print("STARTING")
print("════════════════════════════════════════")

local mySpot = nil
local hasQueued = false
local inGame = false

-- STAGGER START
local delay = math.random(10, 50) / 10
print(string.format("Waiting %.1fs before starting", delay))
task.wait(delay)

while getgenv().QUEUE_SYSTEM_RUNNING do
    task.wait(0.5)
    
    -- In game check
    if player.Team then
        if not inGame then
            print("✓ GAME STARTED")
            inGame = true
            if player.Character then
                local h = player.Character:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed = 16 end
            end
        end
        task.wait(3)
        continue
    else
        if inGame then
            print("✗ GAME ENDED")
            inGame = false
            mySpot = nil
            hasQueued = false
            local d = math.random(10, 60) / 10
            print(string.format("Waiting %.1fs before requeue", d))
            task.wait(d)
        end
    end
    
    -- Already queued - LOCK
    if hasQueued then
        task.wait(5)
        continue
    end
    
    -- Find spot ONCE
    if not mySpot then
        local spots = getAllSpots()
        if #spots == 0 then
            task.wait(3)
            continue
        end
        
        local h = hash(player.Name)
        
        -- Try spots starting from hash
        for i = 1, #spots do
            local idx = ((h + i - 1) % #spots) + 1
            if not isOccupied(spots[idx]) then
                mySpot = spots[idx]
                print(string.format("Selected: %s", mySpot.Name))
                break
            end
            task.wait(0.1)
        end
        
        if not mySpot then
            task.wait(5)
            continue
        end
    end
    
    -- Teleport
    if player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- One more check before teleporting
            if isOccupied(mySpot) then
                print("Spot taken, finding new one")
                mySpot = nil
                task.wait(1)
                continue
            end
            
            hrp.CFrame = mySpot.CFrame + Vector3.new(0, 2, 0)
            print("Teleported")
            
            local h = player.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 0 end
            
            task.wait(1)
        end
    end
    
    -- Press F
    print("Pressing F")
    VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(3)
    VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    
    -- Verify - check ONLY our spot
    task.wait(0.5)
    
    local queued = false
    for _, p in ipairs(mySpot:GetDescendants()) do
        if p:IsA("ProximityPrompt") then
            local txt = (p.ActionText or p.ObjectText or ""):lower()
            print(string.format("Prompt: '%s'", txt))
            if txt:find("unqueue") then
                queued = true
                break
            end
        end
    end
    
    if queued then
        hasQueued = true
        print("✓ QUEUED - LOCKED")
    else
        print("✗ Not queued, retry")
        hasQueued = false
    end
    
    task.wait(2)
end

VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
print("════════════════════════════════════════")
print("STOPPED")
print("════════════════════════════════════════")
