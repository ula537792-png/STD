local function getUnitKey(unit)
	if not unit then return nil end
	local id = unit:GetAttribute("ID")
	if id ~= nil then
		return "ID_" .. tostring(id)
	end
	return unit.Name .. "_" .. tostring(unit:GetDebugId())
end
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local activeButton = nil

local function setActive(btn)
	if activeButton then
		activeButton.BackgroundColor3 = Color3.fromRGB(25,25,35)
	end

	activeButton = btn
	btn.BackgroundColor3 = Color3.fromRGB(70, 20, 120)
end

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")
local spinEnabled = false
local spinSpeed = 10
local infiniteJump = false
local uiOpened = true

player.CharacterAdded:Connect(function(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	root = c:WaitForChild("HumanoidRootPart")
end)

local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("InveriumHub")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "InveriumHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999

gui.Parent = playerGui


local main = Instance.new("Frame")
main.ClipsDescendants = true
main.Size = UDim2.new(0, 950, 0, 580)
main.Position = UDim2.new(0.5, -475, 0.5, -290)
main.ClipsDescendants = true
main.BackgroundColor3 = Color3.fromRGB(12,12,16)
main.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(160,0,255)
stroke.Thickness = 2
stroke.Transparency = 0.3
stroke.Parent = main
local TweenService = game:GetService("TweenService")

local uiOpened = true
local animating = false

local expandedSize = UDim2.new(0, 950, 0, 580)
local collapsedSize = UDim2.new(0, 950, 0, 80)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 34, 0, 34)
toggleBtn.Position = UDim2.new(1, -44, 0, 12)
toggleBtn.BackgroundColor3 = Color3.fromRGB(25,25,35)
toggleBtn.Text = "▲"
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 18
toggleBtn.Parent = main

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local function toggleUI()
	if animating then return end
	animating = true

	local goal = uiOpened and collapsedSize or expandedSize

	local tween = TweenService:Create(
		main,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = goal}
	)

	tween:Play()

	tween.Completed:Connect(function()
		uiOpened = not uiOpened
		animating = false
		toggleBtn.Text = uiOpened and "▲" or "▼"
	end)
end

toggleBtn.MouseButton1Click:Connect(toggleUI)
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 200, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(18,18,25)
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,16)

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(1,0,0,80)
logo.BackgroundTransparency = 1
logo.Text = "INVERIUM"
logo.Font = Enum.Font.GothamBlack
logo.TextSize = 22
logo.TextColor3 = Color3.fromRGB(200,120,255)
logo.Parent = sidebar

local function tab(name, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-24,0,44)
	b.Position = UDim2.new(0,12,0,y)
	b.BackgroundColor3 = Color3.fromRGB(25,25,35)
	b.Text = name
	b.TextColor3 = Color3.fromRGB(240,240,240)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 14
	b.Parent = sidebar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
	return b
end

local btnMain = tab("Player", 110)
local btnInfo = tab("Player Info", 165)
local btnInv = tab(" Dupe", 220)
local btnTrade = tab("Trade scam", 275)
local pages = Instance.new("Frame")
pages.Size = UDim2.new(1,-220,1,-80)
pages.Position = UDim2.new(0,210,0,70)
pages.BackgroundTransparency = 1
pages.Parent = main

local mainPage = Instance.new("Frame")
mainPage.Size = UDim2.new(1,0,1,0)
mainPage.BackgroundColor3 = Color3.fromRGB(18,18,24)
mainPage.Parent = pages
Instance.new("UICorner", mainPage).CornerRadius = UDim.new(0,12)

local infoPage = Instance.new("Frame")
infoPage.Size = UDim2.new(1,0,1,0)
infoPage.BackgroundTransparency = 1
infoPage.Visible = false
infoPage.Parent = pages

local invPage = Instance.new("ScrollingFrame")
invPage.Size = UDim2.new(1,0,1,0)
invPage.BackgroundTransparency = 1
invPage.ScrollBarThickness = 6
invPage.Visible = false
invPage.Parent = pages

