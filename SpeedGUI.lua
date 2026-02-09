-- Speed GUI Script for Roblox
-- Place this in StarterPlayer > StarterPlayerScripts or StarterGui

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Wait for character
repeat wait() until player.Character
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")

-- Default speeds
local normalSpeed = 15
local sprintSpeed = 23
local overrideSpeed = 15
local isSprinting = false
local isSpacebarHeld = false
local guiVisible = true
local allHidden = false

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 340)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0.7, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Speed Controller"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Minimize Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -70, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
minimizeButton.BorderSizePixel = 0
minimizeButton.Text = "_"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 18
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = mainFrame

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeButton

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- Current Speed Display
local speedDisplay = Instance.new("TextLabel")
speedDisplay.Name = "SpeedDisplay"
speedDisplay.Size = UDim2.new(0.9, 0, 0, 50)
speedDisplay.Position = UDim2.new(0.05, 0, 0, 50)
speedDisplay.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
speedDisplay.BorderSizePixel = 0
speedDisplay.Text = "Current: " .. normalSpeed
speedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDisplay.TextSize = 24
speedDisplay.Font = Enum.Font.GothamBold
speedDisplay.Parent = mainFrame

local displayCorner = Instance.new("UICorner")
displayCorner.CornerRadius = UDim.new(0, 8)
displayCorner.Parent = speedDisplay

-- Normal Speed Label
local normalLabel = Instance.new("TextLabel")
normalLabel.Name = "NormalLabel"
normalLabel.Size = UDim2.new(0.55, 0, 0, 25)
normalLabel.Position = UDim2.new(0.05, 0, 0, 115)
normalLabel.BackgroundTransparency = 1
normalLabel.Text = "Normal Speed:"
normalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
normalLabel.TextSize = 14
normalLabel.Font = Enum.Font.Gotham
normalLabel.TextXAlignment = Enum.TextXAlignment.Left
normalLabel.Parent = mainFrame

-- Normal Speed Input Box
local normalInput = Instance.new("TextBox")
normalInput.Name = "NormalInput"
normalInput.Size = UDim2.new(0.25, 0, 0, 25)
normalInput.Position = UDim2.new(0.65, 0, 0, 115)
normalInput.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
normalInput.BorderSizePixel = 0
normalInput.Text = string.format("%.1f", normalSpeed)
normalInput.TextColor3 = Color3.fromRGB(255, 255, 255)
normalInput.TextSize = 14
normalInput.Font = Enum.Font.Gotham
normalInput.TextXAlignment = Enum.TextXAlignment.Center
normalInput.ClearTextOnFocus = false
normalInput.Parent = mainFrame

local normalInputCorner = Instance.new("UICorner")
normalInputCorner.CornerRadius = UDim.new(0, 4)
normalInputCorner.Parent = normalInput

-- Normal Speed Slider
local normalSliderBg = Instance.new("Frame")
normalSliderBg.Name = "NormalSliderBg"
normalSliderBg.Size = UDim2.new(0.7, 0, 0, 6)
normalSliderBg.Position = UDim2.new(0.05, 0, 0, 145)
normalSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
normalSliderBg.BorderSizePixel = 0
normalSliderBg.Parent = mainFrame

local normalSliderBgCorner = Instance.new("UICorner")
normalSliderBgCorner.CornerRadius = UDim.new(0, 3)
normalSliderBgCorner.Parent = normalSliderBg

local normalSlider = Instance.new("TextButton")
normalSlider.Name = "NormalSlider"
normalSlider.Size = UDim2.new(0, 20, 0, 20)
normalSlider.Position = UDim2.new((normalSpeed - 1) / 49, -10, 0.5, -10)
normalSlider.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
normalSlider.BorderSizePixel = 0
normalSlider.Text = ""
normalSlider.Parent = normalSliderBg

local normalSliderCorner = Instance.new("UICorner")
normalSliderCorner.CornerRadius = UDim.new(1, 0)
normalSliderCorner.Parent = normalSlider

