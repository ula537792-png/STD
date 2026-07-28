local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

local UI_COLORS = {
	BG = Color3.fromRGB(10, 8, 15),
	SIDEBAR = Color3.fromRGB(13, 10, 18),
	TAB_INACTIVE = Color3.fromRGB(18, 14, 25),
	TAB_ACTIVE = Color3.fromRGB(175, 45, 240),
	ACCENT_GLOW = Color3.fromRGB(150, 30, 210),
	CHECKBOX_OFF = Color3.fromRGB(24, 18, 35),
	TEXT = Color3.fromRGB(250, 245, 255),
	TEXT_DIM = Color3.fromRGB(160, 150, 180)
}

local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	root = c:WaitForChild("HumanoidRootPart")
end)

local old = CoreGui:FindFirstChild("InveriumHub")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InveriumHub"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Parent = CoreGui

-- АДАПТИВНЫЙ SCALE (АВТОМАТИЧЕСКИЙ ПОДГОН ПОД ПК И ТЕЛЕФОНЫ)
local uiScale = Instance.new("UIScale", screenGui)

local function updateScale()
	local viewport = camera.ViewportSize
	-- Базовое разрешение, под которое создавалось меню (например, стандартный ПК-экран)
	local baseSize = Vector2.new(1280, 720)
	
	-- Вычисляем коэффициент масштабирования с ограничениями, чтобы на телефонах меню не было микроскопическим, а на 4K мониторах — гигантским
	local scaleX = viewport.X / baseSize.X
	local scaleY = viewport.Y / baseSize.Y
	local finalScale = math.clamp(math.min(scaleX, scaleY), 0.65, 1.1)
	
	-- Если это мобильное устройство (маленькая ширина экрана), делаем интерфейс чуть крупнее для удобства нажатия пальцем
	if viewport.X < 800 then
		finalScale = math.clamp(viewport.X / 750, 0.6, 0.95)
	end
	
	uiScale.Scale = finalScale
end

updateScale()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- ЗАСТАВКА
local welcomeFrame = Instance.new("Frame", screenGui)
welcomeFrame.Size = UDim2.new(0, 360, 0, 90)
welcomeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
welcomeFrame.AnchorPoint = Vector2.new(0.5, 0.5)
welcomeFrame.BackgroundColor3 = Color3.fromRGB(8, 6, 12) 
welcomeFrame.BorderSizePixel = 0
welcomeFrame.BackgroundTransparency = 1
welcomeFrame.ZIndex = 5

Instance.new("UICorner", welcomeFrame).CornerRadius = UDim.new(0, 14)

local welcomeStroke = Instance.new("UIStroke", welcomeFrame)
welcomeStroke.Color = Color3.fromRGB(150, 30, 210) 
welcomeStroke.Transparency = 1
welcomeStroke.Thickness = 1.5

local welcomeText = Instance.new("TextLabel", welcomeFrame)
welcomeText.Size = UDim2.new(1, 0, 1, 0)
welcomeText.Position = UDim2.new(0, 0, 0, 0)
welcomeText.Text = "Welcome to Inverium"
welcomeText.TextColor3 = Color3.fromRGB(240, 230, 255)
welcomeText.Font = Enum.Font.GothamBold
welcomeText.TextSize = 16
welcomeText.BackgroundTransparency = 1
welcomeText.TextTransparency = 1
welcomeText.ZIndex = 6

-- ГЛАВНОЕ ОКНО (С АДАПТИВНЫМ РАЗМЕРОМ ПОД МАЛЕНЬКИЕ ЭКРАНЫ)
local main = Instance.new("Frame", screenGui)
-- Если экран телефона слишком узкий, окно автоматически сужается, чтобы не выходить за края
local initialWidth = math.min(800, camera.ViewportSize.X - 40)
local initialHeight = math.min(480, camera.ViewportSize.Y - 60)
main.Size = UDim2.new(0, initialWidth, 0, initialHeight)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = UI_COLORS.BG
main.BorderSizePixel = 0
main.Visible = false
main.BackgroundTransparency = 1
main.ClipsDescendants = false
main.Active = true

local sizeConstraint = Instance.new("UISizeConstraint", main)
sizeConstraint.MinSize = Vector2.new(400, 280)
sizeConstraint.MaxSize = Vector2.new(1100, 750)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = UI_COLORS.TAB_ACTIVE
mainStroke.Transparency = 1
mainStroke.Thickness = 1.5
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

-- КНОПКА МЕНЮ НА ЭКРАНЕ (ДЛЯ РЕЖИМА BUTTON)
local toggleMenuBtn = Instance.new("TextButton", screenGui)
toggleMenuBtn.Size = UDim2.new(0, 120, 0, 40)
toggleMenuBtn.Position = UDim2.new(0, 30, 0, 30)
toggleMenuBtn.BackgroundColor3 = UI_COLORS.SIDEBAR
toggleMenuBtn.Text = "MENU"
toggleMenuBtn.TextColor3 = UI_COLORS.TEXT
toggleMenuBtn.Font = Enum.Font.GothamBold
toggleMenuBtn.TextSize = 14
toggleMenuBtn.Visible = false
toggleMenuBtn.Active = true
toggleMenuBtn.ZIndex = 99999
Instance.new("UICorner", toggleMenuBtn).CornerRadius = UDim.new(0, 10)

local toggleMenuStroke = Instance.new("UIStroke", toggleMenuBtn)
toggleMenuStroke.Color = UI_COLORS.TAB_ACTIVE
toggleMenuStroke.Thickness = 1.5
toggleMenuStroke.Transparency = 0.3

