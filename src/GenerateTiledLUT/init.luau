local AssetService = game:GetService("AssetService")

local pkgs = game.ReplicatedStorage.Packages
local Parallel = require(pkgs.Parallel)

type WorkerAction = typeof(require(script.Worker))

local square = 6
local scheduler = Parallel.new(square ^ 2, {
	script = script.Worker,
	typecast = (nil :: any) :: WorkerAction,
})

local function chunkRect(rect: Rect, xSlices: number, ySlices: number)
	local width = rect.Max.X - rect.Min.X
	local height = rect.Max.Y - rect.Min.Y
	local x0 = rect.Min.X
	local y0 = rect.Min.Y

	xSlices = math.max(1, math.min(xSlices, width))
	ySlices = math.max(1, math.min(ySlices, height))

	local chunks = {}
	local stepY = math.floor(height / ySlices)
	local stepX = math.floor(width / xSlices)

	for dy = 1, ySlices do
		for dx = 1, xSlices do
			local subY0 = (dy - 1) * stepY
			local subY1 = if dy == ySlices then height else dy * stepY

			local subX0 = (dx - 1) * stepX
			local subX1 = if dx == xSlices then width else dx * stepX

			table.insert(chunks, Rect.new(x0 + subX0, y0 + subY0, x0 + subX1, y0 + subY1))
		end
	end

	return chunks
end

local function generateTiledLUT()
	scheduler:waitForReady()

	local chunkRects = chunkRect(Rect.new(0, 0, 4096, 4096), square, square)
	for _, rect in chunkRects do
		scheduler:schedule(rect)
	end

	local results = scheduler:workAsync()

	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(4096, 4096)

	for i, rect in chunkRects do
		local b = results[i]()
		local rectSize = Vector2.new(rect.Width, rect.Height)
		local editImage = AssetService:CreateEditableImage({ Size = rectSize })
		editImage:WritePixelsBuffer(Vector2.zero, rectSize, b)

		local label = Instance.new("ImageLabel")
		label.Name = tostring(i)
		label.Size = UDim2.fromScale(rectSize.X / 4096, rectSize.Y / 4096)
		label.Position = UDim2.fromScale(rect.Min.X / 4096, rect.Min.Y / 4096)
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.ImageContent = Content.fromObject(editImage)
		label.Parent = frame
	end

	return frame
end

return generateTiledLUT
