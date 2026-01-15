--[[
    RS TENNIS SERVE BOT - REVISED FLOW
    
    1. Teleport detected → Reset camera straight
    2. Move left/right ONLY to green marker center
    3. Flick camera to logged angle
    4. Serve
    
    Press P to cleanup
]]

print("=== SERVE BOT - REVISED ===")

-- Configs with BOTH pitch and yaw angles from manual testing
-- Team 1 (Red): RIGHT side Pitch -16.71° Yaw 70.65°, LEFT side Pitch -16.20° Yaw 109.13°
-- Team 2 (Blue): Same pitch, but yaw flipped 180° (opposite direction)
local SERVE_CONFIGS = {
    Side1Serve1 = {side="RIGHT", name="Red RIGHT", x=-46.07, z=20.49, pitch=-16.71, yaw=70.65},
    Side1Serve2 = {side="LEFT", name="Red LEFT", x=-46.32, z=-18.68, pitch=-16.20, yaw=109.13},
    Side2Serve1 = {side="RIGHT", name="Blue RIGHT", x=46.47, z=-20.13, pitch=-16.71, yaw=70.65 + 180},  -- Flipped
    Side2Serve2 = {side="LEFT", name="Blue LEFT", x=46.38, z=19.47, pitch=-16.20, yaw=109.13 + 180},   -- Flipped
}

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local marker = nil
local isServing = false
local running = true
local angleDisplay = nil  -- GUI for showing angles

local function createAngleDisplay()
    -- Remove old display
    if angleDisplay then
        angleDisplay:Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AngleDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    -- Create Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 100)
    frame.Position = UDim2.new(1, -260, 0, 10)  -- Top right
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.new(0, 1, 0)
    frame.Parent = screenGui
    
    -- Create TextLabel for pitch
    local pitchLabel = Instance.new("TextLabel")
    pitchLabel.Size = UDim2.new(1, 0, 0.5, 0)
    pitchLabel.Position = UDim2.new(0, 0, 0, 0)
    pitchLabel.BackgroundTransparency = 1
    pitchLabel.TextColor3 = Color3.new(1, 1, 1)
    pitchLabel.TextSize = 18
    pitchLabel.Font = Enum.Font.Code
    pitchLabel.Text = "Pitch: 0.00°"
    pitchLabel.Parent = frame
    
    -- Create TextLabel for yaw
    local yawLabel = Instance.new("TextLabel")
    yawLabel.Size = UDim2.new(1, 0, 0.5, 0)
    yawLabel.Position = UDim2.new(0, 0, 0.5, 0)
    yawLabel.BackgroundTransparency = 1
    yawLabel.TextColor3 = Color3.new(1, 1, 1)
    yawLabel.TextSize = 18
    yawLabel.Font = Enum.Font.Code
    yawLabel.Text = "Yaw: 0.00°"
    yawLabel.Parent = frame
    
    angleDisplay = screenGui
    
    -- Update loop
    task.spawn(function()
        while running and angleDisplay do
            local lookVec = camera.CFrame.LookVector
            
            -- Calculate pitch (vertical angle)
            local pitch = math.deg(math.asin(lookVec.Y))
            
            -- Calculate yaw (horizontal angle)
            local yaw = math.deg(math.atan2(lookVec.X, -lookVec.Z))
            
            pitchLabel.Text = string.format("Pitch: %.2f°", pitch)
            yawLabel.Text = string.format("Yaw: %.2f°", yaw)
            
            task.wait(0.05)
        end
    end)
end

local function log(msg)
    print("[ServeBot] " .. msg)
end