-- Перетаскивание экранной кнопки меню
local btnDragging, btnDragStart, btnStartPos
toggleMenuBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		btnDragging = true
		btnDragStart = input.Position
		btnStartPos = toggleMenuBtn.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				btnDragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - btnDragStart
		toggleMenuBtn.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
	end
end)

-- УГОЛОК ИЗМЕНЕНИЯ РАЗМЕРА
local resizeHandle = Instance.new("Frame", main)
resizeHandle.Size = UDim2.new(0, 32, 0, 32)
resizeHandle.Position = UDim2.new(1, -2, 1, -2)
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
resizeHandle.BackgroundTransparency = 0.2
resizeHandle.ZIndex = 100
Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 10)

local resizeStroke = Instance.new("UIStroke", resizeHandle)
resizeStroke.Color = Color3.fromRGB(255, 255, 255)
resizeStroke.Thickness = 1.5
resizeStroke.Transparency = 0.4

for i = 1, 3 do
	local line = Instance.new("Frame", resizeHandle)
	line.Size = UDim2.new(0, 18 - (i * 3), 0, 2)
	line.Position = UDim2.new(1, -6, 1, - (i * 5))
	line.AnchorPoint = Vector2.new(1, 1)
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BackgroundTransparency = 0.25
	line.BorderSizePixel = 0
	line.Rotation = -45
	Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)
end

local resizing = false
local resizeStartPos, startMainSize

resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		resizeStartPos = input.Position
		startMainSize = main.AbsoluteSize
		
		TweenService:Create(resizeHandle, TweenInfo.new(0.2), {BackgroundTransparency = 0, Rotation = 10}):Play()
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				resizing = false
				TweenService:Create(resizeHandle, TweenInfo.new(0.2), {BackgroundTransparency = 0.2, Rotation = 0}):Play()
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - resizeStartPos
		local newX = math.clamp(startMainSize.X + delta.X, sizeConstraint.MinSize.X, sizeConstraint.MaxSize.X)
		local newY = math.clamp(startMainSize.Y + delta.Y, sizeConstraint.MinSize.Y, sizeConstraint.MaxSize.Y)
		main.Size = UDim2.new(0, newX, 0, newY)
	end
end)

-- Перетаскивание главного окна
local isInteractingWithSlider = false
local dragging, dragStart, startPos

main.InputBegan:Connect(function(input)
	if isInteractingWithSlider or resizing then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and not isInteractingWithSlider and not resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Фоновые частицы
local bgContainer = Instance.new("Frame", main)
bgContainer.Size = UDim2.new(1, 0, 1, 0)
bgContainer.BackgroundTransparency = 1
bgContainer.ClipsDescendants = true
bgContainer.ZIndex = 0

local function spawnParticle()
	if not main.Parent then return end
	local p = Instance.new("Frame", bgContainer)
	local size = math.random(3, 7)
	p.Size = UDim2.new(0, size, 0, size)
	local startX = math.random()
	p.Position = UDim2.new(startX, 0, 1.1, 0)
	p.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
	p.BackgroundTransparency = math.random(3, 7) / 10
	p.BorderSizePixel = 0
	p.ZIndex = 1
	Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)
	
	local duration = math.random(4, 7)
	local endX = startX + (math.random() - 0.5) * 0.3
	
	local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Position = UDim2.new(endX, 0, -0.1, 0),
		BackgroundTransparency = 1
	})
	
	tween:Play()
	tween.Completed:Connect(function()
		p:Destroy()
		spawnParticle()
	end)
end

local function startParticles()
	for i = 1, 30 do
		task.delay(math.random() * 3, spawnParticle)
	end
end

-- САЙДБАР (С адаптивной шириной под размер окна)
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 190, 1, 0)
sidebar.BackgroundColor3 = UI_COLORS.SIDEBAR
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 14)

local sideCover = Instance.new("Frame", sidebar)
sideCover.Size = UDim2.new(0, 14, 1, 0)
sideCover.Position = UDim2.new(1, -14, 0, 0)
sideCover.BackgroundColor3 = UI_COLORS.SIDEBAR
sideCover.BorderSizePixel = 0

local logo = Instance.new("TextLabel", sidebar)
logo.Size = UDim2.new(1, 0, 0, 55)
logo.BackgroundTransparency = 1
logo.Text = "INVERIUM"
logo.Font = Enum.Font.GothamBlack
logo.TextSize = 18
logo.TextColor3 = UI_COLORS.TEXT

local logoGlow = Instance.new("UIStroke", logo)
logoGlow.Color = UI_COLORS.TAB_ACTIVE
logoGlow.Thickness = 1
logoGlow.Transparency = 0.6

local function createTabButton(name, y)
	local b = Instance.new("TextButton", sidebar)
	b.Size = UDim2.new(1, -16, 0, 38)
	b.Position = UDim2.new(0, 8, 0, y)
	b.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
	b.Text = "   " .. name
	b.TextColor3 = UI_COLORS.TEXT_DIM
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 12
	b.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	
	b.MouseEnter:Connect(function()
		if b.BackgroundColor3 ~= UI_COLORS.TAB_ACTIVE then
			b.TextColor3 = UI_COLORS.TEXT
		end
	end)
	b.MouseLeave:Connect(function()
		if b.BackgroundColor3 ~= UI_COLORS.TAB_ACTIVE then
			b.TextColor3 = UI_COLORS.TEXT_DIM
		end
	end)
	return b
end

local btnMain = createTabButton("Player", 65)
local btnInfo = createTabButton("Player Info", 107)
local btnInv = createTabButton("Dupe", 149)
local btnTrade = createTabButton("Trade Scam", 191)
local btnConfig = createTabButton("PC/Mobile", 233)

