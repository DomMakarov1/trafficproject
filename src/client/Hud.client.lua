local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TerraformHud"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function panel(name: string, pos: UDim2, color: Color3)
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = pos
	f.Size = UDim2.fromOffset(240, 46)
	f.BackgroundColor3 = Color3.fromRGB(30, 34, 40)
	f.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Parent = f
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 22
	l.Parent = f
	f.Parent = gui
	return l
end

local seedsLabel = panel("Seeds", UDim2.new(0, 16, 1, -126), Color3.fromRGB(110, 220, 110))
local petalsLabel = panel("Petals", UDim2.new(0, 16, 1, -70), Color3.fromRGB(190, 90, 150))
local sub = Instance.new("TextLabel")
sub.Position = UDim2.new(0, 16, 1, -148)
sub.Size = UDim2.fromOffset(240, 20)
sub.BackgroundTransparency = 1
sub.TextColor3 = Color3.fromRGB(200, 220, 200)
sub.Font = Enum.Font.Gotham
sub.TextSize = 16
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = gui

local function update()
	local seeds = player:GetAttribute("Seeds") or 0
	local petals = player:GetAttribute("Petals") or 0
	local perSec = player:GetAttribute("PerSec") or 0
	local click = player:GetAttribute("ClickValue") or 1
	seedsLabel.Text = ("%s Seeds"):format(Format.number(seeds))
	petalsLabel.Text = ("%s Petals"):format(Format.number(petals))
	petalsLabel.Parent.Visible = (player:GetAttribute("Blooms") or 0) > 0 or petals > 0
	sub.Text = ("+%s/sec  |  +%s/click"):format(Format.number(perSec), Format.number(click))
end

for _, attr in { "Seeds", "Petals", "PerSec", "ClickValue", "Blooms" } do
	player:GetAttributeChangedSignal(attr):Connect(update)
end
update()

-- Toasts (mystery reveals, Bloom, offline earnings)
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, -80)
toast.Size = UDim2.fromOffset(520, 56)
toast.BackgroundColor3 = Color3.fromRGB(30, 34, 40)
toast.TextColor3 = Color3.new(1, 1, 1)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 20
toast.TextWrapped = true
toast.Parent = gui
local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(0, 10)
tc.Parent = toast

local queue, busy = {}, false
local function pump()
	if busy then
		return
	end
	busy = true
	while #queue > 0 do
		toast.Text = table.remove(queue, 1)
		TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, 20) }):Play()
		task.wait(3.5)
		TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -80) }):Play()
		task.wait(0.35)
	end
	busy = false
end

ReplicatedStorage:WaitForChild("Toast").OnClientEvent:Connect(function(text: string)
	table.insert(queue, text)
	task.spawn(pump)
end)
