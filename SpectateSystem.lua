-- SpectateSystem.client.lua (ADVANCED)
-- Camera overlay with zoom, stance detection, and crosshair

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Config
local EXIT_KEY = Enum.KeyCode.X
local MIN_ZOOM = 0.5  -- Very close
local MAX_ZOOM = 50   -- Very far
local ZOOM_SPEED = 1

-- State
local isSpectating = false
local spectatingPlayer = nil
local cameraConnection = nil
local originalCameraSubject = nil
local originalCameraType = nil
local currentZoom = 10
local manualPitch = 0  -- Player controls this with mouse

-- Camera offsets based on stance
local OFFSETS = {
	Default = Vector3.new(1.5, 1, 0),      -- Right side, lower height
	Backhand = Vector3.new(-1.5, 1, 0),    -- Left side, lower height
	Overhead = Vector3.new(-1, 1.5, 0),    -- Left and slightly up
}

-- ===== DETECT STANCE =====
local function detectStance(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then
		return "Default"
	end
	
	local char = targetPlayer.Character
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	
	if not humanoid then
		return "Default"
	end
	
	-- Check animator for animation tracks
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local tracks = animator:GetPlayingAnimationTracks()
		
		for _, track in ipairs(tracks) do
			local animName = track.Animation.AnimationId
			
			-- Check for backhand animation (you'll need to verify these names/IDs)
			if animName:lower():find("backhand") or track.Name:lower():find("backhand") then
				return "Backhand"
			end
			
			-- Check for overhead animation
			if animName:lower():find("overhead") or track.Name:lower():find("overhead") then
				return "Overhead"
			end
		end
	end
	
	-- Default to ctrl stance (right side)
	return "Default"
end

-- ===== CAMERA FUNCTIONS =====
local function startSpectating(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then
		warn("[Spectate] Target player has no character")
		return
	end
	
	originalCameraSubject = camera.CameraSubject
	originalCameraType = camera.CameraType
	
	isSpectating = true
	spectatingPlayer = targetPlayer
	currentZoom = 10
	manualPitch = 0
	
	camera.CameraType = Enum.CameraType.Scriptable
	
	-- Update camera every frame
	cameraConnection = RunService.RenderStepped:Connect(function()
		if not spectatingPlayer or not spectatingPlayer.Character then
			stopSpectating()
			return
		end
		
		local targetChar = spectatingPlayer.Character
		local humanoidRootPart = targetChar:FindFirstChild("HumanoidRootPart")
		
		if humanoidRootPart then
			-- Use HumanoidRootPart for horizontal rotation (follows their left/right looking)
			local rootCFrame = humanoidRootPart.CFrame
			
			-- Detect stance
			local stance = detectStance(spectatingPlayer)
			local stanceOffset = OFFSETS[stance] or OFFSETS.Default
			
			-- Player position
			local playerPosition = humanoidRootPart.Position + Vector3.new(0, 1.5, 0)
			
			-- Horizontal direction from their character rotation
			local horizontalForward = rootCFrame.LookVector
			local rightDirection = rootCFrame.RightVector
			
			-- Combine horizontal (from player) + vertical (from YOUR mouse)
			local horizontalAngle = math.atan2(horizontalForward.X, horizontalForward.Z)
			local lookDirection = Vector3.new(
				math.sin(horizontalAngle) * math.cos(manualPitch),
				math.sin(manualPitch),
				math.cos(horizontalAngle) * math.cos(manualPitch)
			)
			
			-- Apply stance offset
			local cameraFocus = playerPosition + (rightDirection * stanceOffset.X)
			
			-- Put camera behind at zoom distance
			local cameraPosition = cameraFocus - (lookDirection * currentZoom) + Vector3.new(0, stanceOffset.Y, 0)
			
			-- Look where we're aiming
			camera.CFrame = CFrame.new(cameraPosition, cameraFocus + (lookDirection * 100))
			camera.FieldOfView = 70
		end
	end)
	
	exitHint.Visible = true
	crosshair.Visible = true
	
	print("[Spectate] Now spectating:", spectatingPlayer.Name)
end

local function stopSpectating()
	if not isSpectating then return end
	
	isSpectating = false
	spectatingPlayer = nil
	
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	
	camera.CameraType = originalCameraType or Enum.CameraType.Custom
	camera.CameraSubject = originalCameraSubject or player.Character:FindFirstChildOfClass("Humanoid")
	
	exitHint.Visible = false
	crosshair.Visible = false
	
	print("[Spectate] Stopped spectating")
end

-- ===== GUI =====
-- MODERN COLOR SCHEME
local COLORS = {
	BG = Color3.fromRGB(20, 22, 26),
	BG2 = Color3.fromRGB(28, 31, 37),
	BG3 = Color3.fromRGB(35, 38, 45),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(150, 155, 165),
	Primary = Color3.fromRGB(88, 101, 242),
	PrimaryHover = Color3.fromRGB(108, 121, 255),
	Success = Color3.fromRGB(67, 181, 129),
	SuccessHover = Color3.fromRGB(87, 201, 149),
	Danger = Color3.fromRGB(240, 71, 71),
	DangerHover = Color3.fromRGB(255, 91, 91),
}

local function tween(obj, ti, props)
	TweenService:Create(obj, ti, props):Play()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SpectateGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Crosshair (center of screen)
local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.fromOffset(20, 20)
crosshair.Position = UDim2.new(0.5, -10, 0.5, -10)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.Parent = gui

-- Vertical line
local vLine = Instance.new("Frame")
vLine.Size = UDim2.fromOffset(2, 20)
vLine.Position = UDim2.new(0.5, -1, 0, 0)
vLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
vLine.BorderSizePixel = 0
vLine.Parent = crosshair

-- Horizontal line
local hLine = Instance.new("Frame")
hLine.Size = UDim2.fromOffset(20, 2)
hLine.Position = UDim2.new(0, 0, 0.5, -1)
hLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
hLine.BorderSizePixel = 0
hLine.Parent = crosshair

-- Center dot
local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(4, 4)
dot.Position = UDim2.new(0.5, -2, 0.5, -2)
dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dot.BorderSizePixel = 0
dot.Parent = crosshair

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

-- Main frame
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(340, 450)
main.Position = UDim2.new(1, -360, 0.5, -225)
main.BackgroundColor3 = COLORS.BG
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Primary
mainStroke.Transparency = 0.7
mainStroke.Thickness = 2
mainStroke.Parent = main

-- Subtle gradient
local mainGradient = Instance.new("UIGradient")
mainGradient.Rotation = 90
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLORS.BG2),
	ColorSequenceKeypoint.new(1, COLORS.BG),
})
mainGradient.Parent = main

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = COLORS.BG2
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 14)
headerCover.Position = UDim2.new(0, 0, 1, -14)
headerCover.BackgroundColor3 = COLORS.BG2
headerCover.BorderSizePixel = 0
headerCover.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 0, 30)
title.Position = UDim2.new(0, 20, 0, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = COLORS.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "👁️ Spectate Mode"
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -120, 0, 16)
subtitle.Position = UDim2.new(0, 20, 0, 38)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextColor3 = COLORS.TextDim
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "↑↓ arrows = Look • Scroll = Zoom • K = Minimize"
subtitle.Parent = header

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.fromOffset(40, 40)
minimizeBtn.Position = UDim2.new(1, -92, 0, 10)
minimizeBtn.BackgroundColor3 = COLORS.BG3
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "—"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.TextColor3 = COLORS.Text
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = header

