-- Global tuning knobs. Change numbers here, not in the logic.
return {
	DataStoreName = "TerraformV1",
	PlotSpacing = 260,

	OfflineCapSeconds = 8 * 3600,
	OfflineEfficiency = 0.5,

	BloomMinRunSeeds = 10000, -- run seeds needed before Bloom gives >= 1 petal
	BloomPetalDivisor = 10000, -- petals = floor(sqrt(runSeeds / divisor))
	PetalSeedBonus = 0.10, -- each petal = +10% seeds, forever

	PollinationBonus = 0.10, -- after first Bloom: +10% per owned neighbour node

	MaxClicksPerSecond = 25,

	-- Fill in with real game pass IDs once created on the Creator Dashboard.
	-- 0 = disabled (the shop pad hides itself).
	Passes = {
		DoubleSeeds = 0,
		AutoBuy = 0,
	},
}