-- CLEANUP
local function cleanup()
    log("╔═══════════════════════════════════════════╗")
    log("║ CLEANUP (P pressed)                     ║")
    log("╠═══════════════════════════════════════════╣")
    
    running = false
    
    VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
    VIM:SendKeyEvent(false, Enum.KeyCode.A, false, game)
    VIM:SendKeyEvent(false, Enum.KeyCode.S, false, game)
    VIM:SendKeyEvent(false, Enum.KeyCode.D, false, game)
    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    log("║ ✓ Released all keys                      ║")
    
    if marker then
        marker:Destroy()
        marker = nil
        log("║ ✓ Removed marker                         ║")
    end
    
    if angleDisplay then
        angleDisplay:Destroy()
        angleDisplay = nil
        log("║ ✓ Removed angle display                  ║")
    end
    
    log("╠═══════════════════════════════════════════╣")
    log("║ Script stopped                           ║")
    log("╚═══════════════════════════════════════════╝")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        cleanup()
    end
end)

local function findCourt()
    local courts = workspace:FindFirstChild("Courts")
    if not courts then return nil end
    
    local closest = nil
    local closestDist = math.huge
    
    for _, court in ipairs(courts:GetChildren()) do
        local dist = (hrp.Position - court:GetPivot().Position).Magnitude
        if dist < closestDist then
            closest = court
            closestDist = dist
        end
    end
    
    return closest
end

local function createMarker(position)
    if marker then
        marker:Destroy()
    end
    
    marker = Instance.new("Part")
    marker.Name = "TargetMarker"
    marker.Size = Vector3.new(2, 0.5, 2)
    marker.Position = Vector3.new(position.X, position.Y + 0.25, position.Z)
    marker.Anchored = true
    marker.CanCollide = false
    marker.BrickColor = BrickColor.new("Bright green")
    marker.Material = Enum.Material.Neon
    marker.Transparency = 0.3
    marker.Parent = workspace
end

local function findServeSpot()
    local court = findCourt()
    if not court then return nil, nil, false end
    
    local matchKeySpots = court:FindFirstChild("MatchKeySpots")
    if not matchKeySpots then return nil, nil, false end
    
    local spots = {
        matchKeySpots:FindFirstChild("Side1Serve1"),
        matchKeySpots:FindFirstChild("Side1Serve2"),
        matchKeySpots:FindFirstChild("Side2Serve1"),
        matchKeySpots:FindFirstChild("Side2Serve2"),
    }
    
    local closest = nil
    local closestName = nil
    local closestDist = math.huge
    
    for _, spot in ipairs(spots) do
        if spot then
            local dist = (hrp.Position - spot.Position).Magnitude
            
            if dist < closestDist then
                closest = spot
                closestName = spot.Name
                closestDist = dist
            end
        end
    end
    
    -- Only consider it a serve position if VERY close to a serve spot (within 3 studs)
    if closestDist > 3 then
        log("╔═══════════════════════════════════════════╗")
        log("║ I AM RECEIVER                            ║")
        log(string.format("║ (Closest serve spot: %.1f studs away)", closestDist))
        log("╚═══════════════════════════════════════════╝")
        return nil, nil, false
    end
    
    if not closest then return nil, nil, false end
    
    local config = SERVE_CONFIGS[closestName]
    
    log("╔═══════════════════════════════════════════╗")
    log("║ I AM SERVER                              ║")
    log("╠═══════════════════════════════════════════╣")
    log(string.format("║ Spot: %s (%s)", closestName, config.name))
    log(string.format("║ Side: %s", config.side))
    log(string.format("║ Pitch: %.2f° Yaw: %.2f°", config.pitch, config.yaw))
    log("╚═══════════════════════════════════════════╝")
    
    return config, court, true
end

