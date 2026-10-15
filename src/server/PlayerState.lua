local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Nodes = require(ReplicatedStorage.Shared.Nodes)
local Config = require(ReplicatedStorage.Shared.Config)

local PlayerState = {}
PlayerState.__index = PlayerState

function PlayerState.new(player: Player, saved: { [string]: any }?)
	saved = saved or {}
	local self = setmetatable({
		player = player,
		seeds = saved.seeds or 0,
		petals = saved.petals or 0,
		runSeeds = saved.runSeeds or 0,
		totalSeeds = saved.totalSeeds or 0,
		blooms = saved.blooms or 0,
		clicks = saved.clicks or 0,
		streak = saved.streak or 0,
		lastDay = saved.lastDay or 0,
		lastSeen = saved.lastSeen or os.time(),
		levels = saved.levels or {},
		revealed = saved.revealed or {},
		passes = { DoubleSeeds = false, AutoBuy = false },
		lastClick = os.clock(),
		clickWindowStart = os.clock(),
		clickWindowCount = 0,
		autoClickBank = 0,
		autoBuyTimer = 0,
		dirty = true,
		notify = function(_text: string) end,
	}, PlayerState)
	return self
end

function PlayerState:level(id: string): number
	return self.levels[id] or 0
end

function PlayerState:maxLevel(node): number
	local m = node.maxLevel
	for _, other in Nodes.List do
		local e = other.effect
		if e and e.type == "maxLevel" and e.target == node.id then
			m += e.value * self:level(other.id)
		end
	end
	return m
end

function PlayerState:cost(node): number
	return math.floor(node.cost * node.growth ^ self:level(node.id))
end

function PlayerState:balance(currency: string): number
	return currency == "Petals" and self.petals or self.seeds
end

-- "hidden" (mystery not found), "locked" (requirements unmet), "maxed", "available"
function PlayerState:status(node): string
	if self.blooms < node.needBlooms then
		return "locked"
	end
	for _, req in node.requires do
		if self:level(req.id) < req.level then
			return "locked"
		end
	end
	if node.mystery and not self.revealed[node.id] then
		return "hidden"
	end
	if self:level(node.id) >= self:maxLevel(node) then
		return "maxed"
	end
	return "available"
end

function PlayerState:pollination(node): number
	if self.blooms < 1 then
		return 1
	end
	local owned = 0
	for _, nid in Nodes.Neighbours[node.id] do
		if self:level(nid) > 0 then
			owned += 1
		end
	end
	return 1 + Config.PollinationBonus * owned
end

function PlayerState:stats()
	local clickAdd, passive = 1, 0
	local seedMult, clickMult, passiveMult, auto = 1, 1, 1, 0
	for _, node in Nodes.List do
		local lv = self:level(node.id)
		local e = node.effect
		if lv > 0 and e then
			local t = e.type
			if t == "click" then
				clickAdd += e.value * lv * self:pollination(node)
			elseif t == "passive" then
				passive += e.value * lv * self:pollination(node)
			elseif t == "seedMult" then
				seedMult *= e.value ^ lv
			elseif t == "clickMult" then
				clickMult *= e.value ^ lv
			elseif t == "passiveMult" then
				passiveMult *= e.value ^ lv
			elseif t == "autoClick" then
				auto += e.value * lv
			end
		end
	end
	seedMult *= 1 + Config.PetalSeedBonus * self.petals
	if self.passes.DoubleSeeds then
		seedMult *= 2
	end
	return {
		click = clickAdd * clickMult * seedMult,
		perSec = passive * passiveMult * seedMult,
		auto = auto,
	}
end

function PlayerState:addSeeds(amount: number)
	self.seeds += amount
	self.runSeeds += amount
	self.totalSeeds += amount
	self.dirty = true
end

function PlayerState:click(): boolean
	local now = os.clock()
	if now - self.clickWindowStart >= 1 then
		self.clickWindowStart = now
		self.clickWindowCount = 0
	end
	self.clickWindowCount += 1
	if self.clickWindowCount > Config.MaxClicksPerSecond then
		return false
	end
	self.lastClick = now
	self.clicks += 1
	self:addSeeds(self:stats().click)
	return true
end

