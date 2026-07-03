local AssetService = game:GetService("AssetService")
local CaptureService = game:GetService("CaptureService")

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

	local frame = GenerateTiledLUT()
	frame.Parent = surface

	workspace:SetAttribute("Ready", false)
	workspace:GetAttributeChangedSignal("Ready"):Wait()
	workspace:SetAttribute("Ready", nil)

	local editImage = screenshot()
	if editImage then
		print(editImage.Size)
		editImage:Destroy()
	end

	part:Destroy()
end

local toolbar = plugin:CreateToolbar("GenLUT")
local button = toolbar:CreateButton("LUT", "", "")

button.Click:Connect(function()
	captureLUT()
end)