-- Sprint Speed Label
local sprintLabel = Instance.new("TextLabel")
sprintLabel.Name = "SprintLabel"
sprintLabel.Size = UDim2.new(0.55, 0, 0, 25)
sprintLabel.Position = UDim2.new(0.05, 0, 0, 175)
sprintLabel.BackgroundTransparency = 1
sprintLabel.Text = "Sprint Speed:"
sprintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sprintLabel.TextSize = 14
sprintLabel.Font = Enum.Font.Gotham
sprintLabel.TextXAlignment = Enum.TextXAlignment.Left
sprintLabel.Parent = mainFrame

-- Sprint Speed Input Box
local sprintInput = Instance.new("TextBox")
sprintInput.Name = "SprintInput"
sprintInput.Size = UDim2.new(0.25, 0, 0, 25)
sprintInput.Position = UDim2.new(0.65, 0, 0, 175)
sprintInput.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
sprintInput.BorderSizePixel = 0
sprintInput.Text = string.format("%.1f", sprintSpeed)
sprintInput.TextColor3 = Color3.fromRGB(255, 255, 255)
sprintInput.TextSize = 14
sprintInput.Font = Enum.Font.Gotham
sprintInput.TextXAlignment = Enum.TextXAlignment.Center
sprintInput.ClearTextOnFocus = false
sprintInput.Parent = mainFrame

local sprintInputCorner = Instance.new("UICorner")
sprintInputCorner.CornerRadius = UDim.new(0, 4)
sprintInputCorner.Parent = sprintInput

-- Sprint Speed Slider Background
local sprintSliderBg = Instance.new("Frame")
sprintSliderBg.Name = "SprintSliderBg"
sprintSliderBg.Size = UDim2.new(0.7, 0, 0, 6)
sprintSliderBg.Position = UDim2.new(0.05, 0, 0, 205)
sprintSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
sprintSliderBg.BorderSizePixel = 0
sprintSliderBg.Parent = mainFrame

local sprintSliderBgCorner = Instance.new("UICorner")
sprintSliderBgCorner.CornerRadius = UDim.new(0, 3)
sprintSliderBgCorner.Parent = sprintSliderBg

local sprintSlider = Instance.new("TextButton")
sprintSlider.Name = "SprintSlider"
sprintSlider.Size = UDim2.new(0, 20, 0, 20)
sprintSlider.Position = UDim2.new((sprintSpeed - 1) / 49, -10, 0.5, -10)
sprintSlider.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
sprintSlider.BorderSizePixel = 0
sprintSlider.Text = ""
sprintSlider.Parent = sprintSliderBg

local sprintSliderCorner = Instance.new("UICorner")
sprintSliderCorner.CornerRadius = UDim.new(1, 0)
sprintSliderCorner.Parent = sprintSlider

-- Override Speed Label
local overrideLabel = Instance.new("TextLabel")
overrideLabel.Name = "OverrideLabel"
overrideLabel.Size = UDim2.new(0.55, 0, 0, 25)
overrideLabel.Position = UDim2.new(0.05, 0, 0, 235)
overrideLabel.BackgroundTransparency = 1
overrideLabel.Text = "Override Speed:"
overrideLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
overrideLabel.TextSize = 14
overrideLabel.Font = Enum.Font.Gotham
overrideLabel.TextXAlignment = Enum.TextXAlignment.Left
overrideLabel.Parent = mainFrame

-- Override Speed Input Box
local overrideInput = Instance.new("TextBox")
overrideInput.Name = "OverrideInput"
overrideInput.Size = UDim2.new(0.25, 0, 0, 25)
overrideInput.Position = UDim2.new(0.65, 0, 0, 235)
overrideInput.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
overrideInput.BorderSizePixel = 0
overrideInput.Text = string.format("%.1f", overrideSpeed)
overrideInput.TextColor3 = Color3.fromRGB(255, 255, 255)
overrideInput.TextSize = 14
overrideInput.Font = Enum.Font.Gotham
overrideInput.TextXAlignment = Enum.TextXAlignment.Center
overrideInput.ClearTextOnFocus = false
overrideInput.Parent = mainFrame

local overrideInputCorner = Instance.new("UICorner")
overrideInputCorner.CornerRadius = UDim.new(0, 4)
overrideInputCorner.Parent = overrideInput

-- Override Speed Slider Background
local overrideSliderBg = Instance.new("Frame")
overrideSliderBg.Name = "OverrideSliderBg"
overrideSliderBg.Size = UDim2.new(0.7, 0, 0, 6)
overrideSliderBg.Position = UDim2.new(0.05, 0, 0, 265)
overrideSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
overrideSliderBg.BorderSizePixel = 0
overrideSliderBg.Parent = mainFrame