function PlayerState:buy(id: string): boolean
	local node = Nodes.ById[id]
	if not node or self:status(node) ~= "available" then
		return false
	end
	local cost = self:cost(node)
	if self:balance(node.currency) < cost then
		return false
	end
	if node.currency == "Petals" then
		self.petals -= cost
	else
		self.seeds -= cost
	end
	self.levels[id] = self:level(id) + 1
	self.dirty = true
	return true
end

function PlayerState:bloomPetals(): number
	if self.runSeeds < Config.BloomMinRunSeeds then
		return 0
	end
	return math.floor(math.sqrt(self.runSeeds / Config.BloomPetalDivisor))
end

function PlayerState:bloom(): boolean
	local gain = self:bloomPetals()
	if gain < 1 then
		return false
	end
	self.petals += gain
	self.blooms += 1
	self.seeds = 0
	self.runSeeds = 0
	for _, node in Nodes.List do
		if node.currency == "Seeds" then
			self.levels[node.id] = nil
		end
	end
	local keep = self:level("pkeep") * 3
	if keep > 0 then
		self.levels.power = keep
	end
	self.dirty = true
	self.notify(("Bloom! +%d petals. Neighbouring upgrades now pollinate each other."):format(gain))
	return true
end

function PlayerState:checkMysteries()
	for _, node in Nodes.List do
		local m = node.mystery
		if m and not self.revealed[node.id] and self:status(node) == "hidden" then
			local met = false
			if m.kind == "idle" then
				met = os.clock() - self.lastClick >= m.amount
			elseif m.kind == "clicks" then
				met = self.clicks >= m.amount
			elseif m.kind == "streak" then
				met = self.streak >= m.amount
			end
			if met then
				self.revealed[node.id] = true
				self.dirty = true
				self.notify(("A hidden upgrade was revealed: %s!"):format(node.name))
			end
		end
	end
end

function PlayerState:autoBuy()
	local best, bestCost
	for _, node in Nodes.List do
		if node.currency == "Seeds" and self:status(node) == "available" then
			local c = self:cost(node)
			if c <= self.seeds and (not bestCost or c < bestCost) then
				best, bestCost = node, c
			end
		end
	end
	if best then
		self:buy(best.id)
	end
end

function PlayerState:tick(dt: number)
	local s = self:stats()
	local gain = s.perSec * dt
	if s.auto > 0 then
		self.autoClickBank += s.auto * dt
		local whole = math.floor(self.autoClickBank)
		if whole > 0 then
			self.autoClickBank -= whole
			gain += s.click * whole
		end
	end
	if gain > 0 then
		self:addSeeds(gain)
	end
	if self.passes.AutoBuy then
		self.autoBuyTimer += dt
		if self.autoBuyTimer >= 1 then
			self.autoBuyTimer = 0
			self:autoBuy()
		end
	end
	self:checkMysteries()
end

-- Called on join: handles daily streak and offline earnings.
function PlayerState:onJoin()
	local day = math.floor(os.time() / 86400)
	if day == self.lastDay + 1 then
		self.streak += 1
	elseif day > self.lastDay + 1 then
		self.streak = 1
	elseif self.lastDay == 0 then
		self.streak = 1
	end
	self.lastDay = day

	local away = math.clamp(os.time() - self.lastSeen, 0, Config.OfflineCapSeconds)
	if away > 60 then
		local gain = self:stats().perSec * away * Config.OfflineEfficiency
		if gain > 0 then
			self:addSeeds(gain)
			self.notify(("Welcome back! Your garden grew while you were away (+%s seeds)."):format(
				require(ReplicatedStorage.Shared.Format).number(gain)
			))
		end
	end
	self.lastSeen = os.time()
end

function PlayerState:serialize()
	return {
		seeds = self.seeds,
		petals = self.petals,
		runSeeds = self.runSeeds,
		totalSeeds = self.totalSeeds,
		blooms = self.blooms,
		clicks = self.clicks,
		streak = self.streak,
		lastDay = self.lastDay,
		lastSeen = os.time(),
		levels = self.levels,
		revealed = self.revealed,
	}
end

function PlayerState:publish()
	local p = self.player
	local s = self:stats()
	p:SetAttribute("Seeds", self.seeds)
	p:SetAttribute("Petals", self.petals)
	p:SetAttribute("PerSec", s.perSec + s.auto * s.click)
	p:SetAttribute("ClickValue", s.click)
	p:SetAttribute("Blooms", self.blooms)
end

return PlayerState
