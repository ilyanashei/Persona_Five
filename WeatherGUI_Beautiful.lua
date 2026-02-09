-- WeatherGUI.client.lua (BEAUTIFUL REDESIGN)
-- Modern, clean UI with smooth animations

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- === CONFIG ===
local MINIMIZE_KEY = Enum.KeyCode.Insert

-- Path to weather system
local playerScripts = player:WaitForChild("PlayerScripts")
local weatherSystem = playerScripts:WaitForChild("WeatherSystem")
local weatherModulesFolder = weatherSystem:WaitForChild("WeatherModules")

local function getEffectsFolder()
	local holder = workspace:FindFirstChild("Holder")
	if holder and holder:FindFirstChild("Effects") then
		return holder.Effects
	end
	return workspace
end

local function getAtmosphere()
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then
		atm = Instance.new("Atmosphere")
		atm.Parent = Lighting
	end
	return atm
end

-- === LOAD WEATHER MODULES ===
local Modules = {}
for _, m in ipairs(weatherModulesFolder:GetChildren()) do
	if m:IsA("ModuleScript") then
		local ok, mod = pcall(require, m)
		if ok and type(mod) == "table" then
			Modules[string.lower(m.Name)] = mod
		end
	end
end

local ALIASES = {
	clear = "clear",
	rain = "raining",
	raining = "raining",
	snow = "snowing",
	snowing = "snowing",
}

-- === BASELINE ===
local baselineCaptured = false
local baseline = {
	weatherKey = nil,
	lighting = {},
	atmosphere = {},
}

local function snapshotLighting()
	return {
		Ambient = Lighting.Ambient,
		Brightness = Lighting.Brightness,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		FogColor = Lighting.FogColor,
		ExposureCompensation = Lighting.ExposureCompensation,
	}
end

local function snapshotAtmosphere()
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then return nil end
	return {
		Density = atm.Density,
		Offset = atm.Offset,
		Color = atm.Color,
		Decay = atm.Decay,
		Glare = atm.Glare,
		Haze = atm.Haze,
	}
end

local function restoreLighting(snap)
	for prop, val in pairs(snap) do
		pcall(function() Lighting[prop] = val end)
	end
end

local function restoreAtmosphere(snap)
	if not snap then return end
	local atm = getAtmosphere()
	for prop, val in pairs(snap) do
		pcall(function() atm[prop] = val end)
	end
end

local function detectCurrentWeatherKeyBestEffort()
	local pg = player:FindFirstChild("PlayerGui")
	if pg and pg:FindFirstChild("RainingSounds") then
		return "raining"
	end
	return "clear"
end

local function captureBaselineOnce()
	if baselineCaptured then return end
	baselineCaptured = true
	baseline.weatherKey = detectCurrentWeatherKeyBestEffort()
	baseline.lighting = snapshotLighting()
	baseline.atmosphere = snapshotAtmosphere()
end

-- === WEATHER CORE ===
local currentWeatherKey: string? = nil
local currentPhase: "Day" | "Night" = "Day"

local function applyLightingFromModule(mod, phase)
	if type(mod.GetLightingSettings) ~= "function" then return end
	local preset = mod:GetLightingSettings(phase)
	if type(preset) ~= "table" then return end

	local lp = preset.LightingProperties
	if type(lp) == "table" then
		for prop, val in pairs(lp) do
			pcall(function() Lighting[prop] = val end)
		end
	end

	local ap = preset.AtmosphereProperties
	if type(ap) == "table" then
		local atm = getAtmosphere()
		for prop, val in pairs(ap) do
			pcall(function() atm[prop] = val end)
		end
	end
end

local function stopCurrentWeather()
	if currentWeatherKey then
		local mod = Modules[currentWeatherKey]
		if mod and type(mod.Stop) == "function" then
			pcall(mod.Stop, mod)
		end
		setSoundsEnabled(false, nil)
		setParticlesEnabled(false, nil)
		currentWeatherKey = nil
		task.wait(0.1)
	end
end