-- СТРАНИЦЫ
local pages = Instance.new("Frame", main)
pages.Size = UDim2.new(1, -205, 1, -16)
pages.Position = UDim2.new(0, 198, 0, 8)
pages.BackgroundTransparency = 1

local function createPage()
	local p = Instance.new("ScrollingFrame", pages)
	p.Size = UDim2.new(1, 0, 1, 0)
	p.BackgroundTransparency = 1
	p.ScrollBarThickness = 4
	p.ScrollBarImageColor3 = UI_COLORS.TAB_ACTIVE
	p.AutomaticCanvasSize = Enum.AutomaticSize.Y
	p.Visible = false
	local layout = Instance.new("UIListLayout", p)
	layout.Padding = UDim.new(0, 8)
	return p
end

local mainPage = createPage()
mainPage.Visible = true
local infoPage = createPage()
local invPage = createPage()
local tradePage = createPage()
local configPage = createPage()

local activeTabBtn = btnMain
local function setActiveTab(btn, page)
	if activeTabBtn then
		activeTabBtn.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
		activeTabBtn.TextColor3 = UI_COLORS.TEXT_DIM
	end
	activeTabBtn = btn
	btn.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
	btn.TextColor3 = UI_COLORS.TEXT
	
	mainPage.Visible = (mainPage == page)
	infoPage.Visible = (infoPage == page)
	invPage.Visible = (invPage == page)
	tradePage.Visible = (tradePage == page)
	configPage.Visible = (configPage == page)
end

-- SHIFT LOCK
local shiftLockEnabled = false
local isShiftLocked = false

local shiftLockBtn = Instance.new("TextButton", screenGui)
shiftLockBtn.Size = UDim2.new(0, 50, 0, 50)
shiftLockBtn.Position = UDim2.new(1, -70, 0.5, -25)
shiftLockBtn.AnchorPoint = Vector2.new(0, 0.5)
shiftLockBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
shiftLockBtn.Text = "SL"
shiftLockBtn.TextColor3 = UI_COLORS.TEXT_DIM
shiftLockBtn.Font = Enum.Font.GothamBold
shiftLockBtn.TextSize = 16
shiftLockBtn.Visible = false
shiftLockBtn.Active = true
shiftLockBtn.ZIndex = 9999
Instance.new("UICorner", shiftLockBtn).CornerRadius = UDim.new(1, 0)

local shiftLockStroke = Instance.new("UIStroke", shiftLockBtn)
shiftLockStroke.Color = UI_COLORS.TAB_ACTIVE
shiftLockStroke.Thickness = 1.5
shiftLockStroke.Transparency = 0.5

local isShiftLockRepositioning = false
local slDragging = false
local slDragStart, slStartPos

shiftLockBtn.MouseButton1Click:Connect(function()
	if isShiftLockRepositioning then return end
	isShiftLocked = not isShiftLocked
	shiftLockBtn.TextColor3 = isShiftLocked and UI_COLORS.TEXT or UI_COLORS.TEXT_DIM
	shiftLockBtn.BackgroundColor3 = isShiftLocked and Color3.fromRGB(45, 25, 65) or Color3.fromRGB(20, 15, 30)
end)

shiftLockBtn.InputBegan:Connect(function(input)
	if isShiftLockRepositioning and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		slDragging = true
		slDragStart = input.Position
		slStartPos = shiftLockBtn.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				slDragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if slDragging and isShiftLockRepositioning and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - slDragStart
		shiftLockBtn.Position = UDim2.new(slStartPos.X.Scale, slStartPos.X.Offset + delta.X, slStartPos.Y.Scale, slStartPos.Y.Offset + delta.Y)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if shiftLockEnabled and isShiftLocked and char and root then
		local camCF = camera.CFrame
		local lookVector = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
		root.CFrame = CFrame.new(root.Position, root.Position + lookVector)
		hum.AutoRotate = false
	else
		if hum then hum.AutoRotate = true end
	end
end)

-- PC / MOBILE CONFIG PAGE
local closeMode = "key"

local configTitle = Instance.new("TextLabel", configPage)
configTitle.Size = UDim2.new(1, -5, 0, 20)
configTitle.BackgroundTransparency = 1
configTitle.Text = "MENU CLOSE CONFIGURATION"
configTitle.TextColor3 = UI_COLORS.TEXT
configTitle.Font = Enum.Font.GothamBold
configTitle.TextSize = 12
configTitle.TextXAlignment = Enum.TextXAlignment.Left

local configDesc = Instance.new("TextLabel", configPage)
configDesc.Size = UDim2.new(1, -5, 0, 25)
configDesc.BackgroundTransparency = 1
configDesc.Text = "Choose how you want to open/close the hub interface:"
configDesc.TextColor3 = UI_COLORS.TEXT_DIM
configDesc.Font = Enum.Font.GothamSemibold
configDesc.TextSize = 11
configDesc.TextXAlignment = Enum.TextXAlignment.Left

local btnModeKey = Instance.new("TextButton", configPage)
btnModeKey.Size = UDim2.new(1, -5, 0, 42)
btnModeKey.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
btnModeKey.Text = "    Mode: Key [ INSERT ]"
btnModeKey.TextColor3 = UI_COLORS.TEXT
btnModeKey.Font = Enum.Font.GothamSemibold
btnModeKey.TextSize = 12
btnModeKey.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", btnModeKey).CornerRadius = UDim.new(0, 10)

