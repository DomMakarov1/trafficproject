local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local Plot = require(script.Parent.PlotBuilder)

local store = DataStoreService:GetDataStore(Config.DataStoreName)

local toastRemote = Instance.new("RemoteEvent")
toastRemote.Name = "Toast"
toastRemote.Parent = ReplicatedStorage

local states: { [Player]: any } = {}
local plots: { [Player]: any } = {}
local usedSlots: { [number]: boolean } = {}
local slotOf: { [Player]: number } = {}

-- Returns (loadedOk, data). data is nil for brand-new players.
local function load(player: Player): (boolean, any)
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if ok then
			return true, result
		end
		warn("Load failed", player.Name, result)
		task.wait(attempt)
	end
	return false, nil
end

local function save(player: Player)
	local state = states[player]
	if not state or state.noSave then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync("p_" .. player.UserId, state:serialize())
	end)
	if not ok then
		warn("Save failed", player.Name, err)
	end
end

local function checkPasses(player: Player, state)
	for key, id in Config.Passes do
		if id > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if ok and owns then
				state.passes[key] = true
			end
		end
	end
end

local function onJoin(player: Player)
	local loaded, data = load(player)
	local state = PlayerState.new(player, data)
	-- If loading failed entirely, never overwrite a possibly-good save later.
	-- (Also the case in Studio with API access off: progress just won't persist.)
	state.noSave = not loaded
	state.notify = function(text)
		toastRemote:FireClient(player, text)
	end
	states[player] = state

	checkPasses(player, state)
	state:onJoin()

	local slot = 0
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = true
	slotOf[player] = slot

	local plot = Plot.new(player, state, slot)
	plots[player] = plot

	local function placeCharacter(char: Model)
		local root = char:WaitForChild("HumanoidRootPart", 5)
		if root then
			char:PivotTo(plot.spawnCFrame)
		end
	end
	player.CharacterAdded:Connect(placeCharacter)
	if player.Character then
		placeCharacter(player.Character)
	else
		player:LoadCharacter()
	end

	state:publish()
end

local function onLeave(player: Player)
	save(player)
	if plots[player] then
		plots[player]:destroy()
		plots[player] = nil
	end
	if slotOf[player] then
		usedSlots[slotOf[player]] = nil
		slotOf[player] = nil
	end
	states[player] = nil
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end
	local state = states[player]
	if not state then
		return
	end
	for key, id in Config.Passes do
		if id == passId then
			state.passes[key] = true
			state.dirty = true
		end
	end
end)

Players.PlayerAdded:Connect(onJoin)
Players.PlayerRemoving:Connect(onLeave)
for _, p in Players:GetPlayers() do
	task.spawn(onJoin, p)
end

-- Game loop: simulate, publish HUD values, refresh world when something changed.
local publishTimer, saveTimer = 0, 0
RunService.Heartbeat:Connect(function(dt)
	publishTimer += dt
	saveTimer += dt
	for player, state in states do
		state:tick(dt)
	end
	if publishTimer >= 0.2 then
		publishTimer = 0
		for player, state in states do
			state:publish()
			if state.dirty and plots[player] then
				state.dirty = false
				plots[player]:refresh()
			end
		end
	end
	if saveTimer >= 60 then
		saveTimer = 0
		for player in states do
			task.spawn(save, player)
		end
	end
end)

game:BindToClose(function()
	for player in states do
		save(player)
	end
end)