function setSoundsEnabled(enabled: boolean, hint: string?)
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return end
	local h = hint and string.lower(hint) or ""

	for _, folder in ipairs(pg:GetChildren()) do
		local nameLower = string.lower(folder.Name)
		local relevant =
			nameLower:find("rainingsounds", 1, true) ~= nil or
			nameLower:find("snowingsounds", 1, true) ~= nil or
			(h ~= "" and nameLower:find(h, 1, true) ~= nil and nameLower:find("sound", 1, true) ~= nil)

		if relevant then
			for _, s in ipairs(folder:GetDescendants()) do
				if s:IsA("Sound") then
					if enabled then
						s.Volume = 1
						if not s.IsPlaying then pcall(function() s:Play() end) end
					else
						pcall(function() s:Stop() end)
						s.Volume = 0
					end
				end
			end
		end
	end
end

function setParticlesEnabled(enabled: boolean, hint: string?)
	local effects = getEffectsFolder()
	local h = hint and string.lower(hint) or ""

	for _, inst in ipairs(effects:GetDescendants()) do
		local n = string.lower(inst.Name)
		local weatherish =
			(h ~= "" and n:find(h, 1, true) ~= nil) or
			n:find("weather", 1, true) ~= nil or
			n:find("rain", 1, true) ~= nil or
			n:find("snow", 1, true) ~= nil

		if weatherish then
			if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
				inst.Enabled = enabled
			end
		end
	end
end

local function setWeatherFXEnabled(enabled: boolean)
	if currentWeatherKey == "raining" then
		setSoundsEnabled(enabled, "rain")
		setParticlesEnabled(enabled, "rain")
	elseif currentWeatherKey == "snowing" then
		setSoundsEnabled(enabled, "snow")
		setParticlesEnabled(enabled, "snow")
	end
end

local function setWeather(weatherName: string, phase: ("Day" | "Night")?, fxEnabled: boolean?)
	captureBaselineOnce()

	local key = ALIASES[string.lower(weatherName)] or string.lower(weatherName)
	local mod = Modules[key]
	if not mod then return end

	phase = phase or currentPhase
	currentPhase = phase

	stopCurrentWeather()
	applyLightingFromModule(mod, phase)

	if type(mod.Start) == "function" then
		pcall(mod.Start, mod)
	end

	currentWeatherKey = key

	if fxEnabled ~= nil then
		task.defer(function()
			task.wait(0.15)
			setWeatherFXEnabled(fxEnabled)
		end)
	end
end

local function setPhase(phase: "Day" | "Night")
	captureBaselineOnce()
	currentPhase = phase
	if currentWeatherKey then
		local mod = Modules[currentWeatherKey]
		if mod then
			applyLightingFromModule(mod, phase)
		end
	end
end

local function resetToBaseline()
	stopCurrentWeather()
	if baseline.lighting then restoreLighting(baseline.lighting) end
	if baseline.atmosphere then restoreAtmosphere(baseline.atmosphere) end

	if baseline.weatherKey and baseline.weatherKey ~= "clear" and Modules[baseline.weatherKey] then
		local mod = Modules[baseline.weatherKey]
		local phase = (Lighting.ClockTime >= 18 or Lighting.ClockTime < 6) and "Night" or "Day"
		applyLightingFromModule(mod, phase)
		pcall(mod.Start, mod)
		currentWeatherKey = baseline.weatherKey
		currentPhase = phase
	else
		currentWeatherKey = nil
	end
end

-- =========================================================
-- =================== BEAUTIFUL GUI =======================
-- =========================================================

local function tween(obj, ti, props)
	TweenService:Create(obj, ti, props):Play()
end

-- MODERN COLOR SCHEME
local C = {
	-- Main colors
	BG = Color3.fromRGB(25, 27, 32),
	BG2 = Color3.fromRGB(30, 33, 39),
	
	-- Text
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(160, 165, 175),
	
	-- Accents
	Primary = Color3.fromRGB(88, 101, 242),
	PrimaryHover = Color3.fromRGB(108, 121, 255),
	
	-- Weather colors
	Clear = Color3.fromRGB(135, 206, 250),
	Rain = Color3.fromRGB(100, 120, 150),
	Snow = Color3.fromRGB(200, 220, 255),
	
	-- Utility
	Success = Color3.fromRGB(67, 181, 129),
	Danger = Color3.fromRGB(240, 71, 71),
}

local gui = Instance.new("ScreenGui")
gui.Name = "WeatherGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main container
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(420, 380)
main.Position = UDim2.new(0.5, -210, 0.5, -190)
main.BackgroundColor3 = C.BG
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Transparency = 0.9
mainStroke.Thickness = 1
mainStroke.Parent = main

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = C.BG2
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