local btnModeBtn = Instance.new("TextButton", configPage)
btnModeBtn.Size = UDim2.new(1, -5, 0, 42)
btnModeBtn.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
btnModeBtn.Text = "    Mode:Button"
btnModeBtn.TextColor3 = UI_COLORS.TEXT_DIM
btnModeBtn.Font = Enum.Font.GothamSemibold
btnModeBtn.TextSize = 12
btnModeBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", btnModeBtn).CornerRadius = UDim.new(0, 10)

btnModeKey.MouseButton1Click:Connect(function()
	closeMode = "key"
	btnModeKey.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
	btnModeKey.TextColor3 = UI_COLORS.TEXT
	btnModeBtn.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
	btnModeBtn.TextColor3 = UI_COLORS.TEXT_DIM
	toggleMenuBtn.Visible = false
end)

btnModeBtn.MouseButton1Click:Connect(function()
	closeMode = "button"
	btnModeBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
	btnModeBtn.TextColor3 = UI_COLORS.TEXT
	btnModeKey.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
	btnModeKey.TextColor3 = UI_COLORS.TEXT_DIM
	toggleMenuBtn.Visible = true
end)

toggleMenuBtn.MouseButton1Click:Connect(function()
	if closeMode == "button" and not btnDragging then
		main.Visible = not main.Visible
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.Insert and closeMode == "key" then
		main.Visible = not main.Visible
	end
end)

local slDivider = Instance.new("Frame", configPage)
slDivider.Size = UDim2.new(1, -5, 0, 15)
slDivider.BackgroundTransparency = 1

local slConfigTitle = Instance.new("TextLabel", configPage)
slConfigTitle.Size = UDim2.new(1, -5, 0, 20)
slConfigTitle.BackgroundTransparency = 1
slConfigTitle.Text = "SHIFT LOCK SETTINGS"
slConfigTitle.TextColor3 = UI_COLORS.TEXT
slConfigTitle.Font = Enum.Font.GothamBold
slConfigTitle.TextSize = 12
slConfigTitle.TextXAlignment = Enum.TextXAlignment.Left

local btnSLToggle = Instance.new("TextButton", configPage)
btnSLToggle.Size = UDim2.new(1, -5, 0, 42)
btnSLToggle.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
btnSLToggle.Text = "    Mobile Shift Lock: OFF"
btnSLToggle.TextColor3 = UI_COLORS.TEXT_DIM
btnSLToggle.Font = Enum.Font.GothamSemibold
btnSLToggle.TextSize = 12
btnSLToggle.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", btnSLToggle).CornerRadius = UDim.new(0, 10)

btnSLToggle.MouseButton1Click:Connect(function()
	shiftLockEnabled = not shiftLockEnabled
	shiftLockBtn.Visible = shiftLockEnabled
	btnSLToggle.BackgroundColor3 = shiftLockEnabled and Color3.fromRGB(35, 20, 50) or UI_COLORS.TAB_INACTIVE
	btnSLToggle.TextColor3 = shiftLockEnabled and UI_COLORS.TEXT or UI_COLORS.TEXT_DIM
	btnSLToggle.Text = "    Mobile Shift Lock: " .. (shiftLockEnabled and "ON" or "OFF")
	if not shiftLockEnabled then 
		isShiftLocked = false 
		isShiftLockRepositioning = false
	end
end)

local btnSLPos = Instance.new("TextButton", configPage)
btnSLPos.Size = UDim2.new(1, -5, 0, 42)
btnSLPos.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
btnSLPos.Text = "    Reposition Shift Lock: OFF"
btnSLPos.TextColor3 = UI_COLORS.TEXT_DIM
btnSLPos.Font = Enum.Font.GothamSemibold
btnSLPos.TextSize = 12
btnSLPos.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", btnSLPos).CornerRadius = UDim.new(0, 10)

btnSLPos.MouseButton1Click:Connect(function()
	isShiftLockRepositioning = not isShiftLockRepositioning
	btnSLPos.BackgroundColor3 = isShiftLockRepositioning and Color3.fromRGB(35, 20, 50) or UI_COLORS.TAB_INACTIVE
	btnSLPos.TextColor3 = isShiftLockRepositioning and UI_COLORS.TEXT or UI_COLORS.TEXT_DIM
	btnSLPos.Text = "    Reposition Shift Lock: " .. (isShiftLockRepositioning and "UNLOCKED (Drag it)" or "LOCKED")
	
	if isShiftLockRepositioning then
		shiftLockBtn.Visible = true
		shiftLockStroke.Color = Color3.fromRGB(255, 100, 255)
		shiftLockStroke.Transparency = 0.1
	else
		shiftLockStroke.Color = UI_COLORS.TAB_ACTIVE
		shiftLockStroke.Transparency = 0.5
		if not shiftLockEnabled then
			shiftLockBtn.Visible = false
		end
	end
end)

-- PLAYER MODULE
local flyEnabled = false
local flySpeed = 50
local speedEnabled = false
local speedValue = 16
local spinEnabled = false
local spinSpeed = 15
local noclipEnabled = false

local function addToggle(name, callback)
	local b = Instance.new("TextButton", mainPage)
	b.Size = UDim2.new(1, -5, 0, 42)
	b.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
	b.Text = "    " .. name
	b.TextColor3 = UI_COLORS.TEXT
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 12
	b.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

	local statusLbl = Instance.new("TextLabel", b)
	statusLbl.Size = UDim2.new(0, 80, 1, 0)
	statusLbl.Position = UDim2.new(1, -90, 0, 0)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "OFF"
	statusLbl.TextColor3 = UI_COLORS.TEXT_DIM
	statusLbl.Font = Enum.Font.GothamBold
	statusLbl.TextSize = 11
	statusLbl.TextXAlignment = Enum.TextXAlignment.Right

	local state = false
	b.MouseButton1Click:Connect(function()
		state = not state
		statusLbl.Text = state and "ON" or "OFF"
		statusLbl.TextColor3 = state and UI_COLORS.TEXT or UI_COLORS.TEXT_DIM
		b.BackgroundColor3 = state and Color3.fromRGB(35, 20, 50) or UI_COLORS.TAB_INACTIVE
		callback(state)
	end)