local tradePage = Instance.new("ScrollingFrame")
tradePage.Size = UDim2.new(1,0,1,0)
tradePage.BackgroundTransparency = 1
tradePage.ScrollBarThickness = 6
tradePage.Visible = false
tradePage.Parent = pages
RunService.RenderStepped:Connect(function()
	if spinEnabled and root then
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if infiniteJump and hum then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
local dragging, start, startPos

main.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		start = i.Position
		startPos = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(i)
	if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = i.Position - start
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

UserInputService.InputEnded:Connect(function()
	dragging = false
end)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	root = c:WaitForChild("HumanoidRootPart")
end)
local mainPage = Instance.new("ScrollingFrame")
mainPage.Size = UDim2.new(1,-20,1,-20)
mainPage.Position = UDim2.new(0,10,0,10)
mainPage.BackgroundTransparency = 1
mainPage.ScrollBarThickness = 6
mainPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
mainPage.Parent = pages or gui

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.48,0,0,42)
grid.CellPadding = UDim2.new(0,10,0,10)
grid.Parent = mainPage
local spin, fly, noclip = false, false, false
local speed = 16
local jump = 50
local sit = false
local ragdoll = false
local bigHead = false
local tiny = false
local invert = false
local autoJump = false
local autoWalk = false
local fakeSit = false
local slowMotion = false
local fastWalk = false
local freeze = false
local tpRandom = false
local fakeChat = false
local antiGravity = false
local platform = false
local forceJump = false
local crawl = false
local spinSpeed = 15
local function btn(text, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,42)
	b.BackgroundColor3 = Color3.fromRGB(25,25,35)
	b.Text = text
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 13
	b.Parent = mainPage

	Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)

	b.MouseButton1Click:Connect(cb)
end
RunService.RenderStepped:Connect(function()
	if spin and root then
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
	end

	if freeze and root then
		root.Anchored = true
	else
		root.Anchored = false
	end

	if slowMotion then
		game:GetService("Workspace").Gravity = 50
	else
		game:GetService("Workspace").Gravity = 196.2
	end

	if fastWalk then
		hum.WalkSpeed = 40
	else
		hum.WalkSpeed = speed
	end

	hum.JumpPower = jump
end)
local flyBV
UserInputService.InputBegan:Connect(function(input)
	if fly and input.KeyCode == Enum.KeyCode.Space then
		if flyBV then flyBV.Velocity += Vector3.new(0,60,0) end
	end
end)

local function updateFly()
	if fly then
		if not flyBV then
			flyBV = Instance.new("BodyVelocity")
			flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
			flyBV.Parent = root
		end
		flyBV.Velocity = workspace.CurrentCamera.CFrame.LookVector * 60
	else
		if flyBV then flyBV:Destroy() flyBV=nil end
	end
end

RunService.RenderStepped:Connect(updateFly)
RunService.Stepped:Connect(function()
	if noclip and char then
		for _,v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end
end)
btn("🌀 Spin", function() spin = not spin end)
btn("⚙ Spin +5", function() spinSpeed += 5 end)

btn("⚡ Speed +5", function() speed += 5 end)
btn("🐢 Reset Speed", function() speed = 16 end)

btn("🦘 Jump +10", function() jump += 10 end)

btn("🪽 Fly", function() fly = not fly end)
btn("🧱 Noclip", function() noclip = not noclip end)

-- troll harmless
btn("🪑 Sit Toggle", function()
	sit = not sit
	if sit then hum.Sit = true else hum.Sit = false end
end)

btn("🤸 Fake Sit (visual)", function()
	fakeSit = not fakeSit
	hum.Sit = fakeSit
end)

btn("📦 Tiny Mode", function()
	tiny = not tiny
	for _,v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Size = tiny and v.Size * 0.5 or v.Size * 2
		end
	end
end)

btn("🧠 Invert Controls", function()
	invert = not invert
end)

btn("🏃 Auto Walk", function()
	autoWalk = not autoWalk
end)

btn("🦘 Auto Jump", function()
	autoJump = not autoJump
end)

btn("❄ Freeze", function()
	freeze = not freeze
end)

btn("🧱 Platform Mode", function()
	platform = not platform
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new(6,1,6)
	p.Parent = workspace
	p.Position = root.Position - Vector3.new(0,3,0)
end)

btn("🌍 Random TP", function()
	if root then
		root.CFrame = root.CFrame * CFrame.new(math.random(-50,50),0,math.random(-50,50))
	end
end)

btn("💬 Fake Chat (local)", function()
	fakeChat = not fakeChat
end)

btn("⚖ Anti Gravity", function()
	antiGravity = not antiGravity
	workspace.Gravity = antiGravity and -50 or 196.2
end)

btn("🏃 Fast Walk", function()
	fastWalk = not fastWalk
end)

btn("🐌 Slow Motion", function()
	slowMotion = not slowMotion
end)

btn("🦴 Ragdoll (fake)", function()
	ragdoll = not ragdoll
	hum.PlatformStand = ragdoll
end)