-- Cover bottom corners of header
local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 14)
headerCover.Position = UDim2.new(0, 0, 1, -14)
headerCover.BackgroundColor3 = C.BG2
headerCover.BorderSizePixel = 0
headerCover.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 30)
title.Position = UDim2.new(0, 20, 0, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = C.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "⛅ Weather Control"
title.Parent = header

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -100, 0, 16)
subtitle.Position = UDim2.new(0, 20, 0, 38)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextColor3 = C.TextDim
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Text = "Press INSERT to minimize"
subtitle.Parent = header

-- Status indicators
local statusContainer = Instance.new("Frame")
statusContainer.Size = UDim2.new(1, -40, 0, 24)
statusContainer.Position = UDim2.new(0, 20, 0, 62)
statusContainer.BackgroundTransparency = 1
statusContainer.Parent = main

local statusLayout = Instance.new("UIListLayout")
statusLayout.FillDirection = Enum.FillDirection.Horizontal
statusLayout.Padding = UDim.new(0, 8)
statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
statusLayout.Parent = statusContainer

local function makeStatusBadge(text, color)
	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromOffset(0, 24)
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.BackgroundColor3 = color
	badge.BackgroundTransparency = 0.85
	badge.BorderSizePixel = 0
	badge.Parent = statusContainer
	
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 6)
	badgeCorner.Parent = badge
	
	local badgePadding = Instance.new("UIPadding")
	badgePadding.PaddingLeft = UDim.new(0, 10)
	badgePadding.PaddingRight = UDim.new(0, 10)
	badgePadding.Parent = badge
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.TextColor3 = color
	label.Text = text
	label.Parent = badge
	
	local function update(newText, newColor)
		label.Text = newText
		label.TextColor3 = newColor
		badge.BackgroundColor3 = newColor
	end
	
	return update
end

local updateWeatherStatus = makeStatusBadge("Clear", C.Clear)
local updateTimeStatus = makeStatusBadge("Day", C.Clear)
local updateFXStatus = makeStatusBadge("FX On", C.Success)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundColor3 = C.Danger
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 24
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.AutoButtonColor = false
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 10)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	tween(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 90, 90)})
end)
closeBtn.MouseLeave:Connect(function()
	tween(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.Danger})
end)

-- Body
local body = Instance.new("Frame")
body.Size = UDim2.new(1, -40, 1, -110)
body.Position = UDim2.new(0, 20, 0, 96)
body.BackgroundTransparency = 1
body.Parent = main

local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 16)
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Parent = body

-- Section maker
local function makeSection(titleText)
	local section = Instance.new("Frame")
	section.Size = UDim2.new(1, 0, 0, 70)
	section.BackgroundTransparency = 1
	section.Parent = body
	
	local sectionTitle = Instance.new("TextLabel")
	sectionTitle.Size = UDim2.new(1, 0, 0, 20)
	sectionTitle.BackgroundTransparency = 1
	sectionTitle.Font = Enum.Font.GothamBold
	sectionTitle.TextSize = 12
	sectionTitle.TextColor3 = C.TextDim
	sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	sectionTitle.Text = titleText:upper()
	sectionTitle.Parent = section
	
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 44)
	container.Position = UDim2.new(0, 0, 0, 26)
	container.BackgroundTransparency = 1
	container.Parent = section
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container
	
	return container
end

-- Button maker
local function makeButton(parent, text, color, wide)
	local btn = Instance.new("TextButton")
	btn.Size = wide and UDim2.new(0.32, -7, 1, 0) or UDim2.fromOffset(100, 44)
	btn.BackgroundColor3 = C.BG2
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = parent
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = btn
	
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = color or C.Primary
	btnStroke.Transparency = 0.7
	btnStroke.Thickness = 2
	btnStroke.Parent = btn
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = C.Text
	label.Text = text
	label.Parent = btn
	
	-- Active indicator (glow effect)
	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(1, 0, 1, 0)
	glow.BackgroundColor3 = color or C.Primary
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.ZIndex = 0
	glow.Parent = btn
	
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 10)
	glowCorner.Parent = glow
	
	-- Animations
	local function setActive(active)
		tween(glow, TweenInfo.new(0.2), {
			BackgroundTransparency = active and 0.85 or 1
		})
		tween(btnStroke, TweenInfo.new(0.2), {
			Transparency = active and 0 or 0.7,
			Thickness = active and 2.5 or 2
		})
	end
	
	btn.MouseEnter:Connect(function()
		tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BG})
	end)
	
	btn.MouseLeave:Connect(function()
		tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BG2})
	end)
	
	return btn, setActive
