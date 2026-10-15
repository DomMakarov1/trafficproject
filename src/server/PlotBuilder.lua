--[[
	Builds a player's garden entirely from code: baseplate, clickable Sprout,
	upgrade pads with SurfaceGui labels, connecting lines, and world decorations
	that grow in as nodes are bought.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Nodes = require(ReplicatedStorage.Shared.Nodes)
local Format = require(ReplicatedStorage.Shared.Format)
local Config = require(ReplicatedStorage.Shared.Config)

local PAD_SIZE = Vector3.new(20, 1.5, 12)
local MAX_DECOR = 14

local COLORS = {
	available = Color3.fromRGB(70, 120, 80),
	locked = Color3.fromRGB(60, 60, 66),
	hidden = Color3.fromRGB(80, 50, 110),
	maxed = Color3.fromRGB(200, 170, 60),
	petal = Color3.fromRGB(190, 90, 150),
}

local Plot = {}
Plot.__index = Plot

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeLabel(parent: Instance, name: string, y: number, h: number, size: number, bold: boolean?)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromScale(0.04, y)
	l.Size = UDim2.fromScale(0.92, h)
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextWrapped = true
	l.Text = ""
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = size
	c.Parent = l
	l.Parent = parent
	return l
end

local function makePadGui(pad: Part)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = pad
	local title = makeLabel(gui, "Title", 0.04, 0.22, 56, true)
	local desc = makeLabel(gui, "Desc", 0.28, 0.4, 44, false)
	local footer = makeLabel(gui, "Footer", 0.72, 0.24, 48, true)
	return title, desc, footer
end

local function growIn(p: Part, finalSize: Vector3)
	p.Size = finalSize * 0.05
	TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Size = finalSize }):Play()
end