btn("🎯 Force Jump", function()
	forceJump = not forceJump
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

btn("🐍 Crawl Mode", function()
	crawl = not crawl
	hum.HipHeight = crawl and -1 or 0
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local currentTarget = player
local infoRoot = Instance.new("Frame")
infoRoot.Size = UDim2.new(1,0,1,0)
infoRoot.BackgroundTransparency = 1
infoRoot.Parent = infoPage
local center = Instance.new("Frame")
center.Size = UDim2.new(0, 650, 0, 360)
center.Position = UDim2.new(0.5, -325, 0.5, -180)
center.BackgroundColor3 = Color3.fromRGB(18,18,28)
center.Parent = infoRoot
Instance.new("UICorner", center).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(170,0,255)
stroke.Transparency = 0.3
stroke.Parent = center
local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 120, 0, 120)
avatar.Position = UDim2.new(0, 20, 0.5, -60)
avatar.BackgroundTransparency = 1
avatar.Parent = center
Instance.new("UICorner", avatar).CornerRadius = UDim.new(1,0)
local right = Instance.new("ScrollingFrame")
right.Size = UDim2.new(1, -160, 1, -90)
right.Position = UDim2.new(0, 150, 0, 10)
right.BackgroundTransparency = 1
right.ScrollBarThickness = 6
right.AutomaticCanvasSize = Enum.AutomaticSize.Y
right.Parent = center

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.Parent = right

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	right.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 20)
end)
local function field()
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,0,26)
	f.BackgroundColor3 = Color3.fromRGB(25,25,38)
	f.Parent = right
	Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)

	local s = Instance.new("UIStroke")
	s.Thickness = 1
	s.Color = Color3.fromRGB(160,0,255)
	s.Transparency = 0.6
	s.Parent = f

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1,-8,1,0)
	t.Position = UDim2.new(0,4,0,0)
	t.BackgroundTransparency = 1
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Font = Enum.Font.GothamSemibold
	t.TextSize = 12
	t.TextColor3 = Color3.fromRGB(255,255,255)
	t.Parent = f

	return t
end
local nameT = field()
local displayT = field()
local idT = field()
local ageT = field()

local speedT = field()
local jumpT = field()
local healthT = field()

local fpsT = field()
local pingT = field()
local playersT = field()

local stateT = field()
local moveT = field()
local partsT = field()

local fps = 0
local last = tick()

RunService.RenderStepped:Connect(function()
	fps += 1
	if tick() - last >= 1 then
		fpsT.Text = "📊 FPS: " .. fps
		fps = 0
		last = tick()
	end
end)


local function getPing()
	local ok, res = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	return ok and math.floor(res) or 0
end

local function update(plr)
	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid")

	nameT.Text = "👤 " .. plr.Name
	displayT.Text = "🧠 " .. plr.DisplayName
	idT.Text = "🆔 " .. plr.UserId
	ageT.Text = "📅 Account Age: " .. plr.AccountAge

	speedT.Text = "⚡ WalkSpeed: " .. (hum and hum.WalkSpeed or 0)
	jumpT.Text = "🦘 JumpPower: " .. (hum and hum.JumpPower or 0)
	healthT.Text = "❤️ Health: " .. (hum and math.floor(hum.Health) or 0)

	pingT.Text = "📶 Ping: " .. getPing() .. "ms"
	playersT.Text = "👥 Players: " .. #Players:GetPlayers()

	if hum then
		stateT.Text = "🎮 State: " .. hum:GetState().Name
	else
		stateT.Text = "🎮 State: Unknown"
	end

	moveT.Text = "🏃 MoveDirection: " .. tostring(hum and hum.MoveDirection or Vector3.zero)

	local parts = 0
	if char then
		for _, v in ipairs(char:GetChildren()) do
			if v:IsA("BasePart") then
				parts += 1
			end
		end
	end
	partsT.Text = "🧩 Character Parts: " .. parts

	avatar.Image = Players:GetUserThumbnailAsync(
		plr.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size420x420
	)
end

update(player)
task.spawn(function()
	while true do
		task.wait(1)
		if currentTarget then
			update(currentTarget)
		end
	end
end)
local search = Instance.new("TextBox")
search.Size = UDim2.new(0, 320, 0, 32)
search.Position = UDim2.new(0.5, -160, 1, -45)
search.PlaceholderText = "Search player..."
search.Text = ""
search.BackgroundColor3 = Color3.fromRGB(25,25,35)
search.TextColor3 = Color3.fromRGB(255,255,255)
search.Parent = center
Instance.new("UICorner", search).CornerRadius = UDim.new(0,10)

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 110, 0, 32)
btn.Position = UDim2.new(0.5, 170, 1, -45)
btn.Text = "Search"
btn.BackgroundColor3 = Color3.fromRGB(150,0,255)
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.Parent = center
Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

