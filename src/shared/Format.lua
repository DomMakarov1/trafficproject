local Format = {}

local SUFFIXES = { "", "k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.number(n: number): string
	if n ~= n then
		return "0"
	end
	if n < 1000 then
		if n == math.floor(n) then
			return tostring(n)
		end
		return string.format("%.2f", n)
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local scaled = n / 10 ^ (tier * 3)
	return string.format("%.2f%s", scaled, SUFFIXES[tier + 1])
end

return Format