end

local function addSlider(name, min, max, default, callback)
	local container = Instance.new("Frame", mainPage)
	container.Size = UDim2.new(1, -5, 0, 48)
	container.BackgroundTransparency = 1
	container.ZIndex = 2

	local label = Instance.new("TextLabel", container)
	label.Text = name .. ": " .. string.format("%.2f", default)
	label.TextColor3 = UI_COLORS.TEXT
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 2

	local bg = Instance.new("Frame", container)
	bg.Size = UDim2.new(1, 0, 0, 8)
	bg.Position = UDim2.new(0, 0, 0, 24)
	bg.BackgroundColor3 = UI_COLORS.CHECKBOX_OFF
	bg.ZIndex = 2
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

	local bar = Instance.new("Frame", bg)
	bar.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
	bar.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
	bar.ZIndex = 2
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

	local draggingSlider = false
	bg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
			draggingSlider = true
			isInteractingWithSlider = true
			dragging = false
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
			if draggingSlider then
				draggingSlider = false
				isInteractingWithSlider = false
			end
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mousePos = UserInputService:GetMouseLocation()
			local relativeX = math.clamp(mousePos.X - bg.AbsolutePosition.X, 0, bg.AbsoluteSize.X)
			local percent = relativeX / bg.AbsoluteSize.X
			local rawVal = min + (max - min) * percent
			local val = math.floor(rawVal * 100) / 100
			
			bar.Size = UDim2.new(percent, 0, 1, 0)
			label.Text = name .. ": " .. string.format("%.2f", val)
			callback(val)
		end
	end)
end

addToggle("Fly", function(v) flyEnabled = v end)
addSlider("Fly Speed", 10, 200, 50, function(v) flySpeed = v end)

addToggle("Speed Hack", function(v) speedEnabled = v end)
addSlider("Speed Multiplier", 16, 100, 16, function(v) speedValue = v end)

addToggle("Spin Bot", function(v) spinEnabled = v end)
addSlider("Spin Speed", 5, 100, 15, function(v) spinSpeed = v end)

addToggle("Noclip", function(v) noclipEnabled = v end)

RunService.RenderStepped:Connect(function(dt)
	if spinEnabled and root then
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
	end
	if speedEnabled and hum then
		hum.WalkSpeed = speedValue
	end
	if noclipEnabled and char then
		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide = false end
		end
	end
end)

