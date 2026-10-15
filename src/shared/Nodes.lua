--[[
	Node definitions for the upgrade tree. To add content, add an entry here.

	Fields
	  id          unique string
	  name, desc  display text
	  currency    "Seeds" (default) or "Petals"
	  maxLevel    base max level (can be raised by "maxLevel" effects)
	  cost        cost of level 1; level n costs floor(cost * growth ^ n)
	  growth      cost growth per level
	  requires    list of { id, level } that must be owned first
	  needBlooms  number of Blooms done before this node appears
	  pos         Vector2 (studs, x/z) relative to the plot origin
	  effect      { type, value, target? } -- see PlayerState:stats()
	  mystery     { hint, kind = "idle"|"clicks"|"streak", amount } -- shows as ???
	              until the condition is met
	  decor       { kind = "grass"|"flower"|"tree"|"pond", at = Vector3, spread }
	              spawns one decoration per level owned in the world

	Effect types
	  click      +value seeds per click, per level
	  passive    +value seeds/sec, per level
	  seedMult   all seeds x value^level
	  clickMult  click seeds x value^level
	  passiveMult passive seeds x value^level
	  maxLevel   +value max level to `target`, per level
	  autoClick  +value automatic clicks/sec, per level
	  keepSprout after Bloom, start with value*level levels of "power"
]]

local V2, V3 = Vector2.new, Vector3.new

