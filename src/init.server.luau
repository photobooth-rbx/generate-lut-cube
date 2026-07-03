local GenerateTiledLUT = require(script.GenerateTiledLUT)

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