btn.MouseButton1Click:Connect(function()
	local target = Players:FindFirstChild(search.Text)
	if target then
		currentTarget = target
		update(target)
	end
end)
local inventoryUnique = {}
local tradeUnique = {}

local function scanInventory()
	inventoryUnique = {}

	local seen = {}

	local inv = playerGui:FindFirstChild("Inventory")
	if not inv then return end

	local units = inv:FindFirstChild("Inventory")
	if not units then return end

	local folder = units:FindFirstChild("Units")
	if not folder then return end

	for _, unit in ipairs(folder:GetChildren()) do
		if unit then
			local key = getUnitKey(unit)

			if key and not seen[key] then
				seen[key] = true
				table.insert(inventoryUnique, unit)
			end
		end
	end
end
local function scanTrade()
	tradeUnique = {}

	local seen = {}

	local trading = playerGui:FindFirstChild("Trading")
	if not trading then return end

	local screen = trading:FindFirstChild("Trading")
	if not screen then return end

	local ui = screen:FindFirstChild("TradingScreen")
	if not ui then return end

	local playerScreen = ui:FindFirstChild("PlayerScreen")
	if not playerScreen then return end

	local inv = playerScreen:FindFirstChild("PlayerInv")
	if not inv then return end

	for _, unit in ipairs(inv:GetChildren()) do
		if unit then
			local key = getUnitKey(unit)

			if key and not seen[key] then
				seen[key] = true
				table.insert(tradeUnique, unit)
			end
		end
	end
end
local function getIcon(unit)
	local ti = unit:FindFirstChild("TowerImage", true)
	if ti and ti:IsA("ImageLabel") then
		return ti.Image
	end
	return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end
btn.MouseEnter:Connect(function()
	btn.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
	stroke.Transparency = 0.1
end)

btn.MouseLeave:Connect(function()
	btn.BackgroundColor3 = Color3.fromRGB(25,25,35)
	stroke.Transparency = 0.35
end)

local function createCard(parent, unit, isTrade)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,140,0,140)
	btn.BackgroundColor3 = Color3.fromRGB(25,25,35)
	btn.Text = ""
	btn.Parent = parent

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,14)

	local stroke = Instance.new("UIStroke")
	stroke.Parent = btn
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(170, 0, 255)
	stroke.Transparency = 0.35
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.8,0,0.8,0)
	icon.Position = UDim2.new(0.1,0,0.05,0)
	icon.BackgroundTransparency = 1
	icon.Image = getIcon(unit)
	icon.Parent = btn

	btn.MouseButton1Click:Connect(function()
		local clone = unit:Clone()
		clone.Name = unit.Name .. "_clone_" .. tostring(tick())

		if isTrade then
			local check = clone:FindFirstChild("Checkmark", true)
			if check and check:IsA("ImageLabel") then
				check.Visible = true
			end
		end

		clone.Parent = unit.Parent
	end)
end

local function buildInventory()
	for _, v in ipairs(invPage:GetChildren()) do
		if not v:IsA("UIGridLayout") then
			v:Destroy()
		end
	end

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0,140,0,140)
	grid.Parent = invPage

	scanInventory()

	for _, unit in ipairs(inventoryUnique) do
		createCard(invPage, unit, false)
	end
end


local function buildTrade()
	for _, v in ipairs(tradePage:GetChildren()) do
		if not v:IsA("UIGridLayout") then
			v:Destroy()
		end
	end

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0,140,0,140)
	grid.Parent = tradePage

	scanTrade()

	for _, unit in ipairs(tradeUnique) do
		createCard(tradePage, unit, true)
	end
end
local activeButton = nil

local function setActive(btn)
	if activeButton then
		activeButton.BackgroundColor3 = Color3.fromRGB(25,25,35)
	end

	activeButton = btn
	btn.BackgroundColor3 = Color3.fromRGB(70, 20, 120)
end

btnMain.MouseButton1Click:Connect(function()
	setActive(btnMain)

	mainPage.Visible = true
	infoPage.Visible = false
	invPage.Visible = false
	tradePage.Visible = false
end)

btnInfo.MouseButton1Click:Connect(function()
	setActive(btnInfo)

	mainPage.Visible = false
	infoPage.Visible = true
	invPage.Visible = false
	tradePage.Visible = false
	updateInfo()
end)

btnInv.MouseButton1Click:Connect(function()
	setActive(btnInv)

	mainPage.Visible = false
	infoPage.Visible = false
	tradePage.Visible = false
	invPage.Visible = true
	buildInventory()
end)

btnTrade.MouseButton1Click:Connect(function()
	setActive(btnTrade)

	mainPage.Visible = false
	infoPage.Visible = false
	invPage.Visible = false
	tradePage.Visible = true
	buildTrade()
end)