local list = {
	-- ===== Seeds tree =====
	{
		id = "power",
		name = "Sprout Power",
		desc = "+1 seed per click, per level",
		maxLevel = 10,
		cost = 10,
		growth = 1.5,
		pos = V2(0, -22),
		effect = { type = "click", value = 1 },
	},
	{
		id = "grass",
		name = "Grass Patch",
		desc = "+1 seed/sec, per level",
		maxLevel = 10,
		cost = 25,
		growth = 1.6,
		requires = { { id = "power", level = 1 } },
		pos = V2(-26, -40),
		effect = { type = "passive", value = 1 },
		decor = { kind = "grass", at = V3(-70, 0, 10), spread = 22 },
	},
	{
		id = "dew",
		name = "Morning Dew",
		desc = "All seeds x1.5",
		maxLevel = 1,
		cost = 200,
		growth = 1,
		requires = { { id = "power", level = 3 } },
		pos = V2(26, -40),
		effect = { type = "seedMult", value = 1.5 },
	},
	{
		id = "roots",
		name = "Deep Roots",
		desc = "+5 max level to Sprout Power",
		maxLevel = 1,
		cost = 300,
		growth = 1,
		requires = { { id = "dew", level = 1 } },
		pos = V2(0, -58),
		effect = { type = "maxLevel", target = "power", value = 5 },
	},
	{
		id = "rootnet",
		name = "Root Network",
		desc = "+5 max level to Grass Patch",
		maxLevel = 1,
		cost = 1500,
		growth = 1,
		requires = { { id = "grass", level = 3 } },
		pos = V2(-52, -58),
		effect = { type = "maxLevel", target = "grass", value = 5 },
	},
	{
		id = "flowers",
		name = "Wildflowers",
		desc = "+5 seeds/sec, per level",
		maxLevel = 5,
		cost = 500,
		growth = 1.8,
		requires = { { id = "grass", level = 3 } },
		pos = V2(-26, -76),
		effect = { type = "passive", value = 5 },
		decor = { kind = "flower", at = V3(-70, 0, -30), spread = 20 },
	},
	{
		id = "sun",
		name = "Sunlight",
		desc = "All seeds x2",
		maxLevel = 1,
		cost = 2500,
		growth = 1,
		requires = { { id = "dew", level = 1 } },
		pos = V2(52, -58),
		effect = { type = "seedMult", value = 2 },
	},
	{
		id = "bees",
		name = "Bees",
		desc = "Click seeds x1.5, per level",
		maxLevel = 3,
		cost = 3000,
		growth = 2.5,
		requires = { { id = "flowers", level = 2 } },
		pos = V2(-52, -94),
		effect = { type = "clickMult", value = 1.5 },
	},
	{
		id = "sapling",
		name = "Sapling",
		desc = "+25 seeds/sec, per level",
		maxLevel = 5,
		cost = 4000,
		growth = 2,
		requires = { { id = "flowers", level = 2 } },
		pos = V2(0, -94),
		effect = { type = "passive", value = 25 },
		decor = { kind = "tree", at = V3(70, 0, -30), spread = 24 },
	},
	{
		id = "pond",
		name = "Pond",
		desc = "All seeds x1.25, per level",
		maxLevel = 4,
		cost = 20000,
		growth = 3,
		requires = { { id = "sapling", level = 1 }, { id = "sun", level = 1 } },
		pos = V2(26, -112),
		effect = { type = "seedMult", value = 1.25 },
		decor = { kind = "pond", at = V3(70, 0, 20), spread = 14 },
	},

	-- ===== Mystery nodes (??? until the hidden condition is met) =====
	{
		id = "patient",
		name = "Patient Gardener",
		desc = "Passive seeds x1.5",
		maxLevel = 1,
		cost = 5000,
		growth = 1,
		requires = { { id = "grass", level = 3 } },
		pos = V2(52, -94),
		effect = { type = "passiveMult", value = 1.5 },
		mystery = { hint = "Gardeners reward those who wait...", kind = "idle", amount = 60 },
	},
	{
		id = "tapper",
		name = "Green Thumb",
		desc = "Click seeds x2",
		maxLevel = 1,
		cost = 2000,
		growth = 1,
		requires = { { id = "power", level = 3 } },
		pos = V2(-52, -22),
		effect = { type = "clickMult", value = 2 },
		mystery = { hint = "Something stirs after many, many taps.", kind = "clicks", amount = 500 },
	},
	{
		id = "moon",
		name = "Moonlit Seed",
		desc = "All seeds x1.5",
		maxLevel = 1,
		cost = 8000,
		growth = 1,
		requires = { { id = "dew", level = 1 } },
		pos = V2(78, -40),
		effect = { type = "seedMult", value = 1.5 },
		mystery = { hint = "Return three days in a row.", kind = "streak", amount = 3 },
	},

	-- ===== Petal tree (unlocks after the first Bloom) =====
	{
		id = "ppower",
		name = "Petal Power",
		desc = "All seeds x1.25, per level",
		currency = "Petals",
		maxLevel = 10,
		cost = 1,
		growth = 1.7,
		needBlooms = 1,
		pos = V2(-26, 38),
		effect = { type = "seedMult", value = 1.25 },
	},
	{
		id = "pauto",
		name = "Auto-Tapper",
		desc = "+1 automatic click/sec, per level",
		currency = "Petals",
		maxLevel = 5,
		cost = 3,
		growth = 2,
		needBlooms = 1,
		pos = V2(0, 38),
		effect = { type = "autoClick", value = 1 },
	},
	{
		id = "pkeep",
		name = "Seed Bank",
		desc = "After Bloom, start with +3 Sprout Power, per level",
		currency = "Petals",
		maxLevel = 5,
		cost = 2,
		growth = 2,
		needBlooms = 1,
		pos = V2(26, 38),
		effect = { type = "keepSprout", value = 3 },
	},
}

local ById = {}
for _, node in list do
	node.currency = node.currency or "Seeds"
	node.requires = node.requires or {}
	node.needBlooms = node.needBlooms or 0
	ById[node.id] = node
end

-- Adjacency (for pollination): a node neighbours anything it requires or that requires it.
local Neighbours = {}
for _, node in list do
	Neighbours[node.id] = Neighbours[node.id] or {}
end
for _, node in list do
	for _, req in node.requires do
		table.insert(Neighbours[node.id], req.id)
		table.insert(Neighbours[req.id], node.id)
	end
end

return {
	List = list,
	ById = ById,
	Neighbours = Neighbours,
	BloomPos = V2(0, 16),
}