local minimizeBtnCorner = Instance.new("UICorner")
minimizeBtnCorner.CornerRadius = UDim.new(0, 10)
minimizeBtnCorner.Parent = minimizeBtn

minimizeBtn.MouseEnter:Connect(function()
	tween(minimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Primary})
end)
minimizeBtn.MouseLeave:Connect(function()
	tween(minimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BG3})
end)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.Position = UDim2.new(1, -46, 0, 10)
closeBtn.BackgroundColor3 = COLORS.Danger
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 10)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.DangerHover})
end)
closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Danger})
end)

closeBtn.MouseButton1Click:Connect(function()
	stopSpectating()
	gui:Destroy()
end)

-- Player list container
local listContainer = Instance.new("ScrollingFrame")
listContainer.Size = UDim2.new(1, -24, 1, -84)
listContainer.Position = UDim2.new(0, 12, 0, 72)
listContainer.BackgroundTransparency = 1
listContainer.BorderSizePixel = 0
listContainer.ScrollBarThickness = 6
listContainer.ScrollBarImageColor3 = COLORS.Primary
listContainer.Parent = main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent = listContainer

-- Minimize functionality (defined early so it can be used in keybinds)
local minimized = false
local fullSize = main.Size

function toggleMinimize()
	minimized = not minimized
	if minimized then
		main.Visible = false
	else
		main.Visible = true
	end
end

minimizeBtn.MouseButton1Click:Connect(function()
	-- Button click just collapses
	if listContainer.Visible then
		listContainer.Visible = false
		tween(main, TweenInfo.new(0.2), {Size = UDim2.fromOffset(340, 60)})
		minimizeBtn.Text = "+"
	else
		listContainer.Visible = true
		tween(main, TweenInfo.new(0.2), {Size = fullSize})
		minimizeBtn.Text = "—"
	end
end)

-- Exit hint
local exitHint = Instance.new("Frame")
exitHint.Size = UDim2.fromOffset(400, 56)
exitHint.Position = UDim2.new(0.5, -200, 0, 24)
exitHint.BackgroundColor3 = COLORS.BG
exitHint.BorderSizePixel = 0
exitHint.Visible = false
exitHint.Parent = gui

local exitHintCorner = Instance.new("UICorner")
exitHintCorner.CornerRadius = UDim.new(0, 12)
exitHintCorner.Parent = exitHint

local exitHintStroke = Instance.new("UIStroke")
exitHintStroke.Color = COLORS.Primary
exitHintStroke.Transparency = 0.5
exitHintStroke.Thickness = 2
exitHintStroke.Parent = exitHint