local function getMoveVector()
	local moveDir = Vector3.new()
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then moveDir += Vector3.new(0, 0, -1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then moveDir += Vector3.new(0, 0, 1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then moveDir += Vector3.new(-1, 0, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then moveDir += Vector3.new(1, 0, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir += Vector3.new(0, -1, 0) end
	if hum and hum.MoveDirection.Magnitude > 0 and moveDir.Magnitude == 0 then
		moveDir = camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
	end
	return moveDir
end

RunService.Heartbeat:Connect(function(dt)
	if flyEnabled and root then
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		local move = getMoveVector()
		if move.Magnitude > 0 then
			local velocity = (camera.CFrame.LookVector * -move.Z + camera.CFrame.RightVector * move.X + Vector3.new(0, move.Y, 0)) * flySpeed
			root.CFrame = root.CFrame + (velocity * dt)
		end
	end
end)

-- PLAYER INFO
local currentTarget = player

local infoWrapper = Instance.new("Frame", infoPage)
infoWrapper.Size = UDim2.new(1, -5, 0, 0)
infoWrapper.AutomaticSize = Enum.AutomaticSize.Y
infoWrapper.BackgroundTransparency = 1

local infoList = Instance.new("UIListLayout", infoWrapper)
infoList.SortOrder = Enum.SortOrder.LayoutOrder
infoList.Padding = UDim.new(0, 8)

local topInfoSection = Instance.new("Frame", infoWrapper)
topInfoSection.LayoutOrder = 1
topInfoSection.Size = UDim2.new(1, 0, 0, 120)
topInfoSection.BackgroundTransparency = 1

local avatarFrame = Instance.new("Frame", topInfoSection)
avatarFrame.Size = UDim2.new(0, 110, 0, 110)
avatarFrame.Position = UDim2.new(0, 4, 0, 3)
avatarFrame.BackgroundColor3 = UI_COLORS.SIDEBAR
Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(0, 12)

local avatarStroke = Instance.new("UIStroke", avatarFrame)
avatarStroke.Color = UI_COLORS.TAB_ACTIVE
avatarStroke.Thickness = 1.5
avatarStroke.Transparency = 0.4

local avatar = Instance.new("ImageLabel", avatarFrame)
avatar.Size = UDim2.new(1, -8, 1, -8)
avatar.Position = UDim2.new(0, 4, 0, 4)
avatar.BackgroundTransparency = 1
Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 8)

local infoCardsScroll = Instance.new("ScrollingFrame", topInfoSection)
infoCardsScroll.Size = UDim2.new(1, -125, 0, 110)
infoCardsScroll.Position = UDim2.new(0, 120, 0, 3)
infoCardsScroll.BackgroundTransparency = 1
infoCardsScroll.ScrollBarThickness = 4
infoCardsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local infoLayoutGrid = Instance.new("UIListLayout", infoCardsScroll)
infoLayoutGrid.SortOrder = Enum.SortOrder.LayoutOrder
infoLayoutGrid.Padding = UDim.new(0, 6)

local function createInfoCard(labelTitle)
	local f = Instance.new("Frame", infoCardsScroll)
	f.Size = UDim2.new(1, -6, 0, 32)
	f.BackgroundColor3 = UI_COLORS.SIDEBAR
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
	
	local stroke = Instance.new("UIStroke", f)
	stroke.Color = UI_COLORS.TAB_ACTIVE
	stroke.Transparency = 0.85
	stroke.Thickness = 1

	local title = Instance.new("TextLabel", f)
	title.Size = UDim2.new(1, -10, 0, 12)
	title.Position = UDim2.new(0, 6, 0, 3)
	title.BackgroundTransparency = 1
	title.Text = labelTitle
	title.TextColor3 = UI_COLORS.TEXT_DIM
	title.Font = Enum.Font.GothamBold
	title.TextSize = 9
	title.TextXAlignment = Enum.TextXAlignment.Left

	local val = Instance.new("TextLabel", f)
	val.Size = UDim2.new(1, -10, 0, 16)
	val.Position = UDim2.new(0, 6, 0, 13)
	val.BackgroundTransparency = 1
	val.Text = "Loading..."
	val.TextColor3 = UI_COLORS.TEXT
	val.Font = Enum.Font.GothamSemibold
	val.TextSize = 11
	val.TextXAlignment = Enum.TextXAlignment.Left
	return val
end

local nameT = createInfoCard("USERNAME")
local displayT = createInfoCard("DISPLAY NAME")
local idT = createInfoCard("USER ID")
local ageT = createInfoCard("ACCOUNT AGE")
local speedT = createInfoCard("WALKSPEED")
local healthT = createInfoCard("HEALTH")
local pingT = createInfoCard("SERVER PING")
local stateT = createInfoCard("HUMANOID STATE")

local actionPanel = Instance.new("Frame", infoWrapper)
actionPanel.LayoutOrder = 2
actionPanel.Size = UDim2.new(1, 0, 0, 260)
actionPanel.BackgroundColor3 = UI_COLORS.SIDEBAR
Instance.new("UICorner", actionPanel).CornerRadius = UDim.new(0, 12)

local actionTitle = Instance.new("TextLabel", actionPanel)
actionTitle.Size = UDim2.new(1, -16, 0, 30)
actionTitle.Position = UDim2.new(0, 10, 0, 4)
actionTitle.BackgroundTransparency = 1
actionTitle.Text = "SELECT TARGET PLAYER"
actionTitle.TextColor3 = UI_COLORS.TEXT
actionTitle.Font = Enum.Font.GothamBold
actionTitle.TextSize = 11
actionTitle.TextXAlignment = Enum.TextXAlignment.Left

local playerScroll = Instance.new("ScrollingFrame", actionPanel)
playerScroll.Size = UDim2.new(1, -16, 1, -36)
playerScroll.Position = UDim2.new(0, 8, 0, 32)
playerScroll.BackgroundTransparency = 1
playerScroll.ScrollBarThickness = 4
playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local playerListLayout = Instance.new("UIGridLayout", playerScroll)
playerListLayout.CellSize = UDim2.new(0.48, 0, 0, 34)
playerListLayout.CellPadding = UDim2.new(0, 6, 0, 6)

local function updateInfo(plr)
	local charPlr = plr.Character
	local humPlr = charPlr and charPlr:FindFirstChild("Humanoid")
	nameT.Text = plr.Name
	displayT.Text = plr.DisplayName
	idT.Text = tostring(plr.UserId)
	ageT.Text = tostring(plr.AccountAge) .. " days"
	speedT.Text = tostring(humPlr and math.floor(humPlr.WalkSpeed) or 0)
	healthT.Text = tostring(humPlr and math.floor(humPlr.Health) or 0) .. " HP"
	
	local success, pingVal = pcall(function()
		return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
	end)
	pingT.Text = success and (pingVal .. "ms") or "N/A"
	
	stateT.Text = humPlr and humPlr:GetState().Name or "None"
	avatar.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end

local function refreshPlayerList()
	for _, v in ipairs(playerScroll:GetChildren()) do
		if v:IsA("TextButton") then v:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local btn = Instance.new("TextButton", playerScroll)
		btn.BackgroundColor3 = (currentTarget == p) and Color3.fromRGB(40, 22, 60) or UI_COLORS.TAB_INACTIVE
		btn.Text = "  " .. p.Name
		btn.TextColor3 = (currentTarget == p) and UI_COLORS.TEXT or UI_COLORS.TEXT_DIM
		btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 11
		btn.TextXAlignment = Enum.TextXAlignment.Left
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		
		btn.MouseButton1Click:Connect(function()
			currentTarget = p
			updateInfo(p)
			refreshPlayerList()
		end)
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		if currentTarget and currentTarget.Parent then 
			updateInfo(currentTarget) 
		else
			currentTarget = player
		end
	end
end)

-- DUPE & TRADE SCAM
local dupeCount = 1
local tradeCount = 1

local function getUnitKey(unit)
	if not unit then return nil end
	local id = unit:GetAttribute("ID")
	if id ~= nil then return "ID_" .. tostring(id) end
	return unit.Name .. "_" .. tostring(unit:GetDebugId())
end

local function getIcon(unit)
	local ti = unit:FindFirstChild("TowerImage", true)
	if ti and ti:IsA("ImageLabel") and ti.Image ~= "" then 
		return ti.Image 
	end
	return ""
end

local function scanInventory()
	local inventoryUnique, seen = {}, {}
	local inv = playerGui:FindFirstChild("Inventory")
	if not inv then return inventoryUnique end
	local units = inv:FindFirstChild("Inventory", true) or inv:FindFirstChild("Units", true)
	if not units then return inventoryUnique end
	local folder = units:FindFirstChild("Units") or units
	for _, unit in ipairs(folder:GetChildren()) do
		if unit:IsA("GuiObject") or unit:IsA("Instance") then
			local key = getUnitKey(unit)
			if key and not seen[key] then
				seen[key] = true
				table.insert(inventoryUnique, unit)
			end
		end
	end
	return inventoryUnique
end

local function scanTrade()
	local tradeUnique, seen = {}, {}
	local trading = playerGui:FindFirstChild("Trading", true)
	if not trading then return tradeUnique end
	
	for _, descendant in ipairs(trading:GetDescendants()) do
		if descendant.Name == "PlayerInv" or descendant.Name == "Inventory" or descendant.Name == "Units" then
			for _, unit in ipairs(descendant:GetChildren()) do
				local key = getUnitKey(unit)
				if key and not seen[key] then
					seen[key] = true
					table.insert(tradeUnique, unit)
				end
			end
		end
	end
	
	if #tradeUnique == 0 then
		for _, descendant in ipairs(trading:GetDescendants()) do
			if descendant:IsA("ImageButton") or descendant:IsA("TextButton") or descendant:IsA("Frame") then
				if descendant:FindFirstChild("TowerImage", true) or descendant:FindFirstChild("ViewportFrame", true) then
					local key = getUnitKey(descendant)
					if key and not seen[key] then
						seen[key] = true
						table.insert(tradeUnique, descendant)
					end
				end
			end
		end
	end
	
	return tradeUnique
end

local function setupDupePage(page, isTrade)
	local existingPanel = page:FindFirstChild("TopPanel")
	if existingPanel then existingPanel:Destroy() end
	local existingGrid = page:FindFirstChild("GridContainer")
	if existingGrid then existingGrid:Destroy() end

	local topPanel = Instance.new("Frame", page)
	topPanel.Name = "TopPanel"
	topPanel.Size = UDim2.new(1, -5, 0, 115)
	topPanel.BackgroundColor3 = UI_COLORS.SIDEBAR
	Instance.new("UICorner", topPanel).CornerRadius = UDim.new(0, 12)

	local countLabel = Instance.new("TextLabel", topPanel)
	countLabel.Size = UDim2.new(1, -16, 0, 22)
	countLabel.Position = UDim2.new(0, 8, 0, 6)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = "Target Instances Multiplier: " .. (isTrade and tradeCount or dupeCount)
	countLabel.TextColor3 = UI_COLORS.TEXT
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextSize = 11
	countLabel.TextXAlignment = Enum.TextXAlignment.Left

	local sliderBg = Instance.new("Frame", topPanel)
	sliderBg.Size = UDim2.new(1, -16, 0, 8)
	sliderBg.Position = UDim2.new(0, 8, 0, 30)
	sliderBg.BackgroundColor3 = UI_COLORS.CHECKBOX_OFF
	Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 4)

	local currentVal = isTrade and tradeCount or dupeCount
	local sliderBar = Instance.new("Frame", sliderBg)
	sliderBar.Size = UDim2.new(math.clamp((currentVal - 1) / 49, 0, 1), 0, 1, 0)
	sliderBar.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
	Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 4)

	local draggingSlider = false
	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
			draggingSlider = true
			isInteractingWithSlider = true
			dragging = false
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
			if draggingSlider then
				draggingSlider = false
				isInteractingWithSlider = false
			end
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mousePos = UserInputService:GetMouseLocation()
			local relativeX = math.clamp(mousePos.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
			local percent = sliderBg.AbsoluteSize.X > 0 and (relativeX / sliderBg.AbsoluteSize.X) or 0
			local val = math.max(1, math.floor(1 + percent * 49))
			
			sliderBar.Size = UDim2.new(percent, 0, 1, 0)
			countLabel.Text = "Target Instances Multiplier: " .. val
			if isTrade then tradeCount = val else dupeCount = val end
		end
	end)

	local btnAll = Instance.new("TextButton", topPanel)
	btnAll.Size = UDim2.new(0.48, 0, 0, 30)
	btnAll.Position = UDim2.new(0, 8, 0, 42)
	btnAll.BackgroundColor3 = UI_COLORS.TAB_ACTIVE
	btnAll.Text = isTrade and "Auto-Scam All" or "Auto-Duplicate All"
	btnAll.TextColor3 = UI_COLORS.TEXT
	btnAll.Font = Enum.Font.GothamSemibold
	btnAll.TextSize = 11
	Instance.new("UICorner", btnAll).CornerRadius = UDim.new(0, 8)

	local safeModeActive = false
	local btnSafe = Instance.new("TextButton", topPanel)
	btnSafe.Size = UDim2.new(0.48, 0, 0, 30)
	btnSafe.Position = UDim2.new(0.52, -2, 0, 42)
	btnSafe.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
	btnSafe.Text = "Safe Delay: OFF"
	btnSafe.TextColor3 = UI_COLORS.TEXT_DIM
	btnSafe.Font = Enum.Font.GothamSemibold
	btnSafe.TextSize = 11
	Instance.new("UICorner", btnSafe).CornerRadius = UDim.new(0, 8)

	btnSafe.MouseButton1Click:Connect(function()
		safeModeActive = not safeModeActive
		btnSafe.BackgroundColor3 = safeModeActive and Color3.fromRGB(35, 20, 50) or UI_COLORS.TAB_INACTIVE
		btnSafe.TextColor3 = safeModeActive and UI_COLORS.TEXT or UI_COLORS.TEXT_DIM
		btnSafe.Text = "Safe Delay: " .. (safeModeActive and "ON" or "OFF")
	end)

	local boosterActive = false
	local btnBooster = Instance.new("TextButton", topPanel)
	btnBooster.Size = UDim2.new(1, -16, 0, 28)
	btnBooster.Position = UDim2.new(0, 8, 0, 78)
	btnBooster.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
	btnBooster.Text = "Booster x2: OFF"
	btnBooster.TextColor3 = UI_COLORS.TEXT_DIM
	btnBooster.Font = Enum.Font.GothamSemibold
	btnBooster.TextSize = 11
	Instance.new("UICorner", btnBooster).CornerRadius = UDim.new(0, 8)

	btnBooster.MouseButton1Click:Connect(function()
		boosterActive = not boosterActive
		btnBooster.BackgroundColor3 = boosterActive and Color3.fromRGB(35, 20, 50) or UI_COLORS.TAB_INACTIVE
		btnBooster.TextColor3 = boosterActive and UI_COLORS.TEXT or UI_COLORS.TEXT_DIM
		btnBooster.Text = "Booster x2: " .. (boosterActive and "ON" or "OFF")
	end)

	local gridContainer = Instance.new("ScrollingFrame", page)
	gridContainer.Name = "GridContainer"
	gridContainer.Size = UDim2.new(1, -5, 1, -125)
	gridContainer.Position = UDim2.new(0, 0, 0, 125)
	gridContainer.BackgroundTransparency = 1
	gridContainer.ScrollBarThickness = 4
	gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local grid = Instance.new("UIGridLayout", gridContainer)
	grid.CellSize = UDim2.new(0, 115, 0, 115)
	grid.CellPadding = UDim2.new(0, 8, 0, 8)

	local function executeDuplication(unit)
		if not unit or not unit.Parent then return end
		local baseCount = isTrade and tradeCount or dupeCount
		local finalCount = boosterActive and (baseCount * 2) or baseCount
		task.spawn(function()
			for i = 1, finalCount do
				local clone = unit:Clone()
				clone.Name = unit.Name .. "_clone_" .. tostring(tick()) .. "_" .. i
				if isTrade then
					local check = clone:FindFirstChild("Checkmark", true)
					if check and check:IsA("ImageLabel") then check.Visible = true end
				end
				clone.Parent = unit.Parent
				if safeModeActive then task.wait(0.04) end
			end
		end)
	end

	btnAll.MouseButton1Click:Connect(function()
		local items = isTrade and scanTrade() or scanInventory()
		for _, unit in ipairs(items) do
			executeDuplication(unit)
		end
	end)

	local items = isTrade and scanTrade() or scanInventory()
	for _, unit in ipairs(items) do
		local cardBtn = Instance.new("TextButton", gridContainer)
		cardBtn.Size = UDim2.new(0, 115, 0, 115)
		cardBtn.BackgroundColor3 = UI_COLORS.TAB_INACTIVE
		cardBtn.Text = ""
		cardBtn.Active = true
		cardBtn.AutoButtonColor = true
		Instance.new("UICorner", cardBtn).CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke", cardBtn)
		stroke.Thickness = 1
		stroke.Color = UI_COLORS.TAB_ACTIVE
		stroke.Transparency = 0.6

		local icon = Instance.new("ImageLabel", cardBtn)
		icon.Size = UDim2.new(0.75, 0, 0.75, 0)
		icon.Position = UDim2.new(0.125, 0, 0.08, 0)
		icon.BackgroundTransparency = 1
		icon.Image = getIcon(unit)
		icon.Active = false
		icon.Selectable = false

		cardBtn.MouseButton1Click:Connect(function()
			executeDuplication(unit)
		end)
	end