local function resetCamera(court)
    log(">>> Resetting camera...")
    
    local inBounds = court:FindFirstChild("InBounds")
    if not inBounds then return end
    
    -- Find opposite service box
    local center = court:GetPivot().Position
    local myZ = hrp.Position.Z - center.Z
    
    local targetBox = nil
    for _, child in ipairs(inBounds:GetChildren()) do
        if string.match(child.Name, "Serve") and not string.match(child.Name, "Line") then
            local boxZ = child:GetPivot().Position.Z - center.Z
            if (myZ * boxZ) < 0 then
                targetBox = child
                break
            end
        end
    end
    
    if not targetBox then return end
    
    -- Calculate HORIZONTAL direction only
    local myPos = hrp.Position
    local boxPos = targetBox:GetPivot().Position
    local horizontal = Vector3.new(boxPos.X - myPos.X, 0, boxPos.Z - myPos.Z).Unit
    
    -- Position camera
    local camPos = myPos + (horizontal * -5) + Vector3.new(0, 2, 0)
    local lookPos = myPos + (horizontal * 10)
    
    camera.CFrame = CFrame.lookAt(camPos, lookPos)
    
    log("✓ Camera reset")
end

local function moveToMarker(config, court)
    local courtCenter = court:GetPivot().Position
    local targetWorldPos = Vector3.new(
        courtCenter.X + config.x,
        hrp.Position.Y,
        courtCenter.Z + config.z
    )
    
    createMarker(targetWorldPos)
    
    local myPos = hrp.Position
    local offsetX = targetWorldPos.X - myPos.X
    local offsetZ = targetWorldPos.Z - myPos.Z
    local distance2D = math.sqrt(offsetX*offsetX + offsetZ*offsetZ)
    
    local charRight = hrp.CFrame.RightVector
    local directionToTarget = (targetWorldPos - myPos).Unit
    local rightComponent = directionToTarget:Dot(charRight)
    
    local moveRight = rightComponent > 0
    local moveTime = distance2D / 16 + 0.1
    
    log(string.format(">>> Moving %s (%.1f studs)", moveRight and "RIGHT" or "LEFT", distance2D))
    
    if moveRight then
        VIM:SendKeyEvent(true, Enum.KeyCode.D, false, game)
    else
        VIM:SendKeyEvent(true, Enum.KeyCode.A, false, game)
    end
    
    task.wait(moveTime)
    
    VIM:SendKeyEvent(false, Enum.KeyCode.A, false, game)
    VIM:SendKeyEvent(false, Enum.KeyCode.D, false, game)
    
    log("✓ Movement complete")
end

local function aimCamera(config)
    log(string.format(">>> Aiming: Pitch %.2f°, Yaw %.2f°", config.pitch, config.yaw))
    
    -- Convert angles to radians
    local pitchRad = math.rad(config.pitch)
    local yawRad = math.rad(config.yaw)
    
    -- Calculate look vector from pitch and yaw
    local lookVec = Vector3.new(
        math.sin(yawRad) * math.cos(pitchRad),
        math.sin(pitchRad),
        -math.cos(yawRad) * math.cos(pitchRad)
    ).Unit
    
    -- Set camera
    local camPos = camera.CFrame.Position
    camera.CFrame = CFrame.lookAt(camPos, camPos + lookVec)
    
    log("✓ Camera aimed")
end

local function findBall()
    local holder = workspace:FindFirstChild("Holder")
    if not holder then return nil end
    local balls = holder:FindFirstChild("Balls")
    if not balls then return nil end
    
    for _, ball in ipairs(balls:GetChildren()) do
        if ball:IsA("BasePart") then
            local dist = (ball.Position - hrp.Position).Magnitude
            if dist < 20 then
                return ball
            end
        end
    end
    return nil
end

local function ballInHitbox(ball)
    if not ball or not ball.Parent then return false end
    
    local look = hrp.CFrame.LookVector
    local right = hrp.CFrame.RightVector
    local up = hrp.CFrame.UpVector
    
    local center = hrp.Position + (look * -0.2) + (right * -0.2) + (up * 3.8)
    local ballPos = ball.Position
    
    local dx = math.abs(ballPos.X - center.X)
    local dy = math.abs(ballPos.Y - center.Y)
    local dz = math.abs(ballPos.Z - center.Z)
    
    return dx < 2.0 and dy < 2.25 and dz < 2.35
end

