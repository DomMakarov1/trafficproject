--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameInfo = require(ReplicatedStorage.Shared.GameInfo)
local Loader = require(ReplicatedStorage.Shared.Loader)

Loader.load(script:FindFirstChild("Controllers"))

print(`[{GameInfo.name}] job client started (v{GameInfo.version})`)