end

btnMain.MouseButton1Click:Connect(function() setActiveTab(btnMain, mainPage) end)
btnInfo.MouseButton1Click:Connect(function() 
	setActiveTab(btnInfo, infoPage) 
	updateInfo(currentTarget)
	refreshPlayerList()
end)
btnInv.MouseButton1Click:Connect(function() 
	setActiveTab(btnInv, invPage) 
	setupDupePage(invPage, false) 
end)
btnTrade.MouseButton1Click:Connect(function() 
	setActiveTab(btnTrade, tradePage) 
	setupDupePage(tradePage, true) 
end)
btnConfig.MouseButton1Click:Connect(function() setActiveTab(btnConfig, configPage) end)

-- ЗАПУСК АНИМАЦИИ ИНТРО
task.spawn(function()
	local introInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(welcomeFrame, introInfo, {BackgroundTransparency = 0.05}):Play()
	TweenService:Create(welcomeStroke, introInfo, {Transparency = 0.2}):Play()
	TweenService:Create(welcomeText, introInfo, {TextTransparency = 0}):Play()
	
	task.wait(1.5)
	
	local outroInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(welcomeFrame, outroInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(welcomeStroke, outroInfo, {Transparency = 1}):Play()
	TweenService:Create(welcomeText, outroInfo, {TextTransparency = 1}):Play()
	
	task.wait(0.4)
	welcomeFrame:Destroy()
	
	main.Visible = true
	startParticles()
	
	TweenService:Create(main, introInfo, {BackgroundTransparency = 0.03}):Play()
	TweenService:Create(mainStroke, introInfo, {Transparency = 0.3}):Play()
end)