local exitHintText = Instance.new("TextLabel")
exitHintText.Size = UDim2.new(1, -24, 1, 0)
exitHintText.Position = UDim2.new(0, 12, 0, 0)
exitHintText.BackgroundTransparency = 1
exitHintText.Font = Enum.Font.GothamBold
exitHintText.TextSize = 13
exitHintText.TextColor3 = COLORS.Text
exitHintText.Text = ('Press "%s" to exit • Arrow keys ↑↓ to look • Scroll to zoom • "K" to minimize'):format(EXIT_KEY.Name)
exitHintText.TextWrapped = true
exitHintText.Parent = exitHint

-- Create player entry
local function createPlayerEntry(targetPlayer)
	if targetPlayer == player then return end
	
	local entry = Instance.new("Frame")
	entry.Size = UDim2.new(1, -12, 0, 50)
	entry.BackgroundColor3 = COLORS.BG3
	entry.BorderSizePixel = 0
	entry.Parent = listContainer
	
	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 10)
	entryCorner.Parent = entry
	
	local entryStroke = Instance.new("UIStroke")
	entryStroke.Color = Color3.fromRGB(255, 255, 255)
	entryStroke.Transparency = 0.95
	entryStroke.Thickness = 1
	entryStroke.Parent = entry
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -110, 1, 0)
	nameLabel.Position = UDim2.new(0, 16, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamSemibold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = COLORS.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = targetPlayer.Name
	nameLabel.Parent = entry
	
	local spectateBtn = Instance.new("TextButton")
	spectateBtn.Size = UDim2.fromOffset(88, 36)
	spectateBtn.Position = UDim2.new(1, -96, 0.5, -18)
	spectateBtn.BackgroundColor3 = COLORS.Primary
	spectateBtn.BorderSizePixel = 0
	spectateBtn.Text = "Spectate"
	spectateBtn.Font = Enum.Font.GothamBold
	spectateBtn.TextSize = 12
	spectateBtn.TextColor3 = COLORS.Text
	spectateBtn.AutoButtonColor = false
	spectateBtn.Parent = entry
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = spectateBtn
	
	spectateBtn.MouseEnter:Connect(function()
		tween(spectateBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.PrimaryHover})
	end)
	
	spectateBtn.MouseLeave:Connect(function()
		tween(spectateBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.Primary})
	end)
	
	spectateBtn.MouseButton1Click:Connect(function()
		if isSpectating and spectatingPlayer == targetPlayer then
			stopSpectating()
		else
			if isSpectating then
				stopSpectating()
			end
			startSpectating(targetPlayer)
		end
	end)
	
	local function updateButton()
		if isSpectating and spectatingPlayer == targetPlayer then
			spectateBtn.Text = "Stop"
			tween(spectateBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Success})
		else
			spectateBtn.Text = "Spectate"
			tween(spectateBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.Primary})
		end
	end
	
	RunService.RenderStepped:Connect(updateButton)
	
	return entry
end

-- Populate player list
local function refreshPlayerList()
	for _, child in ipairs(listContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		createPlayerEntry(otherPlayer)
	end
	
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listContainer.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	listContainer.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 10)
end

-- Handle player changes
Players.PlayerAdded:Connect(function()
	task.wait(0.1)
	refreshPlayerList()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	if spectatingPlayer == leavingPlayer then
		stopSpectating()
	end
	refreshPlayerList()
end)

-- Zoom and camera control
local upArrowDown = false
local downArrowDown = false

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	
	if input.KeyCode == EXIT_KEY and isSpectating then
		stopSpectating()
	elseif input.KeyCode == Enum.KeyCode.Up then
		upArrowDown = true
	elseif input.KeyCode == Enum.KeyCode.Down then
		downArrowDown = true
	elseif input.KeyCode == Enum.KeyCode.K and gui.Parent then
		toggleMinimize()
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.Up then
		upArrowDown = false
	elseif input.KeyCode == Enum.KeyCode.Down then
		downArrowDown = false
	end
end)

-- Update pitch continuously while arrows are held
RunService.RenderStepped:Connect(function(dt)
	if not isSpectating then return end
	
	if upArrowDown then
		manualPitch = math.clamp(manualPitch + (dt * 1.5), -1.4, 1.4)
	end
	if downArrowDown then
		manualPitch = math.clamp(manualPitch - (dt * 1.5), -1.4, 1.4)
	end
end)

UserInputService.InputChanged:Connect(function(input, gp)
	if gp then return end
	
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		-- Zoom in/out
		if isSpectating then
			currentZoom = math.clamp(currentZoom - (input.Position.Z * ZOOM_SPEED), MIN_ZOOM, MAX_ZOOM)
		end
	end
end)

-- Initial load
refreshPlayerList()

main.BackgroundTransparency = 1
tween(main, TweenInfo.new(0.3), {BackgroundTransparency = 0})

print("[Spectate] GUI loaded! Scroll to zoom, Press X to exit.")
