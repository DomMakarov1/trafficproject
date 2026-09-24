--!strict
-- Requires every ModuleScript directly inside a folder, calls init() on all of them,
-- then start() on all of them. Modules can safely reference each other in start().

export type Module = {
	init: (() -> ())?,
	start: (() -> ())?,
}

local Loader = {}

function Loader.load(folder: Instance?): { [string]: Module }
	local modules: { [string]: Module } = {}
	if not folder then
		return modules
	end

	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			modules[child.Name] = require(child) :: any
		end
	end

	for _, module in modules do
		local init = module.init
		if init then
			init()
		end
	end

	for _, module in modules do
		local start = module.start
		if start then
			task.spawn(start)
		end
	end

	return modules
end

return Loader