local overrideSliderBgCorner = Instance.new("UICorner")
overrideSliderBgCorner.CornerRadius = UDim.new(0, 3)
overrideSliderBgCorner.Parent = overrideSliderBg

local overrideSlider = Instance.new("TextButton")
overrideSlider.Name = "OverrideSlider"
overrideSlider.Size = UDim2.new(0, 20, 0, 20)
overrideSlider.Position = UDim2.new((overrideSpeed - 1) / 49, -10, 0.5, -10)
overrideSlider.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
overrideSlider.BorderSizePixel = 0
overrideSlider.Text = ""
overrideSlider.Parent = overrideSliderBg

local overrideSliderCorner = Instance.new("UICorner")
overrideSliderCorner.CornerRadius = UDim.new(1, 0)
overrideSliderCorner.Parent = overrideSlider

-- Info Label
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(0.9, 0, 0, 20)
infoLabel.Position = UDim2.new(0.05, 0, 1, -25)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Shift: Sprint | Space: Override | K: Hide All"
infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.Parent = mainFrame

-- Open Button (hidden by default)
local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Size = UDim2.new(0, 120, 0, 40)
openButton.Position = UDim2.new(0, 10, 1, -50)
openButton.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
openButton.BorderSizePixel = 0
openButton.Text = "Speed GUI"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 16
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.Active = true
openButton.Draggable = true
openButton.Parent = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openButton

-- Functions
local function updateSpeed()
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		local hum = char.Humanoid
		if isSpacebarHeld then
			hum.WalkSpeed = overrideSpeed
			speedDisplay.Text = string.format("Current: %.1f (Override)", overrideSpeed)
			speedDisplay.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		elseif isSprinting then
			hum.WalkSpeed = sprintSpeed
			speedDisplay.Text = string.format("Current: %.1f (Sprinting)", sprintSpeed)
			speedDisplay.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
		else
			hum.WalkSpeed = normalSpeed
			speedDisplay.Text = string.format("Current: %.1f", normalSpeed)
			speedDisplay.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
		end
	end
end

-- Continuously enforce speed every frame (prevents anti-cheat or other scripts from changing it)
game:GetService("RunService").RenderStepped:Connect(function()
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		local hum = char.Humanoid
		local targetSpeed
		if isSpacebarHeld then
			targetSpeed = overrideSpeed
		elseif isSprinting then
			targetSpeed = sprintSpeed
		else
			targetSpeed = normalSpeed
		end
		hum.WalkSpeed = targetSpeed
	end
end)

-- Also hook into property changes to override immediately
player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		local targetSpeed
		if isSpacebarHeld then
			targetSpeed = overrideSpeed
		elseif isSprinting then
			targetSpeed = sprintSpeed
		else
			targetSpeed = normalSpeed
		end
		if hum.WalkSpeed ~= targetSpeed then
			hum.WalkSpeed = targetSpeed
		end
	end)
end)

-- Set initial property change listener for current character
if player.Character and player.Character:FindFirstChild("Humanoid") then
	local hum = player.Character.Humanoid
	hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		local targetSpeed
		if isSpacebarHeld then
			targetSpeed = overrideSpeed
		elseif isSprinting then
			targetSpeed = sprintSpeed
		else
			targetSpeed = normalSpeed
		end
		if hum.WalkSpeed ~= targetSpeed then
			hum.WalkSpeed = targetSpeed
		end
	end)
end

-- Minimize button functionality
minimizeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	openButton.Visible = true
	guiVisible = false
end)

-- Close button functionality (completely closes the GUI)
closeButton.MouseButton1Click:Connect(function()
	-- Reset speeds to default before closing
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		char.Humanoid.WalkSpeed = 16 -- Roblox default speed
	end
	normalSpeed = 15
	sprintSpeed = 23
	overrideSpeed = 15
	isSprinting = false
	isSpacebarHeld = false
	screenGui:Destroy()
end)

-- Open button functionality
openButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	openButton.Visible = false
	guiVisible = true
end)

