local AssetService = game:GetService("AssetService")
local CaptureService = game:GetService("CaptureService")
local ScriptEditorService = game:GetService("ScriptEditorService")

local GenerateTiledLUT = require(script.GenerateTiledLUT)

local function screenshot()
	local result: string?
	local complete = false
	local thread = coroutine.running()
	CaptureService:CaptureScreenshot(function(contentUri: string)
		result = contentUri
		complete = true
		task.spawn(thread)
	end)

	while not complete do
		coroutine.yield()
	end

	return result and AssetService:CreateEditableImageAsync(Content.fromUri(result))
end

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

local function captureLUT()
	local camera = workspace.CurrentCamera :: Camera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.identity

	local height = 2 * math.tan(math.rad(camera.FieldOfView / 2))
	local width = (camera.ViewportSize.X / camera.ViewportSize.Y) * height

	local part = Instance.new("Part")
	part.Locked = true
	part.Anchored = true
	part.Size = Vector3.new(width, height, 1)
	part.CFrame = CFrame.new(0, 0, -1.5)
	part.Parent = workspace

	local surface = Instance.new("SurfaceGui")
	surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surface.CanvasSize = Vector2.new(4096, 4096)
	surface.Face = Enum.NormalId.Back
	surface.LightInfluence = 0
	surface.Parent = part

	local frame, destroyImages = GenerateTiledLUT()
	frame.Parent = surface

	workspace:SetAttribute("Ready", false)
	workspace:GetAttributeChangedSignal("Ready"):Wait()
	workspace:SetAttribute("Ready", nil)

	local editImage = screenshot()
	destroyImages()

	if editImage then
		local meshPart = Instance.new("MeshPart")
		meshPart.TextureContent = Content.fromObject(editImage)
		meshPart.Name = "LUT"
		meshPart.Parent = game:GetService("StarterGui")

		local cubeModule = writeCube(editImage, 65) -- 33, 65, 256
		cubeModule.Parent = meshPart
	end

	part:Destroy()
end

local toolbar = plugin:CreateToolbar("GenLUT")
local button = toolbar:CreateButton("LUT", "", "")

button.Click:Connect(function()
	captureLUT()
end)