local function buildDecor(folder: Folder, kind: string, pos: Vector3)
	local rng = Random.new()
	if kind == "grass" then
		local p = makePart(folder, "Grass", Vector3.new(1, 3, 1), CFrame.new(pos + Vector3.new(0, 1.5, 0)), Color3.fromRGB(80, 180, 70))
		growIn(p, Vector3.new(1, rng:NextNumber(2, 4), 1))
	elseif kind == "flower" then
		local stem = makePart(folder, "Stem", Vector3.new(0.4, 3, 0.4), CFrame.new(pos + Vector3.new(0, 1.5, 0)), Color3.fromRGB(50, 140, 60))
		local head = makePart(folder, "Bloom", Vector3.new(1.8, 1.8, 1.8), CFrame.new(pos + Vector3.new(0, 3.2, 0)), Color3.fromHSV(rng:NextNumber(), 0.6, 1), Enum.Material.Neon)
		head.Shape = Enum.PartType.Ball
		growIn(stem, stem.Size)
		growIn(head, head.Size)
	elseif kind == "tree" then
		local trunk = makePart(folder, "Trunk", Vector3.new(2, 8, 2), CFrame.new(pos + Vector3.new(0, 4, 0)), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
		local leaves = makePart(folder, "Leaves", Vector3.new(9, 9, 9), CFrame.new(pos + Vector3.new(0, 10, 0)), Color3.fromRGB(60, 160, 70), Enum.Material.Grass)
		leaves.Shape = Enum.PartType.Ball
		growIn(trunk, trunk.Size)
		growIn(leaves, leaves.Size)
	elseif kind == "pond" then
		local water = makePart(folder, "Pond", Vector3.new(0.4, 12, 12), CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(60, 140, 230), Enum.Material.Glass)
		water.Shape = Enum.PartType.Cylinder
		growIn(water, water.Size)
	end
end

function Plot.new(player: Player, state, index: number)
	local self = setmetatable({}, Plot)
	self.player = player
	self.state = state
	self.origin = Vector3.new(index * Config.PlotSpacing, 0, 0)
	self.pads = {}
	self.lines = {}
	self.decorBuilt = {}

	local model = Instance.new("Model")
	model.Name = player.Name .. "'s Garden"
	self.model = model

	local o = self.origin
	makePart(model, "Ground", Vector3.new(240, 2, 220), CFrame.new(o + Vector3.new(0, -1, -45)), Color3.fromRGB(95, 70, 50), Enum.Material.Ground)
	makePart(model, "Lawn", Vector3.new(236, 0.2, 216), CFrame.new(o + Vector3.new(0, 0.1, -45)), Color3.fromRGB(70, 140, 70), Enum.Material.Grass)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.CFrame = CFrame.new(o + Vector3.new(0, 0.4, 28))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Enabled = false
	spawn.Parent = model
	self.spawnCFrame = CFrame.new(o + Vector3.new(0, 4, 28))

	-- The clickable Sprout
	local sprout = makePart(model, "Sprout", Vector3.new(7, 7, 7), CFrame.new(o + Vector3.new(0, 4, 0)), Color3.fromRGB(110, 220, 110), Enum.Material.Neon)
	sprout.Shape = Enum.PartType.Ball
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 60
	cd.Parent = sprout
	cd.MouseClick:Connect(function(who)
		if who ~= player then
			return
		end
		if state:click() then
			TweenService:Create(sprout, TweenInfo.new(0.06), { Size = Vector3.new(6, 6, 6) }):Play()
			task.delay(0.06, function()
				TweenService:Create(sprout, TweenInfo.new(0.1), { Size = Vector3.new(7, 7, 7) }):Play()
			end)
		end
	end)
	self.sprout = sprout

	-- Connection lines first so pads draw over them
	for _, node in Nodes.List do
		for _, req in node.requires do
			local a, b = Nodes.ById[req.id], node
			local pa = o + Vector3.new(a.pos.X, 0.3, a.pos.Y)
			local pb = o + Vector3.new(b.pos.X, 0.3, b.pos.Y)
			local dist = (pb - pa).Magnitude
			local line = makePart(model, "Line_" .. a.id .. "_" .. b.id, Vector3.new(1.6, 0.2, dist), CFrame.lookAt((pa + pb) / 2, pb), COLORS.locked, Enum.Material.Neon)
			table.insert(self.lines, { part = line, node = node, req = req })
		end
	end

	-- Upgrade pads
	for _, node in Nodes.List do
		local pad = makePart(model, "Pad_" .. node.id, PAD_SIZE, CFrame.new(o + Vector3.new(node.pos.X, 0.75, node.pos.Y)), COLORS.locked)
		local title, desc, footer = makePadGui(pad)
		local pcd = Instance.new("ClickDetector")
		pcd.MaxActivationDistance = 40
		pcd.Parent = pad
		pcd.MouseClick:Connect(function(who)
			if who == player then
				state:buy(node.id)
			end
		end)
		self.pads[node.id] = { part = pad, title = title, desc = desc, footer = footer, node = node }
	end

	-- Bloom (prestige) pad
	local bloom = makePart(model, "BloomPad", Vector3.new(26, 1.5, 14), CFrame.new(o + Vector3.new(Nodes.BloomPos.X, 0.75, Nodes.BloomPos.Y)), COLORS.petal, Enum.Material.Neon)
	local bt, bd, bf = makePadGui(bloom)
	local bcd = Instance.new("ClickDetector")
	bcd.MaxActivationDistance = 40
	bcd.Parent = bloom
	bcd.MouseClick:Connect(function(who)
		if who == player then
			state:bloom()
		end
	end)
	self.bloom = { part = bloom, title = bt, desc = bd, footer = bf }

	-- Game pass pads (hidden until real pass IDs are configured)
	self.passPads = {}
	local passDefs = {
		{ key = "DoubleSeeds", label = "2x Seeds", offset = -40, desc = "Permanently double all seeds" },
		{ key = "AutoBuy", label = "Auto-Buy", offset = 40, desc = "Automatically buys the cheapest upgrade" },
	}
	for _, def in passDefs do
		local id = Config.Passes[def.key]
		if id and id > 0 then
			local pp = makePart(model, "Pass_" .. def.key, Vector3.new(20, 1.5, 12), CFrame.new(o + Vector3.new(def.offset, 0.75, 44)), Color3.fromRGB(230, 170, 40), Enum.Material.Neon)
			local t, d, f = makePadGui(pp)
			t.Text, d.Text, f.Text = def.label, def.desc, "Click to buy"
			local ccd = Instance.new("ClickDetector")
			ccd.MaxActivationDistance = 40
			ccd.Parent = pp
			ccd.MouseClick:Connect(function(who)
				if who == player and not state.passes[def.key] then
					MarketplaceService:PromptGamePassPurchase(player, id)
				end
			end)
			self.passPads[def.key] = pp
		end
	end

	self.decorFolder = Instance.new("Folder")
	self.decorFolder.Name = "Decor"
	self.decorFolder.Parent = model

	model.Parent = workspace
	self:refresh()
	return self
end

function Plot:refresh()
	local state = self.state
	for _, entry in self.pads do
		local node = entry.node
		local status = state:status(node)
		local lv, max = state:level(node.id), state:maxLevel(node)
		local part = entry.part
		if status == "hidden" then
			part.Color = COLORS.hidden
			entry.title.Text = "???"
			entry.desc.Text = node.mystery.hint
			entry.footer.Text = "Hidden"
		elseif status == "locked" then
			part.Color = COLORS.locked
			entry.title.Text = "Locked"
			if node.needBlooms > 0 and state.blooms < node.needBlooms then
				entry.desc.Text = "Perform a Bloom to unlock"
			else
				local parts = {}
				for _, req in node.requires do
					if state:level(req.id) < req.level then
						table.insert(parts, ("%s Lv.%d"):format(Nodes.ById[req.id].name, req.level))
					end
				end
				entry.desc.Text = "Needs " .. table.concat(parts, ", ")
			end
			entry.footer.Text = ""
		else
			part.Color = status == "maxed" and COLORS.maxed or COLORS.available
			if node.currency == "Petals" and status ~= "maxed" then
				part.Color = COLORS.petal
			end
			entry.title.Text = ("%s (%d/%d)"):format(node.name, lv, max)
			entry.desc.Text = node.desc
			if status == "maxed" then
				entry.footer.Text = "MAXED"
			else
				entry.footer.Text = ("%s %s"):format(Format.number(state:cost(node)), node.currency)
				entry.footer.TextColor3 = state:balance(node.currency) >= state:cost(node) and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150)
			end
		end

		-- World decorations: one per level owned
		local d = node.decor
		if d then
			local built = self.decorBuilt[node.id] or 0
			local want = math.min(lv, MAX_DECOR)
			while built < want do
				built += 1
				local rng = Random.new(#node.id * 1000 + built)
				local offset = Vector3.new(rng:NextNumber(-d.spread, d.spread), 0, rng:NextNumber(-d.spread, d.spread))
				buildDecor(self.decorFolder, d.kind, self.origin + d.at + offset)
			end
			if lv == 0 and built > 0 then
				self.decorFolder:ClearAllChildren()
				table.clear(self.decorBuilt)
				built = 0
			end
			self.decorBuilt[node.id] = built
		end
	end

	for _, l in self.lines do
		local met = state:level(l.req.id) >= l.req.level
		l.part.Color = met and Color3.fromRGB(110, 220, 110) or COLORS.locked
	end

	local gain = state:bloomPetals()
	self.bloom.title.Text = "BLOOM"
	if gain >= 1 then
		self.bloom.desc.Text = ("Reset seeds & upgrades for %d petals. Petals are permanent (+%d%% seeds each)."):format(gain, Config.PetalSeedBonus * 100)
		self.bloom.footer.Text = "Click to Bloom"
	else
		self.bloom.desc.Text = ("Earn %s seeds this run to Bloom (%s so far)."):format(Format.number(Config.BloomMinRunSeeds), Format.number(state.runSeeds))
		self.bloom.footer.Text = "Not ready"
	end
end

function Plot:destroy()
	self.model:Destroy()
end

return Plot