end

-- Create sections
local weatherSection = makeSection("Weather Type")
local timeSection = makeSection("Time of Day")
local controlSection = makeSection("Effects Control")

-- Weather buttons
local btnClear, setClearActive = makeButton(weatherSection, "☀️ Clear", C.Clear, true)
local btnRain, setRainActive = makeButton(weatherSection, "🌧️ Rain", C.Rain, true)
local btnSnow, setSnowActive = makeButton(weatherSection, "❄️ Snow", C.Snow, true)

-- Time buttons
local btnDay, setDayActive = makeButton(timeSection, "🌞 Day", C.Clear, false)
local btnNight, setNightActive = makeButton(timeSection, "🌙 Night", Color3.fromRGB(100, 100, 180), false)

-- Control buttons
local btnFXOn, setFXOnActive = makeButton(controlSection, "✓ FX On", C.Success, false)
local btnFXOff, setFXOffActive = makeButton(controlSection, "✗ FX Off", C.TextDim, false)
local btnReset, setResetActive = makeButton(controlSection, "↺ Reset", C.Primary, false)

-- State
local activeWeather = "clear"
local fxState = true

local function refreshUI()
	setClearActive(activeWeather == "clear")
	setRainActive(activeWeather == "raining")
	setSnowActive(activeWeather == "snowing")
	
	setDayActive(currentPhase == "Day")
	setNightActive(currentPhase == "Night")
	
	setFXOnActive(fxState)
	setFXOffActive(not fxState)
	
	-- Update status badges
	if activeWeather == "clear" then
		updateWeatherStatus("☀️ Clear", C.Clear)
	elseif activeWeather == "raining" then
		updateWeatherStatus("🌧️ Rain", C.Rain)
	elseif activeWeather == "snowing" then
		updateWeatherStatus("❄️ Snow", C.Snow)
	end
	
	if currentPhase == "Day" then
		updateTimeStatus("🌞 Day", C.Clear)
	else
		updateTimeStatus("🌙 Night", Color3.fromRGB(100, 100, 180))
	end
	
	if fxState then
		updateFXStatus("✓ FX On", C.Success)
	else
		updateFXStatus("✗ FX Off", C.TextDim)
	end
end

-- Button handlers
btnClear.MouseButton1Click:Connect(function()
	activeWeather = "clear"
	fxState = true
	setWeather("clear", currentPhase, true)
	refreshUI()
end)

btnRain.MouseButton1Click:Connect(function()
	activeWeather = "raining"
	fxState = true
	setWeather("raining", currentPhase, true)
	refreshUI()
end)

btnSnow.MouseButton1Click:Connect(function()
	activeWeather = "snowing"
	fxState = true
	setWeather("snowing", currentPhase, true)
	refreshUI()
end)

btnDay.MouseButton1Click:Connect(function()
	setPhase("Day")
	refreshUI()
end)

btnNight.MouseButton1Click:Connect(function()
	setPhase("Night")
	refreshUI()
end)

btnFXOn.MouseButton1Click:Connect(function()
	fxState = true
	setWeatherFXEnabled(true)
	refreshUI()
end)

btnFXOff.MouseButton1Click:Connect(function()
	fxState = false
	setWeatherFXEnabled(false)
	refreshUI()
end)

btnReset.MouseButton1Click:Connect(function()
	resetToBaseline()
	activeWeather = baseline.weatherKey or "clear"
	fxState = true
	refreshUI()
end)

closeBtn.MouseButton1Click:Connect(function()
	resetToBaseline()
	gui:Destroy()
end)

-- Minimize
local minimized = false

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == MINIMIZE_KEY and gui.Parent then
		minimized = not minimized
		if minimized then
			main.Visible = false
		else
			main.Visible = true
		end
	end
end)

-- Startup
captureBaselineOnce()
activeWeather = baseline.weatherKey or "clear"
refreshUI()

main.BackgroundTransparency = 1
tween(main, TweenInfo.new(0.3), {BackgroundTransparency = 0})

print("[WeatherGUI] ✨ Beautiful UI loaded!")
