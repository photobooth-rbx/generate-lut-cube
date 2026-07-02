--!optimize 2

@native
local function worker(rect: Rect)
	local width, height = rect.Width, rect.Height
	local tile = buffer.create(width * height * 4)

	local bi = 0
	for y = rect.Min.Y + 1, rect.Max.Y do
		for x = rect.Min.X + 1, rect.Max.X do
			local i = (y - 1) * 4096 + (x - 1)
			local r = bit32.band(bit32.rshift(i, 16), 0xFF)
			local g = bit32.band(bit32.rshift(i, 8), 0xFF)
			local b = bit32.band(bit32.rshift(i, 0), 0xFF)

			bi = bi + 1
			local bj = (bi - 1) * 4
			buffer.writeu8(tile, bj + 0, r)
			buffer.writeu8(tile, bj + 1, g)
			buffer.writeu8(tile, bj + 2, b)
			buffer.writeu8(tile, bj + 3, 255)
		end
	end

	return tile
end

return worker
