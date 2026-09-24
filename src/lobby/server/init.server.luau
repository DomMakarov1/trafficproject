--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameInfo = require(ReplicatedStorage.Shared.GameInfo)
local Loader = require(ReplicatedStorage.Shared.Loader)

Loader.load(script:FindFirstChild("Services"))

print(`[{GameInfo.name}] lobby server started (v{GameInfo.version})`)