-- Predict if ball will be in hitbox very soon (for early release)
local function ballNearHitbox(ball, velocity)
    if not ball or not ball.Parent then return false end
    
    local look = hrp.CFrame.LookVector
    local right = hrp.CFrame.RightVector
    local up = hrp.CFrame.UpVector
    
    local center = hrp.Position + (look * -0.2) + (right * -0.2) + (up * 3.8)
    
    -- Predict position 0.05 seconds ahead
    local gravity = Vector3.new(0, -workspace.Gravity, 0)
    local predictedPos = ball.Position + velocity * 0.05 + 0.5 * gravity * 0.05 * 0.05
    
    local dx = math.abs(predictedPos.X - center.X)
    local dy = math.abs(predictedPos.Y - center.Y)
    local dz = math.abs(predictedPos.Z - center.Z)
    
    return dx < 2.0 and dy < 2.25 and dz < 2.35
end

-- MAIN
task.spawn(function()
    log("=== STARTING ===")
    log("Press P to cleanup and stop")
    log("")
    
    -- Create angle display GUI
    createAngleDisplay()
    log("✓ Angle display created (top right)")
    
    -- Wait for team
    log("STEP 1: Waiting for team...")
    while not player.Team or player.Team.Name == "" and running do
        task.wait(0.5)
    end
    if not running then return end
    log("✓ Team: " .. player.Team.Name)
    
    -- Wait for cutscene
    log("STEP 2: Waiting 8 seconds...")
    local cutsceneStart = tick()
    while tick() - cutsceneStart < 8 and running do
        task.wait(0.5)
    end
    if not running then return end
    log("✓ Cutscene done")
    
    -- Monitor for teleport
    log("STEP 3: Monitoring for teleport...")
    local lastPosition = hrp.Position
    
    while running do
        task.wait(0.1)
        
        if not isServing then
            local currentPosition = hrp.Position
            local distMoved = (currentPosition - lastPosition).Magnitude
            
            if distMoved > 20 then
                log("✓✓✓ TELEPORT DETECTED ✓✓✓")
                
                -- Check if we're the server
                local config, court, isServer = findServeSpot()
                
                if not isServer then
                    log("Skipping - not serving")
                    lastPosition = hrp.Position
                    continue
                end
                
                isServing = true
                
                -- STEP 1: Reset camera
                task.wait(0.1)
                resetCamera(court)
                
                -- STEP 2: Move to marker
                task.wait(0.1)
                moveToMarker(config, court)
                
                -- STEP 3: Flick camera to angle
                task.wait(0.1)
                aimCamera(config)
                
                -- STEP 4: Wait for ball
                local ball = nil
                while not ball and running do
                    ball = findBall()
                    task.wait(0.1)
                end
                if not running then break end
                log("✓ Ball spawned")
                
                -- STEP 5: Hold spacebar & wait for hitbox
                log("✓ Holding spacebar")
                VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                
                -- STEP 6: Release INSTANTLY when ball in hitbox
                log("✓ Waiting for hitbox...")
                local lastBallPos = ball.Position
                local ballFalling = false
                
                while ball and ball.Parent and running do
                    task.wait(0.016)
                    
                    if ball and ball.Parent then
                        local currentBallPos = ball.Position
                        local vel = (currentBallPos - lastBallPos) / 0.016
                        lastBallPos = currentBallPos
                        
                        if vel.Y < -1 then
                            ballFalling = true
                        end
                        
                        if ballFalling then
                            local inNow = ballInHitbox(ball)
                            local inSoon = ballNearHitbox(ball, vel)
                            
                            if inNow or inSoon then
                                log("✓✓✓ RELEASE ✓✓✓")
                                VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                break
                            end
                        end
                    end
                end
                
                VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                
                if marker then
                    marker:Destroy()
                    marker = nil
                end
                
                if not running then break end
                
                log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                log("Serve complete")
                log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                task.wait(2)
                
                isServing = false
                lastPosition = hrp.Position
            else
                lastPosition = currentPosition
            end
        end
    end
end)

log("=== RUNNING ===")