-- Normal speed input box functionality
normalInput.FocusLost:Connect(function(enterPressed)
	local value = tonumber(normalInput.Text)
	if value and value >= 1 and value <= 50 then
		normalSpeed = value
		normalInput.Text = string.format("%.1f", normalSpeed)
		-- Update slider position
		local relativePos = (normalSpeed - 1) / 49
		normalSlider.Position = UDim2.new(relativePos, -10, 0.5, -10)
		updateSpeed()
	else
		normalInput.Text = string.format("%.1f", normalSpeed)
	end
end)

-- Sprint speed input box functionality
sprintInput.FocusLost:Connect(function(enterPressed)
	local value = tonumber(sprintInput.Text)
	if value and value >= 1 and value <= 50 then
		sprintSpeed = value
		sprintInput.Text = string.format("%.1f", sprintSpeed)
		-- Update slider position
		local relativePos = (sprintSpeed - 1) / 49
		sprintSlider.Position = UDim2.new(relativePos, -10, 0.5, -10)
		updateSpeed()
	else
		sprintInput.Text = string.format("%.1f", sprintSpeed)
	end
end)

-- Override speed input box functionality
overrideInput.FocusLost:Connect(function(enterPressed)
	local value = tonumber(overrideInput.Text)
	if value and value >= 1 and value <= 50 then
		overrideSpeed = value
		overrideInput.Text = string.format("%.1f", overrideSpeed)
		-- Update slider position
		local relativePos = (overrideSpeed - 1) / 49
		overrideSlider.Position = UDim2.new(relativePos, -10, 0.5, -10)
		updateSpeed()
	else
		overrideInput.Text = string.format("%.1f", overrideSpeed)
	end
end)

-- Slider dragging
local draggingNormal = false
local draggingSprint = false
local draggingOverride = false

normalSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingNormal = true
	end
end)

normalSlider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingNormal = false
	end
end)

sprintSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSprint = true
	end
end)

sprintSlider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSprint = false
	end
end)

overrideSlider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingOverride = true
	end
end)

overrideSlider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingOverride = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if draggingNormal then
			local mousePos = UserInputService:GetMouseLocation()
			local sliderPos = normalSliderBg.AbsolutePosition
			local sliderSize = normalSliderBg.AbsoluteSize
			local relativePos = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
			-- Range from 1 to 50 with 0.1 increments
			normalSpeed = math.floor((relativePos * 490 + 10)) / 10
			normalSlider.Position = UDim2.new(relativePos, -10, 0.5, -10)
			normalInput.Text = string.format("%.1f", normalSpeed)
			updateSpeed()
		elseif draggingSprint then
			local mousePos = UserInputService:GetMouseLocation()
			local sliderPos = sprintSliderBg.AbsolutePosition
			local sliderSize = sprintSliderBg.AbsoluteSize
			local relativePos = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
			-- Range from 1 to 50 with 0.1 increments
			sprintSpeed = math.floor((relativePos * 490 + 10)) / 10
			sprintSlider.Position = UDim2.new(relativePos, -10, 0.5, -10)
			sprintInput.Text = string.format("%.1f", sprintSpeed)
			updateSpeed()
		elseif draggingOverride then
			local mousePos = UserInputService:GetMouseLocation()
			local sliderPos = overrideSliderBg.AbsolutePosition
			local sliderSize = overrideSliderBg.AbsoluteSize
			local relativePos = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
			-- Range from 1 to 50 with 0.1 increments
			overrideSpeed = math.floor((relativePos * 490 + 10)) / 10
			overrideSlider.Position = UDim2.new(relativePos, -10, 0.5, -10)
			overrideInput.Text = string.format("%.1f", overrideSpeed)
			updateSpeed()
		end
	end
end)

-- Sprint toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		updateSpeed()
	elseif not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
		isSpacebarHeld = true
		updateSpeed()
	elseif not gameProcessed and input.KeyCode == Enum.KeyCode.K then
		allHidden = not allHidden
		mainFrame.Visible = not allHidden
		openButton.Visible = false
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		updateSpeed()
	elseif input.KeyCode == Enum.KeyCode.Space then
		isSpacebarHeld = false
		updateSpeed()
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	wait(0.1)
	updateSpeed()
end)

-- Initial speed set
wait(0.1)
updateSpeed()
