local AssetService = game:GetService("AssetService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local StudioService = game:GetService("StudioService")

local CaptureLUT = require(script.CaptureLUT)

@native
local function writeCube(editImage: EditableImage, lutSize: number?)
	local pixels = editImage:ReadPixelsBuffer(Vector2.zero, editImage.Size)

	local sampleLUTSize = lutSize or 33
	local entries = sampleLUTSize ^ 3

	local norm = table.create(256)
	for v = 0, 255 do
		norm[v] = string.format("%.6f", v / 255)
	end

	local srcIndex = table.create(sampleLUTSize)
	for j = 0, sampleLUTSize - 1 do
		srcIndex[j] = math.round(j / (sampleLUTSize - 1) * 255)
	end

	local lines = table.create(entries + 2)
	lines[1] = 'TITLE "LUT"'
	lines[2] = "LUT_3D_SIZE " .. sampleLUTSize

	local n = 2
	for bj = 0, sampleLUTSize - 1 do
		local bSrc = srcIndex[bj] * 65536
		for gj = 0, sampleLUTSize - 1 do
			local gSrc = srcIndex[gj] * 256
			for rj = 0, sampleLUTSize - 1 do
				local pixel = (bSrc + gSrc + srcIndex[rj]) * 4
				local r = buffer.readu8(pixels, pixel + 0)
				local g = buffer.readu8(pixels, pixel + 1)
				local b = buffer.readu8(pixels, pixel + 2)

				n += 1
				lines[n] = norm[r] .. " " .. norm[g] .. " " .. norm[b]
			end
		end
	end

	local module = Instance.new("ModuleScript")
	module.Name = "LUT.cube"
	ScriptEditorService:UpdateSourceAsync(module, function()
		return table.concat(lines, "\n")
	end)

	return module
end

local function writeLUT(editImage: EditableImage)
	local meshPart = Instance.new("MeshPart")
	meshPart.TextureContent = Content.fromObject(editImage)
	meshPart.Name = "LUT"
	meshPart.Parent = game:GetService("StarterGui")

	-- lutSize typically is 33 or 65, but can put 256 for full resolution
	local cubeModule = writeCube(editImage, 65)
	cubeModule.Parent = meshPart
end

local toolbar = plugin:CreateToolbar("GenLUT")
local captureButton = toolbar:CreateButton("Capture LUT", "", "")
local loadButton = toolbar:CreateButton("Load LUT", "", "")

local debounce = false
captureButton.Click:Connect(function()
	if not debounce then
		debounce = true

		local runCapture = CaptureLUT()

		warn("Click the Capture LUT button again when ready")

		local thread = coroutine.running()
		captureButton.Click:Once(function()
			task.spawn(thread)
		end)

		coroutine.yield()

		local editImage = runCapture()
		if editImage then
			writeLUT(editImage)
		end

		debounce = false
	end
end)

loadButton.Click:Connect(function()
	local file = (StudioService:PromptImportFileAsync({ "png" }) :: any) :: File?
	local editImage = if file
		then AssetService:CreateEditableImageAsync(Content.fromUri(file:GetTemporaryId()))
		else nil

	if editImage then
		writeLUT(editImage)
	end
end)
