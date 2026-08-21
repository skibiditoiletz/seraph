local seraphAcc = {username="misyn",role="whitelisted",workshop={},hexColor="#ffbcf9",authKeys={first="",},userid=231,icon="rbxassetid://76229822465645",expires=0,}
if getgenv().loaded then 
	pcall(function()
		getgenv().library:unload_menu() 
		for i,v in next, getgenv().connections do v:Disconnect() end
	end)
end 

getgenv().loaded = true 

local seraphAcc = seraphAcc or {}

-- Variables 
local uis = game:GetService("UserInputService") 
local players = game:GetService("Players") 
local ws = game:GetService("Workspace")
local safeWorkspace = cloneref(workspace)
local rs = game:GetService("ReplicatedStorage")
local http_service = game:GetService("HttpService")
local gui_service = game:GetService("GuiService")
local lighting = game:GetService("Lighting")
local run = game:GetService("RunService")
local stats = game:GetService("Stats")
local coregui = cloneref(game:GetService("CoreGui"))
local debris = game:GetService("Debris")
local tween_service = game:GetService("TweenService")
local sound_service = game:GetService("SoundService")
local configName = "default"
local player_list = {}
local esp_frames = {}
local lerpedFlySpeed, totalSpeed = 0, 1;

-- local _assets = game:GetObjects("rbxassetid://96007083256961")[1]:Clone()

function xpcall(...)
	for _, toPcall in {...} do
		if pcall(toPcall) then break end
	end
end

local cons = {}

-- local peakAsset = game:GetObjects("rbxassetid://113170053514092")[1]:Clone()
-- peakAsset.Size = Vector3.zero
-- peakAsset.Anchored, peakAsset.CanCollide, peakAsset.CanTouch, peakAsset.CanQuery = true, false, false, false

local visualization = peakAsset:Clone()
-- draw visualization
do
	function createArc(startAngle, endAngle, segments, radiusScale, thicknessScale)
		radiusScale = radiusScale or 0.45   -- % of min(parent size)
		thicknessScale = thicknessScale or 0.05

		local frame = Instance.new("Frame")
		frame.Name = "Arc"
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)

		local pieces = {}

		local function rebuild()
			for _, v in ipairs(pieces) do
				v:Destroy()
			end
			table.clear(pieces)

			local size = frame.AbsoluteSize
			if size.X == 0 or size.Y == 0 then return end

			local minSize = math.min(size.X, size.Y)
			local innerRadius = minSize * radiusScale
			local thickness = minSize * thicknessScale

			local startRad = math.rad(startAngle)
			local endRad = math.rad(endAngle)
			local theta = (endRad - startRad) / segments
			local sideLen = 2 * math.tan(theta / 2) * innerRadius

			for i = 0, segments - 1 do
				local angle = startRad + theta * (i + 0.5)

				local x = math.cos(angle) * innerRadius
				local y = math.sin(angle) * innerRadius

				local f = Instance.new("Frame")
				f.AnchorPoint = Vector2.new(0.5, 0.5)
				f.Size = UDim2.fromOffset(sideLen + 1, thickness)
				f.Position = UDim2.fromOffset(
					size.X / 2 + x,
					size.Y / 2 + y
				)
				f.Rotation = math.deg(angle) + 90
				f.BorderSizePixel = 0
				f.BackgroundColor3 =
					Color3.fromHSV(i / (segments - 1), 1, 1):Lerp(Color3.new(1,1,1), .5)

				f.Parent = frame
				table.insert(pieces, f)
			end
		end

		frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(rebuild)
		task.defer(rebuild)

		return frame
	end

	visualization:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("ImageLabel").ImageTransparency = 0.7
	local frame = createArc(0, 360, 360 / 5, 0.5, 0.007)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Parent = visualization:FindFirstChildWhichIsA("SurfaceGui")
	visualization:FindFirstChildWhichIsA("SurfaceGui").SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	visualization:FindFirstChildWhichIsA("SurfaceGui").PixelsPerStud = 50
	visualization.Parent = nil
end
-- end visualization

getgenv().connections = cons

--local run_debug = false
makefolder("seraph/debug")
makefolder("seraph/configs")
makefolder("seraph/sounds")

for soundPath, soundUrl in {
	["seraph/sounds/bubble.mp3"] = "https://github.com/ravegirls/meow/raw/refs/heads/main/gmod_bubble.mp3",
	["seraph/sounds/bubble2.mp3"] = "https://github.com/ravegirls/meow/raw/refs/heads/main/gmod_bubble_2.mp3",
	["seraph/sounds/trident.mp3"] = "https://github.com/ravegirls/meow/raw/refs/heads/main/trident-new.mp3",
}
 do
	if not isfile(soundPath) then
		writefile(soundPath, game:HttpGet(soundUrl))
	end
end

--if run_debug then pcall(delfile, "seraph/cache/seraph.gif") pcall(delfile, "seraph/debug/debug.log") end
pcall(function()
	local defaultConfig = readfile("seraph/configs/default.value")
	if defaultConfig then
		configName = defaultConfig
	end
end)

local elapsed_ticks = 0
local holder = Instance.new("Folder", cloneref(workspace))

function get(url)
	return game:HttpGet(url) or request({
		Url = url,
		Method = "GET",
		Headers = {
			["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 SeraphClient/1.0 Chocosploit/1.0"
		}
	}).Body
end
function setproperty(obj, prop, value)
	obj[prop] = value
end

local isDone
task.spawn(function()

	local load = Instance.new("ScreenGui")
	load.Name = "load"
	load.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	load.Parent = coregui

	local frame = Instance.new("Frame")
	frame.Name = "frame"
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 0, 0, 25)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.BorderColor3 = Color3.new(0, 0, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.Parent = load

	local UICorner = Instance.new("UICorner")
	UICorner.Name = "UICorner"

	UICorner.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "icon"
	icon.Size = UDim2.new(0, 25, 0, 25)
	icon.BackgroundColor3 = Color3.new(1, 1, 1)
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.BorderColor3 = Color3.new(0, 0, 0)
	icon.Transparency = 1
	icon.Image = "rbxassetid://101942723117519"
	icon.Parent = frame

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Name = "UIStroke"
	UIStroke.Thickness = 2
	UIStroke.Parent = frame

	local UIStroke2 = Instance.new("UIStroke")
	UIStroke2.Name = "UIStroke"
	UIStroke2.Thickness = 2.5
	UIStroke2.Transparency = 0.25
	UIStroke2.Parent = frame

	local UIStroke3 = Instance.new("UIStroke")
	UIStroke3.Name = "UIStroke"
	UIStroke3.Thickness = 3
	UIStroke3.Transparency = 0.5
	UIStroke3.Parent = frame

	local UIStroke4 = Instance.new("UIStroke")
	UIStroke4.Name = "UIStroke"
	UIStroke4.Thickness = 4
	UIStroke4.Transparency = 0.75
	UIStroke4.Parent = frame

	local UIStroke5 = Instance.new("UIStroke")
	UIStroke5.Name = "UIStroke"
	UIStroke5.Thickness = 8
	UIStroke5.Transparency = 0.9900000095367432
	UIStroke5.Parent = frame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Name = "UIListLayout"
	UIListLayout.Padding = UDim.new(0, 6)
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = frame

	local fps = Instance.new("TextLabel")
	fps.Name = "fps"
	fps.Size = UDim2.new(0, 0, 0, 25)
	fps.BackgroundColor3 = Color3.new(1, 1, 1)
	fps.BackgroundTransparency = 1
	fps.BorderSizePixel = 0
	fps.BorderColor3 = Color3.new(0, 0, 0)
	fps.AutomaticSize = Enum.AutomaticSize.X
	fps.LayoutOrder = 7
	fps.Text = "Preparing setup.."
	fps.TextColor3 = Color3.new(0.956863, 0.956863, 0.956863)
	fps.TextSize = 16
	fps.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	fps.TextWrapped = true
	fps.Parent = frame

	local UIPadding = Instance.new("UIPadding")
	UIPadding.Name = "UIPadding"
	UIPadding.PaddingRight = UDim.new(0, 5)
	UIPadding.Parent = frame

	local UIStroke6 = Instance.new("UIStroke")
	UIStroke6.Name = "UIStroke"
	UIStroke6.Thickness = 4.5
	UIStroke6.Transparency = 0.800000011920929
	UIStroke6.Parent = frame

	local UIStroke7 = Instance.new("UIStroke")
	UIStroke7.Name = "UIStroke"
	UIStroke7.Thickness = 5
	UIStroke7.Transparency = 0.8500000238418579
	UIStroke7.Parent = frame

	local UIStroke8 = Instance.new("UIStroke")
	UIStroke8.Name = "UIStroke"
	UIStroke8.Thickness = 5.5
	UIStroke8.Transparency = 0.8999999761581421
	UIStroke8.Parent = frame

	frame.Visible = false
	task.wait(1)
	frame.Visible = true
	setproperty(fps,"TextTransparency",1)
	setproperty(icon,"ImageTransparency",1)
	setproperty(frame,"BackgroundTransparency",1)
	tween_service:Create(fps, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0}):Play()
	tween_service:Create(icon, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
	tween_service:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0}):Play()
	tween_service:Create(icon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageColor3 = Color3.new()}):Play()
	for _, stroke in frame:GetChildren() do
		if not stroke:IsA("UIStroke") then continue end
		local trans = stroke.Transparency
		setproperty(stroke,"Transparency",1)
		tween_service:Create(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = trans}):Play()
	end

	task.wait(0.25)

	if not isfile("seraph/cache/seraphdata.gif") then

		makefolder("seraph/gifs")

		tween_service:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0.1, 0)}):Play()

		for i = 1, 150 do
			local frame_translation = string.format("frame_%03d_delay-0.02s.png", i-1)
			writefile(`seraph/gifs/{frame_translation}`, get("https://raw.githubusercontent.com/ravegirls/cdn/refs/heads/main/sequence/" .. frame_translation))

			fps.Text = "We're geting things set up for you..".. (" (" .. i .. "/150)")
			task.wait()


		end
		writefile("seraph/cache/seraphdata.gif", "<translation=\"completed\">")

		task.wait(0.5)

		tween_service:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

		task.wait(1)
	end

	if not isfile("seraph/cache/images.cache") then

		tween_service:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0.1, 0)}):Play()

		local asset_list = {
			['von.png'] = 'https://raw.githubusercontent.com/ravegirls/cdn/refs/heads/main/image-removebg-preview.png',
			['icon.jpg'] = 'https://i1.sndcdn.com/avatars-V9XiJ3sEbqGgCbp4-Apy7ZQ-t500x500.jpg',
			['atom.png'] = 'https://raw.githubusercontent.com/ravegirls/cdn/refs/heads/main/atom.png',
			['ser.png'] = 'https://raw.githubusercontent.com/ravegirls/cdn/refs/heads/main/ser.png',
			['aph.png'] = 'https://raw.githubusercontent.com/ravegirls/cdn/refs/heads/main/aph.png',
		}

		makefolder("seraph/imgs")

		local n, l = 0, 0

		for _ in asset_list do
			l += 1
		end

		for i, v in asset_list do
			n += 1

			local src = get(v)

			writefile(`seraph/imgs/{i}`, src)

			fps.Text = "Downloading images..".. (` ({n} / {l})`)
			task.wait(0.5)


		end
		writefile("seraph/cache/images.cache", "<translation=\"completed\">")

		task.wait(0.5)

		tween_service:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

		task.wait(1)
	end

	fps.Text = "Cleaning up..."

	task.wait(0.25)

	isDone = true

	tween_service:Create(fps, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 1}):Play()
	tween_service:Create(icon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
	tween_service:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 1}):Play()
	for _, stroke in frame:GetChildren() do
		if not stroke:IsA("UIStroke") then continue end
		tween_service:Create(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
	end
end)


repeat task.wait() until isDone

function create(class, prop)
	local inst = Instance.new(class)
	if typeof(prop) == 'table' then
		for i, v in prop do
			inst[i] = v
		end
	end
	return inst
end

if (game.GameId == 73885730) then
	configName = "prison-life"
elseif (game.PlaceId == 286090429) then
	configName = "arsenal"
end

pcall(function()
	local defaultConfig = readfile(`seraph/configs/{tostring(game.PlaceId)}.value`)
	if defaultConfig then
		configName = defaultConfig
	end
end)

for _,v in listfiles("seraph") do
	if string.match(v, ".value") or string.match(v, ".vector") then
		local name = string.gsub(v, "seraph/", "")
		local src = readfile(v)
		delfile(v)
		writefile(`seraph/configs/{name}`, src)
	end
end

pcall(sethiddenproperty,workspace,"SignalBehavior",Enum.SignalBehavior.Immediate)

local sfx = {
	none = "",
	rust = "rbxassetid://97189180645129",
	ding = "rbxassetid://9126073001",
	neverlose = "rbxassetid://18391691942",
	fatality = "rbxassetid://6607142036",
	hit = "rbxassetid://71845200764605",
	hitmarker = "rbxassetid://7242037470",
	baimware = "rbxassetid://6607339542",
	onetap = "rbxassetid://126006761622363",
	kickball = "rbxassetid://102170046721162",
	gamesense = "rbxassetid://4817809188",
	pop = "rbxassetid://85730811347567",
	["minecraft success"] = "rbxassetid://135478009117226",
	["bwomp"] = "rbxassetid://89053290756490",
	["retro ouch"] = "rbxassetid://109681634329245",
	["terraria slime"] = "rbxassetid://6916371803",
}

for _, file in listfiles("seraph/sounds/") do
	local fileName = file:match("[^\\/]+$"):gsub("%.mp3", "")
	sfx[fileName] = getcustomasset(file)
end

local vec2 = Vector2.new
local vec3 = Vector3.new
local dim2 = UDim2.new
local dim = UDim.new 
local rect = Rect.new
local cfr = CFrame.new
local empty_cfr = cfr()
local point_object_space = empty_cfr.PointToObjectSpace
local angle = CFrame.Angles
local dim_offset = UDim2.fromOffset

local color = Color3.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new
local numseq = NumberSequence.new
local numkey = NumberSequenceKeypoint.new

local camera = ws.CurrentCamera
local lp = players.LocalPlayer
if not lp then
	repeat run.RenderStepped:Wait() lp = players.LocalPlayer until lp
end
local mouse = lp:GetMouse() 
local gui_offset = gui_service:GetGuiInset().Y

local max = math.max 
local floor = math.floor 
local min = math.min 
local abs = math.abs 
local noise = math.noise
local rad = math.rad 
local random = math.random 
local pow = math.pow 
local sin = math.sin 
local cos = math.cos
local pi = math.pi 
local tan = math.tan 
local atan2 = math.atan2 
local clamp = math.clamp 
local rng = random

local insert = table.insert
local find = table.find 
local remove = table.remove
local concat = table.concat
-- 

-- Library init
getgenv().library = {
	directory = "seraph",
	folders = {
		"/fonts",
		"/cfg",
		"/lua"
	},
	flags = {},
	config_flags = {},

	connections = {},   
	notifications = {},
	playerlist_data = {
		players = {},
		player = {}, 
	},
	colorpicker_open = false; 
	gui; 
}


library.gradientEvent = Instance.new("BindableEvent")
library.gradientChanged = library.gradientEvent.Event

library.guiVisibility = Instance.new("BindableEvent")
library.guiVisibilityChanged = library.guiVisibility.Event

library.font = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Light, Enum.FontStyle.Normal)

local themes = {
	corners = true,

	preset = {
		--[[outline = rgb(10, 10, 10),
		inline = rgb(35, 35, 35),
		text = rgb(180, 180, 180),
		text_outline = rgb(0, 0, 0),
		background = rgb(20, 20, 20),

		["1"] = rgb(33, 33, 33), 
		["2"] = rgb(33, 33, 33),
		["3"] = rgb(33, 33, 33),
		]]
		outline = rgb(0, 0, 0),             -- Pure black outer border
        inline = rgb(14, 14, 14),           -- Lighter inner "shine" border
        text = rgb(255, 255, 255),          -- Bright white text
        text_outline = rgb(0, 0, 0),
        background = rgb(15, 15, 15),       -- Darker background for contrast
        
        -- These replace your "1", "2", "3" with the Bitchbot section colors
        ["1"] = rgb(20, 20, 20), 
        ["2"] = rgb(20, 20, 20),
        ["3"] = rgb(20, 20, 20),

		button = seraphAcc.theme and seraphAcc.theme.button or rgb(121, 96, 180),
		button_alt = seraphAcc.theme and seraphAcc.theme.button_alt or rgb(151, 125, 214)
	},

	utility = {
		inline = {
			BackgroundColor3 = {} 	
		},
		text = {
			TextColor3 = {}	
		},
		text_outline = {
			Color = {} 	
		},
		["1"] = {
			BackgroundColor3 = {}, 	
			TextColor3 = {}, 
			ImageColor3 = {}, 
			ScrollBarImageColor3 = {} 
		},
		["2"] = {
			BackgroundColor3 = {}, 	
			TextColor3 = {}, 
			ImageColor3 = {}, 
			ScrollBarImageColor3 = {} 
		},
		["3"] = {
			BackgroundColor3 = {}, 	
			TextColor3 = {}, 
			ImageColor3 = {}, 
			ScrollBarImageColor3 = {} 
		},
	}
}

local keys = {
	[Enum.KeyCode.LeftShift] = "LS",
	[Enum.KeyCode.RightShift] = "RS",
	[Enum.KeyCode.LeftControl] = "LC",
	[Enum.KeyCode.RightControl] = "RC",
	[Enum.KeyCode.Insert] = "INS",
	[Enum.KeyCode.Backspace] = "BS",
	[Enum.KeyCode.Return] = "Ent",
	[Enum.KeyCode.LeftAlt] = "LA",
	[Enum.KeyCode.RightAlt] = "RA",
	[Enum.KeyCode.CapsLock] = "CAPS",
	[Enum.KeyCode.One] = "1",
	[Enum.KeyCode.Two] = "2",
	[Enum.KeyCode.Three] = "3",
	[Enum.KeyCode.Four] = "4",
	[Enum.KeyCode.Five] = "5",
	[Enum.KeyCode.Six] = "6",
	[Enum.KeyCode.Seven] = "7",
	[Enum.KeyCode.Eight] = "8",
	[Enum.KeyCode.Nine] = "9",
	[Enum.KeyCode.Zero] = "0",
	[Enum.KeyCode.KeypadOne] = "Num1",
	[Enum.KeyCode.KeypadTwo] = "Num2",
	[Enum.KeyCode.KeypadThree] = "Num3",
	[Enum.KeyCode.KeypadFour] = "Num4",
	[Enum.KeyCode.KeypadFive] = "Num5",
	[Enum.KeyCode.KeypadSix] = "Num6",
	[Enum.KeyCode.KeypadSeven] = "Num7",
	[Enum.KeyCode.KeypadEight] = "Num8",
	[Enum.KeyCode.KeypadNine] = "Num9",
	[Enum.KeyCode.KeypadZero] = "Num0",
	[Enum.KeyCode.Minus] = "-",
	[Enum.KeyCode.Equals] = "=",
	[Enum.KeyCode.Tilde] = "~",
	[Enum.KeyCode.LeftBracket] = "[",
	[Enum.KeyCode.RightBracket] = "]",
	[Enum.KeyCode.RightParenthesis] = ")",
	[Enum.KeyCode.LeftParenthesis] = "(",
	[Enum.KeyCode.Semicolon] = ",",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.BackSlash] = "\\",
	[Enum.KeyCode.Comma] = ",",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.Asterisk] = "*",
	[Enum.KeyCode.Plus] = "+",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Backquote] = "`",
	[Enum.UserInputType.MouseButton1] = "MB1",
	[Enum.UserInputType.MouseButton2] = "MB2",
	[Enum.UserInputType.MouseButton3] = "MB3",
	[Enum.KeyCode.Escape] = "ESC",
	[Enum.KeyCode.Space] = "SPC",
}

library.__index = library

for _, path in next, library.folders do 
	makefolder(library.directory .. path)
end

local flags = library.flags 
local config_flags = library.config_flags

-- Font importing system 
local fonts = {}; do
	function Register_Font(Name, Weight, Style, Asset)
		Asset.Id = library.directory .. "/fonts/" .. Asset.Id
		if not isfile(Asset.Id) then
			writefile(Asset.Id, Asset.Font)
		end

		if isfile(library.directory .. "/fonts/" ..Name .. ".font") then
			delfile(library.directory .. "/fonts/" ..Name .. ".font")
		end

		local Data = {
			name = Name,
			faces = {
				{
					name = "Regular",
					weight = Weight,
					style = Style,
					assetId = getcustomasset(Asset.Id),
				},
			},
		}

		writefile(Name .. ".font", game:GetService("HttpService"):JSONEncode(Data))

		return getcustomasset(Name .. ".font");
	end

	local ProggyTiny = Register_Font("ProggyTiny", 200, "Normal", {
		Id = "ProggyTiny.ttf",
		Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/tahoma_bold.ttf"),
	})

	local ProggyClean = Register_Font("ProggyClean", 200, "normal", {
		Id = "ProggyClean.ttf",
		Font = game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf")
	})

	local Pixel = Register_Font("Pixel", 200, "normal", {
		Id = "Pixel.ttf",
		Font = game:HttpGet("https://github.com/ravegirls/meow/raw/refs/heads/main/pixel.ttf")
	})

	local Tahoma = Register_Font("Tahoma", 200, "normal", {
		Id = "Tahoma.ttf",
		Font = game:HttpGet("https://github.com/ravegirls/meow/raw/refs/heads/main/tahoma-bold.ttf")
	})

	local Verdana = Register_Font("Verdana", 200, "normal", {
		Id = "Verdana.ttf",
		Font = game:HttpGet("https://seraph.wtf/assets/verdana.ttf")
	})

	local Pixel2 = Register_Font("Pixel2", 200, "normal", {
		Id = "Pixel2.ttf",
		Font = game:HttpGet("https://seraph.wtf/assets/pixelfont.ttf")
	})

	fonts = {
		["TahomaBold"] = Font.new(ProggyTiny, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		["ProggyClean"] = Font.new(ProggyClean, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		["Pixel"] = Font.new(Pixel, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		["Verdana"] = Font.new(Verdana, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		["Tahoma"] = Font.new(Tahoma, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		["Pixel2"] = Font.new(Pixel2, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	}

	library.font = fonts.ProggyClean
end
--
-- 

-- Library functions 
-- Misc functions
function library:tween(obj, properties) 
	local tween = tween_service:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), properties):Play()

	return tween
end 

function library:close_current_element(cfg) 
	local path = library.current_element_open

	if path then
		path.set_visible(false)
		path.open = false 
	end
end 

function library:resizify(frame) 
	local Frame = Instance.new("TextButton")
	Frame.Position = dim2(1, -10, 1, -10)
	Frame.BorderColor3 = rgb(0, 0, 0)
	Frame.Size = dim2(0, 10, 0, 10)
	Frame.BorderSizePixel = 0
	Frame.BackgroundColor3 = rgb(255, 255, 255)
	Frame.Parent = frame
	Frame.BackgroundTransparency = 1 
	Frame.Text = ""

	local resizing = false 
	local start_size 
	local start 
	local og_size = frame.Size  

	Frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			start = input.Position
			start_size = frame.Size
		end
	end)

	Frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)

	library:connection(uis.InputChanged, function(input, game_event) 
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local viewport_x = camera.ViewportSize.X
			local viewport_y = camera.ViewportSize.Y

			local current_size = dim2(
				start_size.X.Scale,
				math.clamp(
					start_size.X.Offset + (input.Position.X - start.X),
					og_size.X.Offset,
					viewport_x
				),
				start_size.Y.Scale,
				math.clamp(
					start_size.Y.Offset + (input.Position.Y - start.Y),
					og_size.Y.Offset,
					viewport_y
				)
			)
			frame.Size = current_size
		end
	end)
end

function library:mouse_in_frame(uiobject)
	local y_cond = uiobject.AbsolutePosition.Y <= mouse.Y and mouse.Y <= uiobject.AbsolutePosition.Y + uiobject.AbsoluteSize.Y
	local x_cond = uiobject.AbsolutePosition.X <= mouse.X and mouse.X <= uiobject.AbsolutePosition.X + uiobject.AbsoluteSize.X

	return (y_cond and x_cond)
end

library.lerp = function(start, finish, t)
	t = t or 1 / 8

	return start * (1 - t) + finish * t
end

function library:draggify(frame, scale)
	local scale = scale or 1
	local dragging = false 
	local start_size = frame.Position
	local start 

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			start = input.Position
			start_size = frame.Position
		end
	end)

	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	library:connection(uis.InputChanged, function(input, game_event) 
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local viewport_x = camera.ViewportSize.X
			local viewport_y = camera.ViewportSize.Y

			local current_position = dim2(
				0,
				floor(clamp(
					start_size.X.Offset + (input.Position.X - start.X),
					0,
					viewport_x - frame.Size.X.Offset
					) / scale) * scale,
				0,
				floor(clamp(
					start_size.Y.Offset + (input.Position.Y - start.Y),
					0,
					viewport_y - frame.Size.Y.Offset
					) / scale) * scale
			)

			frame.Position = current_position
		end
	end)
end 

function library:convert(str)
	local values = {}

	for value in string.gmatch(str, "[^,]+") do
		insert(values, tonumber(value))
	end

	if #values == 4 then              
		return unpack(values)
	else 
		return
	end
end

function library:convert_enum(enum)
	local enum_parts = {}

	for part in string.gmatch(enum, "[%w_]+") do
		insert(enum_parts, part)
	end

	local enum_table = Enum
	for i = 2, #enum_parts do
		local enum_item = enum_table[enum_parts[i]]

		enum_table = enum_item
	end

	return enum_table
end

local config_holder;
function library:update_config_list() 
	if not config_holder then 
		return 
	end

	local list = {}

	for idx, file in listfiles(library.directory .. "/configs") do
		if not file:match(".cfg") then continue end
		local name = file:gsub(library.directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(library.directory .. "\\cfg\\", "")
		list[#list + 1] = name
	end


	config_holder.refresh_options(list)
end 

function library:get_config()
    local Config = {}

    for flag_name, v in pairs(flags) do
        if type(v) == "table" and v.key then
            Config[flag_name] = {
                active = v.active, 
                mode = v.mode, 
                key = tostring(v.key)
            }
        elseif type(v) == "table" and v["Color"] then
            local colorHex = typeof(v["Color"]) == "Color3" and v["Color"]:ToHex() or v["Color"]
            Config[flag_name] = {
                Transparency = v["Transparency"] or 0, 
                Color = colorHex
            }
        elseif type(v) ~= "table" and type(v) ~= "userdata" and type(v) ~= "function" then
            Config[flag_name] = v
        elseif type(v) == "table" then
            local cleanTable = {}
            local isPureTable = true
            for i, val in pairs(v) do
                if type(val) == "userdata" or type(val) == "function" then
                    isPureTable = false
                    break
                end
                cleanTable[i] = val
            end
            if isPureTable then
                Config[flag_name] = cleanTable
            end
        end
    end 

    return http_service:JSONEncode(Config)
end

function library:load_config(config_json) 
	local config = http_service:JSONDecode(config_json)

	for _, v in next, config do 
		pcall(function()
			local function_set = library.config_flags[_]

			if _ == "config_name_list" then 
				return
			end

			if function_set then 
				if type(v) == "table" and v["Transparency"] and v["Color"] then
					function_set(hex(v["Color"]), v["Transparency"])
					--print("set cp!")
				elseif type(v) == "table" and v["active"] then 
					function_set(v)
				else
					function_set(v)
				end
			end 
		end)
	end 
end 

function library:round(number, float) 
	local multiplier = 1 / (float or 1)

	return floor(number * multiplier + 0.5) / multiplier
end 

function library:apply_theme(instance, theme, property) 
	insert(themes.utility[theme][property], instance)
end

function library:update_theme(theme, color)
	for _, property in themes.utility[theme] do 

		for m, object in property do 
			if object[_] == themes.preset[theme] then 
				object[_] = color 
			end
		end 
	end 

	themes.preset[theme] = color 
end 

function library:connection(signal, callback)
	local connection = signal:Connect(callback)

	insert(library.connections, connection)

	return connection 
end

function library:apply_stroke(parent) 
	local STROKE = library:create("UIStroke", {
		Parent = parent,
		Color = themes.preset.text_outline, 
		LineJoinMode = Enum.LineJoinMode.Miter
	}) 

	library:apply_theme(STROKE, "text_outline", "Color")
end

function library:create(instance, options)
	local ins = Instance.new(instance) 

	for prop, value in next, options do 
		ins[prop] = value
	end

	if instance == "TextLabel" or instance == "TextButton" or instance == "TextBox" then 	
		library:apply_theme(ins, "text", "TextColor3")
		library:apply_stroke(ins)
	end

	return ins 
end

function library:unload_menu() 
	if library.gui then 
		library.gui:Destroy()
	end

	for index, connection in next, library.connections do 
		pcall(function()
			connection:Disconnect() 
			connection = nil 
		end)
	end     

	if library.sgui then 
		library.sgui:Destroy()
	end 

	unload_full()

	library = nil 

end 
--


function ref_trans(obj)

	if not transValues[obj] then
		transValues[obj] = {}
	end
end

-- Library element functions

function udim_scale(udim, scale)
	return UDim2.new(udim.X.Scale * scale, udim.X.Offset * scale, udim.Y.Scale * scale, udim.Y.Offset * scale)
end
function library:window(properties)
	local cfg = {
		name = properties.name or properties.Name or "fijihack.panda",
		size = properties.size or properties.Size or dim2(0, 460, 0, 362), 
		selected_tab 
	}

	library.gui = library:create("ScreenGui", {
		Parent = coregui,
		Name = "\0",
		Enabled = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 9e4
	})

	local particles = { }
	for i = 1, 65 do
		particles[i] = {
			frame = library:create("Frame", {
				Parent = library.gui,
				Size = dim2(0, 2, 0, 2),
				BackgroundColor3 = rgb(255, 255, 255),
				BorderSizePixel = 0,
				Position = dim2(math.random(), math.random(-10,10), math.random(), math.random(-10,10)),
				BackgroundTransparency = 1
			}),
			position = vec2(math.random() * camera.ViewportSize.X, -rng(1,20)),
			velocity = vec2(rng(-5,5), rng(5,8))
		}
	end


	local scale, scale2 = library:create("UIScale", {
		Parent = library.gui
	}), library:create("UIScale", {
		Parent = library.gui
	})

	library.gui_scale = 1
	library.main_scale = scale

	pcall(function()
		library.gui_scale = tonumber(readfile("seraph/configs/default_scale.value"))
	end)

	local tween
	local info = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	library.gui_visible = true
	library.guiVisibility:Fire(library.gui_visible)

	local gui_connections = {}

	uis.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Home and not guiDebounce then
			library:set_visibility()
		end
	end)

	function library:set_visibility()
		if tween then tween:Cancel() end
		guiDebounce = true
		tween = tween_service:Create(scale, info, {Scale = library.gui_visible and 0 or library.gui_scale}) 		tween:Play()
		library.gui_visible = not library.gui_visible 
		writefile("seraph/configs/default_scale.value", tostring(library.gui_scale))
		library.guiVisibility:Fire(library.gui_visible)
			--[[if library.gui_visible then
				for x, con in gui_connections do
					con:Enable()
					if x % 5 == 0 then task.wait() end
				end
			else
				for x, con in gui_connections do
					con:Disable()
					if x % 5 == 0 then task.wait() end
				end
			end]]
			task.wait()
		guiDebounce = false
	end

	local window_outline = library:create("Frame", {
		Parent = library.gui;
		Position = dim2(0.5, -cfg.size.X.Offset / 2, 0.5, -cfg.size.Y.Offset / 2);
		BorderColor3 = rgb(0, 0, 0);
		Size = cfg.size;
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	function library:set_scale(scale_value)
		library.gui_scale = scale_value
		if tween then tween:Cancel() end
		scale.Scale = library.gui_visible and scale_value or 0
	end

	task.delay(0.1, function()
		tween = tween_service:Create(scale, info, {Scale = library.gui_scale})
		tween:Play()
	end)


	-- Window

	library:create("ImageLabel", {
		Name = "glow",
		Image = "rbxassetid://18245826428",
		BackgroundTransparency = 1,
		ImageColor3 = rgb(),
		ZIndex = -1,
		ImageTransparency = 0.8,
		Size = UDim2.new(1, 40, 1, 40),
		Position = UDim2.new(0, -20, 0, -20),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(21, 21, 79, 79),
		Parent = window_outline
	})

	library.main_frame = window_outline

	if themes.corners then
		library:create("UICorner", {
			Parent = window_outline,
			CornerRadius = UDim.new(0, 2)
		})

		scale.Parent = window_outline
	end

	window_outline.Position = dim2(0, window_outline.AbsolutePosition.Y, 0, window_outline.AbsolutePosition.Y)
	cfg.main_outline = window_outline

	library:resizify(window_outline)
	library:draggify(window_outline)

	local title_holder = library:create("Frame", {
		Parent = window_outline;
		BackgroundTransparency = 0.800000011920929;
		Position = dim2(0, 2, 0, 2);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -4, 0, 20);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 0, 0)
	});


	local ui_title = library:create("TextLabel", {
		FontFace = fonts["TahomaBold"];
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = title_holder;
		BackgroundTransparency = 1;
		Size = dim2(1, 0, 1, 0);
		BorderSizePixel = 0;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255),
		RichText = true,
	});

	function cfg:set_title(new_title)
		ui_title.Text = new_title
	end

	library.gradient = library:create("UIGradient", {
		Color = rgbseq{
			rgbkey(0, themes.preset["1"]), 
			rgbkey(0.5, themes.preset["2"]),
			rgbkey(1, themes.preset["3"]),
		};
		Parent = window_outline
	});

	local tab_button_holder = library:create("Frame", {
		AnchorPoint = vec2(0, 1);
		Parent = window_outline;
		BackgroundTransparency = 0.800000011920929;
		Position = dim2(0, 2, 1, -2);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -4, 0, 20);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 0, 0)
	}); cfg.tab_button_holder = tab_button_holder

	library:create("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Center;
		FillDirection = Enum.FillDirection.Horizontal;
		HorizontalAlignment = Enum.HorizontalAlignment.Center;
		HorizontalFlex = Enum.UIFlexAlignment.Fill;
		Parent = tab_button_holder;
		SortOrder = Enum.SortOrder.LayoutOrder;
		VerticalFlex = Enum.UIFlexAlignment.Fill
	});
	--

	return setmetatable(cfg, library)
end 

function library:tab(properties)
	local cfg = {
		name = properties.name or "visuals", 
		count = 0,
		on_click = properties.on_click or function() end,
	}

	-- Instances 
	-- Tab Button
	local tab_button = library:create("TextButton", {
		FontFace = library.font;
		TextColor3 = rgb(170, 170, 170);
		BorderColor3 = rgb(0, 0, 0);
		Text = '';
		Parent = self.tab_button_holder;
		BackgroundTransparency = 0;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.XY;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});
	-- 

	library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = rgb(170, 170, 170);
		BorderColor3 = rgb(0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		Text = cfg.name;
		Parent = tab_button;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.XY;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	library:create("UIGradient", {
		Color = rgbseq{
			rgbkey(0, themes.preset["1"]:lerp(rgb(), .3)), 
			rgbkey(1, themes.preset["2"]),
		};
		Rotation = 90;
		Parent = tab_button
	});

	-- Page
	local Page = library:create("Frame", {
		Parent = self.main_outline;
		BackgroundTransparency = 0.6;
		Position = dim2(0, 2, 0, 24);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -4, 1, -48);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 0, 0),
		Visible = false,
	}); cfg.page = Page

	library:create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal;
		HorizontalFlex = Enum.UIFlexAlignment.Fill;
		Parent = Page;
		Padding = dim(0, 2);
		SortOrder = Enum.SortOrder.LayoutOrder;
		VerticalFlex = Enum.UIFlexAlignment.Fill
	});

	library:create("UIPadding", {
		PaddingTop = dim(0, 2);
		PaddingBottom = dim(0, 2);
		Parent = Page;
		PaddingRight = dim(0, 2);
		PaddingLeft = dim(0, 2)
	});
	-- 
	-- 

	function cfg.open_tab() 
		local selected_tab = self.selected_tab

		if selected_tab then 
			selected_tab[1].Visible = false 
			selected_tab[2].TextColor3 = rgb(170, 170, 170)

			selected_tab = nil 
		end

		Page.Visible = true
		tab_button.TextColor3 = rgb(255, 255, 255)

		self.selected_tab = {Page, tab_button}

		cfg.on_click()
	end

	function cfg.change_visibility(self, visible)
		tab_button.Visible = visible
		cfg.visible = visible
	end

	cfg.visible = true

	tab_button.MouseButton1Down:Connect(function()
		cfg.open_tab()
	end)

	if not self.selected_tab then 
		cfg.open_tab(true) 
	end

	return setmetatable(cfg, library)    
end 

local notifications = {notifs = {}} 

library.sgui = library:create("ScreenGui", {
	Name = "Hi",
	Parent = gethui() 
})

function notifications:refresh_notifs() 
	for i, v in notifications.notifs do 
		local Position = vec2(50, 50)
		tween_service:Create(v, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = dim_offset(Position.X, Position.Y + (i * 30))}):Play()
	end
end

function notifications:fade(path, is_fading)
	local fading = is_fading and 1 or 0 

	tween_service:Create(path, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = fading}):Play()

	for _, instance in path:GetDescendants() do 
		if not instance:IsA("GuiObject") then 
			if instance:IsA("UIStroke") then
				tween_service:Create(instance, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Transparency = fading}):Play()
			end

			continue
		end 

		if instance:IsA("TextLabel") then
			tween_service:Create(instance, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextTransparency = fading}):Play()
		elseif instance:IsA("Frame") then
			tween_service:Create(instance, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = instance.Transparency and 0.6 and is_fading and 1 or 0.6}):Play()
		end
	end
end 

library.hitLogGui = library:create("ScreenGui", {
    Name = "HitLogs",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = gethui()
})

library.logContainer = library:create("Frame", {
    Name = "LogContainer",
    Size = UDim2.new(0, 0, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.X,
    Parent = library.hitLogGui
})

library:create("UIListLayout", {
    Name = "UiListLayout",
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
    Parent = library.logContainer
})

library.activeNotifications = 0

function library:spawnLog(text)
	local identity = getidentity()
	setidentity(8)
    local logFrame = library:create("Frame", {
        Name = "LogFrame",
        Size = UDim2.new(0, 0, 0, 22),
        BackgroundColor3 = Color3.fromRGB(32, 32, 32),
        BackgroundTransparency = 0.5,
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        Parent = library.logContainer
    })

	local scale = library:create("UIScale", {
		Parent = logFrame,
		Scale = 0
	})

	tween_service:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 1}):Play()

	library.activeNotifications += 1
	local notifId = library.activeNotifications

    library:create("UIPadding", {
        Name = "UiPadding",
        PaddingTop = UDim.new(0, 1),
        PaddingBottom = UDim.new(0, 1),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 64),
        Parent = logFrame
    })

    library:create("UIGradient", {
        Name = "MainGradient",
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.0822943, 0),
            NumberSequenceKeypoint.new(0.366584, 0.0375),
            NumberSequenceKeypoint.new(0.51995, 0.19375),
            NumberSequenceKeypoint.new(0.75187, 0.2875),
            NumberSequenceKeypoint.new(0.840399, 0.66875),
            NumberSequenceKeypoint.new(0.9202, 0.85625),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Parent = logFrame
    })

    local textLabel = library:create("TextLabel", {
        Name = "Segments",
        Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 3, 0, 0),
        BackgroundTransparency = 1,
		TextStrokeTransparency = 1,
        ZIndex = 5,
        AutomaticSize = Enum.AutomaticSize.X,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        RichText = true,
        FontFace = fonts.ProggyClean,
        Parent = logFrame
    })

    local accentBar = library:create("Frame", {
        Name = "AccentBar",
        Position = UDim2.new(0, -6, 0, 0),
        Size = UDim2.new(0, 8, 1, 0),
        BackgroundColor3 = themes.preset.button_alt,
        BorderSizePixel = 0,
        LayoutOrder = 3,
        Parent = logFrame
    })

    library:create("UIGradient", {
        Name = "AccentGradient",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), 
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.527431, 0),
            NumberSequenceKeypoint.new(0.599751, 1),
            NumberSequenceKeypoint.new(1, 1)
        }),
        Parent = accentBar
    })

    local topBorder = library:create("Frame", {
        Name = "TopBorder",
        Position = UDim2.new(0, -5, 0, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
		BackgroundTransparency = 0.4,
        Parent = logFrame
    })

    local bottomBorder = library:create("Frame", {
        Name = "BottomBorder",
        Position = UDim2.new(0, -5, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
		BackgroundTransparency = 0.4,
        Parent = logFrame
    })

    local borderSequence = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.0822943, 0),
        NumberSequenceKeypoint.new(0.713217, 0),
        NumberSequenceKeypoint.new(0.75187, 0.2875),
        NumberSequenceKeypoint.new(0.840399, 0.66875),
        NumberSequenceKeypoint.new(0.9202, 0.85625),
        NumberSequenceKeypoint.new(1, 1)
    })

    library:create("UIGradient", { Name = "TopGrad", Transparency = borderSequence, Parent = topBorder })
    library:create("UIGradient", { Name = "BottomGrad", Transparency = borderSequence, Parent = bottomBorder })

    task.spawn(function()
		run.RenderStepped:Wait()
		local timeWaiting = 7
		repeat
			timeWaiting -= run.RenderStepped:Wait()
		until (timeWaiting <= 0 or (library.activeNotifications - notifId) > 20)
		library.activeNotifications -= 1
		tween_service:Create(bottomBorder, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		tween_service:Create(topBorder, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		tween_service:Create(accentBar, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		tween_service:Create(logFrame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
		tween_service:Create(textLabel, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
		tween_service:Create(textLabel, TweenInfo.new(1.05, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(-2, 0, 0)}):Play()
        task.delay(1.0, game.Destroy, logFrame)
    end)
	setidentity(identity)
end

function notifications:create_notification(options)
	local cfg = {
		name = options.name or "Hit: q3sm (finobe) in the Head for 100 Damage!",
		outline; 
	}

	-- Instances
	local outline = library:create("Frame", {
		Parent = library.sgui;
		Position = dim_offset(-50, 50 + (#notifications.notifs * 30)); -- origin (dependant on the watermark position rn)
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0, 0, 0, 24);
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	local dark = library:create("Frame", {
		Parent = outline;
		BackgroundTransparency = 1;
		Position = dim2(0, 2, 0, 2);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -4, 1, -4);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 0, 0)
	});

	library:create("UIPadding", {
		PaddingTop = dim(0, 7);
		PaddingBottom = dim(0, 6);
		Parent = dark;
		PaddingRight = dim(0, 7);
		PaddingLeft = dim(0, 4)
	});

	library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = dark;
		Size = dim2(0, 0, 1, 0);
		Position = dim2(0, 1, 0, -1);
		BackgroundTransparency = 1;
		TextXAlignment = Enum.TextXAlignment.Left;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	}); 

	library:create("UIGradient", {
		Color = rgbseq{
			rgbkey(0, themes.preset["1"]), 
			rgbkey(0.5, themes.preset["2"]),
			rgbkey(1, themes.preset["3"]),
		};
		Parent = outline
	});
	-- 

	local index = #notifications.notifs + 1
	notifications.notifs[index] = outline

	notifications:refresh_notifs()
	tween_service:Create(outline, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {AnchorPoint = vec2(0, 0)}):Play()

	notifications:fade(outline, false)

	task.spawn(function()
		task.wait(3)

		notifications.notifs[index] = nil

		notifications:fade(outline, true)

		task.wait(3)

		outline:Destroy() 
	end)
end

function library:watermark(options)
	local cfg = {
		name = options.name or "nebulahax";
	}

	-- Instances
	local outline = library:create("Frame", {
		Parent = library.sgui;
		Position = dim2(0, 50, 0, 50); 
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0, 0, 0, 24);
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		BackgroundColor3 = rgb(255, 255, 255)
	}); library.watermark_outline = outline; library:draggify(outline);

	local dark = library:create("Frame", {
		Parent = outline;
		BackgroundTransparency = 0.6;
		Position = dim2(0, 2, 0, 2);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -4, 1, -4);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 0, 0)
	});

	library:create("UIPadding", {
		PaddingTop = dim(0, 7);
		PaddingBottom = dim(0, 6);
		Parent = dark;
		PaddingRight = dim(0, 7);
		PaddingLeft = dim(0, 4)
	});

	local text_title = library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = dark;
		Size = dim2(0, 0, 1, 0);
		Position = dim2(0, 1, 0, -1);
		BackgroundTransparency = 1;
		TextXAlignment = Enum.TextXAlignment.Left;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	}); 

	library:create("UIGradient", {
		Color = rgbseq{
			rgbkey(0, themes.preset["1"]), 
			rgbkey(0.5, themes.preset["2"]),
			rgbkey(1, themes.preset["3"]),
		};
		Parent = outline
	});
	--

	function cfg.update_text(text)
		text_title.Text = text
	end

	cfg.update_text(cfg.name)

	return setmetatable(cfg, library)
end 

--local watermark = library:watermark({name = "priv9 - 100 fps - 100 ping"})
local fps = 0
local watermark_delay = tick() 

--[[
run.RenderStepped:Connect(function()
	fps += 1

	if tick() - watermark_delay > 1 then 
		watermark_delay = tick()
		local ping = math.floor(stats.PerformanceStats.Ping:GetValue()) .. "ms"                
		watermark.update_text(string.format("priv9 - fps: %s - ping: %s", fps, ping))
		fps = 0
	end
end)
]]

        --[[
        	local pingTimeSec = game.Players.LocalPlayer:GetNetworkPing()
	local pingTimeMs = pingTimeSec * 1000
	pingLabel.Text = "Ping: " .. tostring(math.floor(pingTimeMs)) .. "ms"

	local realFPS = workspace:GetRealPhysicsFPS()
	fpsLabel.Text = "FPS: " .. tostring(math.floor(realFPS))
        ]]

function library:column(properties)
	self.count += 1
	local base = self

	local cfg = {color = library.gradient.Color.Keypoints[self.count].Value, count = self.count} 

	local scrolling_frame = library:create("ScrollingFrame", {
		ScrollBarImageColor3 = rgb(0, 0, 0);
		Active = true;
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ScrollBarThickness = 0;
		Parent = self.page;
		LayoutOrder = -1;
		BackgroundTransparency = 1;
		ScrollBarImageTransparency = 1;
		BorderColor3 = rgb(0, 0, 0);
		BackgroundColor3 = rgb(0, 0, 0);
		BorderSizePixel = 0;
		CanvasSize = dim2(0, 0, 0, 0)
	}); cfg.column = scrolling_frame

	function cfg:destroy()
		self.count -= 1
		scrolling_frame:Destroy()
		table.clear(cfg)
	end

	library:create("UIListLayout", {
		Parent = scrolling_frame;
		Padding = dim(0, 5);
		SortOrder = Enum.SortOrder.LayoutOrder
	});

	return setmetatable(cfg, library)            
end 

function library:multisection(properties)
    local cfg = {
        name = properties.name or "multisection",
        sections = properties.sections or {"tab"},
        size = properties.size or 1,
        autofill = properties.auto_fill or false,
        count = self.count,
        color = self.color,
        tabs = {},
        active_tab = nil
    }

    -- 1. Main Container
    local accent = library:create("Frame", {
        Parent = self.column;
        ClipsDescendants = true;
        BorderColor3 = rgb(0, 0, 0);
        BorderSizePixel = 0;
        BackgroundColor3 = self.color;
        Size = cfg.autofill and dim2(1, 0, cfg.size, 0) or dim2(1, 0, 0, 0);
    }); library:apply_theme(accent, tostring(self.count), "BackgroundColor3");

    -- Re-adding 2px UICorner
    library:create("UICorner", {
        Parent = accent,
        CornerRadius = dim(0, 2)
    })

    -- 2. Tab Bar (Shifted to Right)
    local tab_holder = library:create("Frame", {
        Parent = accent,
        Size = dim2(1, 0, 0, 18),
        Position = dim2(0, 0, 0, 0), 
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    })

    library:create("UIListLayout", {
        Parent = tab_holder,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, -- Buttons now on the right
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = dim(0, 0) 
    })

    -- 3. Sliding Bar (Visual Indicator)
    local sliding_bar = library:create("Frame", {
        Parent = tab_holder,
        -- Sized based on buttons
        Size = dim2(1 / #cfg.sections, 0, 0, 1),
        -- Initial position needs to account for Right alignment
        -- If aligned right, the first button is at: 1 - (total_tabs * tab_width)
        Position = dim2(1 - (1 / #cfg.sections * #cfg.sections), 0, 1, -1),
        BackgroundColor3 = self.color,
        BorderSizePixel = 0,
        ZIndex = 5
    }); library:apply_theme(sliding_bar, tostring(self.count), "BackgroundColor3");

    -- 4. Content Container
    local dark = library:create("Frame", {
        Parent = accent;
        BackgroundTransparency = 0.6;
        Position = dim2(0, 2, 0, 19);
        BorderColor3 = rgb(0, 0, 0);
        Size = dim2(1, -4, 0, 0); 
        BorderSizePixel = 0;
        ClipsDescendants = true; 
        BackgroundColor3 = rgb(0, 0, 0)
    });

    -- Re-adding 2px UICorner to inner box
    library:create("UICorner", {
        Parent = dark,
        CornerRadius = dim(0, 2)
    })

    for i, tab_name in ipairs(cfg.sections) do
        local but = library:create("TextButton", {
            Parent = tab_holder,
            -- Buttons are sized to fit their fraction of the total width
            Size = dim2(1 / #cfg.sections, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = tab_name:lower(),
            TextColor3 = (i == 1) and rgb(255, 255, 255) or rgb(155, 155, 155),
            FontFace = fonts["TahomaBold"],
            TextSize = 12,
            AutoButtonColor = false,
            BorderSizePixel = 0
        })

        local content = library:create("Frame", {
            Parent = dark,
            Size = dim2(1, 0, 1, 0), 
            Position = dim2(i == 1 and 0 or 1, 0, 0, 0), 
            BackgroundTransparency = 1,
            Visible = (i == 1),
        })

        local padding_cont = library:create("Frame", {
            Parent = content,
            Size = dim2(1, -10, 0, 0),
            Position = dim2(0, 5, 0, 5),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y
        })

        local layout = library:create("UIListLayout", {
            Parent = padding_cont,
            Padding = dim(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local function update_height()
            if cfg.active_tab == tab_name then
                local content_height = math.ceil(layout.AbsoluteContentSize.Y) + 10
                dark.Size = dim2(1, -4, 0, content_height)
                accent.Size = dim2(1, 0, 0, content_height + 21)
            end
        end

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update_height)

        local tab_api = setmetatable({
            elements = padding_cont,
            button = but,
            index = i,
            container = content,
            update_height = update_height,
            column = self.column,
            count = self.count,
            color = self.color
        }, { __index = library })

        cfg.tabs[tab_name] = tab_api

		local tween
		local busy = 0
        but.MouseButton1Click:Connect(function()
            if cfg.active_tab == tab_name then return end
			if busy > 0 then return end
            
            cfg.active_tab = tab_name
            local target_tab = cfg.tabs[tab_name]
            local t_info = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            
            local bar_x = 1 - ((#cfg.sections - i + 1) * (1 / #cfg.sections))
            
            tween_service:Create(sliding_bar, t_info, {
                Position = dim2(bar_x, 0, 1, -1)
            }):Play()

			busy += 3

            for _, t in pairs(cfg.tabs) do
                local is_active = (t == target_tab)
                local target_x = (t.index < target_tab.index) and -1 or (t.index > target_tab.index) and 1 or 0
                
                if is_active then t.container.Visible = true end

                tween = tween_service:Create(t.container, t_info, {
                    Position = dim2(target_x, 0, 0, 0)
                })
                tween:Play()
                
                tween.Completed:Connect(function()
                    if not is_active then t.container.Visible = false end
					busy -= 1
                end)

                tween_service:Create(t.button, TweenInfo.new(0.25), {
                    TextColor3 = is_active and rgb(255, 255, 255) or rgb(155, 155, 155)
                }):Play()
            end
            update_height()
        end)

        if i == 1 then cfg.active_tab = tab_name end
    end

    task.spawn(function()
        task.wait()
        if cfg.active_tab and cfg.tabs[cfg.active_tab] then
            cfg.tabs[cfg.active_tab].update_height()
        end
    end)

    function cfg:get_tab(name)
        return cfg.tabs[name]
    end

    return cfg
end

function library:section(properties)            
	local cfg = {
		name = properties.name or properties.Name or "section",
		size = properties.size or 1, 
		autofill = properties.auto_fill or false,
		count = self.count;
		color = self.color;
	}

	-- Instances
	local accent = library:create("Frame", {
		Parent = self.column;
		ClipsDescendants = true;
		BorderColor3 = rgb(0, 0, 0);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	}); library:apply_theme(fill, tostring(self.count), "BackgroundColor3");

	function cfg.show_element(bool)
		accent.Visible = bool
	end

	function cfg:destroy()
		accent:Destroy()
		table.clear(cfg)
	end

	local dark = library:create("Frame", {
		Parent = accent;
		BackgroundTransparency = 0.6;
		Position = dim2(0, 2, 0, 16);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -4, 1, -18);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 0, 0)
	});

	if themes.corners then
		library:create("UICorner", {
			Parent = accent,
			CornerRadius = UDim.new(0, 2)
		})

	end

	local elements = library:create("Frame", {
		Parent = dark;
		Position = dim2(0, 4, 0, 5);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -8, 0, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	}); cfg.elements = elements

	if cfg.autofill == false then 
		elements.AutomaticSize = Enum.AutomaticSize.Y;
		accent.AutomaticSize = Enum.AutomaticSize.Y;
		accent.Size = dim2(1, 0, 0, 0);

		local UIPadding = library:create("UIPadding", {
			Parent = elements,
			Name = "",
			PaddingBottom = dim(0, 7)
		})
	else 
		accent.Size = dim2(1, 0, cfg.size, 0);
	end

	library:create("UIListLayout", {
		Parent = elements;
		Padding = dim(0, 6);
		SortOrder = Enum.SortOrder.LayoutOrder
	});

	local title = library:create("TextLabel", {
		FontFace = fonts["TahomaBold"];
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = accent;
		Size = dim2(1, 0, 0, 0);
		Position = dim2(0, 4, 0, 1);
		BackgroundTransparency = 1;
		TextXAlignment = Enum.TextXAlignment.Left;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.Y;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	function cfg.set_title(self, bool)
		title.Text = bool
	end

	library:create("UIListLayout", {
		Parent = ScrollingFrame;
		Padding = dim(0, 5);
		SortOrder = Enum.SortOrder.LayoutOrder
	});
	--

	return setmetatable(cfg, library)
end 

do
	local layover = Instance.new("ScreenGui")
	local frame = Instance.new("Frame")
	local label = Instance.new("TextLabel")
	local pad = Instance.new("UIPadding")
	local corner = Instance.new("UICorner")

	layover.Name = "layover"
	layover.Parent = gethui()
	layover.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	layover.ResetOnSpawn = false
	layover.DisplayOrder = 100000

	frame.Name = "frame"
	frame.Parent = layover
	frame.BackgroundColor3 = rgb(20, 20, 20)
	frame.BorderColor3 = rgb(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.AutomaticSize = Enum.AutomaticSize.XY

	label.Name = "label"
	label.Parent = frame
	label.BackgroundColor3 = rgb(255, 255, 255)
	label.BackgroundTransparency = 1.000
	label.BorderColor3 = rgb(0, 0, 0)
	label.BorderSizePixel = 0
	label.FontFace = fonts["ProggyClean"]
	label.TextColor3 = rgb(255, 255, 255)
	label.TextSize = 12.000
	label.AutomaticSize = Enum.AutomaticSize.XY

	pad.Name = "pad"
	pad.Parent = frame
	pad.PaddingBottom = UDim.new(0, 7)
	pad.PaddingLeft = UDim.new(0, 7)
	pad.PaddingRight = UDim.new(0, 7)
	pad.PaddingTop = UDim.new(0, 7)

	--corner.CornerRadius = UDim.new(0, 6)
	--corner.Name = "corner"
	--corner.Parent = frame

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = themes.preset.button_alt
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.ZIndex = 11

	local grad = Instance.new("UIGradient", stroke)
	grad.Rotation = 90
	grad.Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155))

	for i = 1, 10 do
		local stroke = stroke:Clone()
		stroke.Parent = frame
		stroke.Transparency = i / 10
		stroke.ZIndex -= 1
		stroke.Thickness = 1 + i / 3
		stroke.Color = stroke.Color:Lerp(rgb(), i / 20)
	end

	local grad = Instance.new("UIGradient", label)
	grad.Rotation = 90
	grad.Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155))

	frame.Visible = true
	local scale = Instance.new("UIScale", frame)
	scale.Scale = 0.0

	local tween

	local current_position
	label:GetPropertyChangedSignal("TextBounds"):Connect(function()
		if not current_position then return end
		frame.Position = UDim2.new(0, current_position.X - label.TextBounds.X / 2, 0, current_position.Y)
	end)
	show_tooltip = function(enabled, text, pos)
		if tween then tween:Cancel() end
		tween = tween_service:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Scale = enabled and 1.0 or 0.0
		})
		tween:Play()
		label.Text = text
		frame.Position = UDim2.new(0, pos.X - label.TextBounds.X / 2, 0, pos.Y)
		current_position = pos

	end
end


library.animations = {}
function library:create_tween(obj, info, prop)
	if library.animations[obj] then
		library.animations[obj]:Cancel()
		library.animations[obj] = nil
	end

	local tween = tween_service:Create(obj, TweenInfo.new(table.unpack(info)), prop)
	tween:Play()

	if not library.animations[obj] then
		library.animations[obj] = tween
	end
end
-- Elements  

function library:label(options) 
    local cfg = {
        name = options.name or "Label",
        popout = options.popout or false, -- Enabled for sub-items
        wip = options.wip,
        beta = options.beta,
        color = self.color,
    }

    local is_beta = seraphAcc.role == "contributor" or seraphAcc.role == "beta"
    local clr = options.unsafe and rgb(210, 215, 192) or rgb(255, 255, 255)

    if is_beta and cfg.beta then
        clr = hex("#e67e22")
    elseif not is_beta and cfg.beta then
        clr = hex("#e67e22"):lerp(rgb(0, 0, 0), .2)
    end

    -- Main Container
    local label_element = library:create("Frame", {
        Parent = self.elements;
        BackgroundTransparency = 1;
        Size = dim2(1, 0, 0, 12);
        BorderSizePixel = 0;
    });

    cfg.instance = label_element

    local nameplate = library:create("TextLabel", {
        FontFace = library.font;
        TextColor3 = clr;
        Text = cfg.name;
        Parent = label_element;
        Size = dim2(0, 0, 1, 0);
        Position = dim2(0, 1, 0, -1);
        BackgroundTransparency = 1;
        TextXAlignment = Enum.TextXAlignment.Left;
        BorderSizePixel = 0;
        TextTransparency = (options.wip or (not is_beta and cfg.beta)) and 0.5 or 0,
        AutomaticSize = Enum.AutomaticSize.X;
        TextSize = 12;
    });

    -- Tooltip logic remains identical
    if options.tip then
        local question = library:create("TextLabel", {
            FontFace = library.font;
            Text = '?';
            Parent = nameplate;
            Size = dim2(0, 0, 1, 0);
            Position = dim2(1, 3, 0, -3);
            BackgroundTransparency = 1;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 8;
            TextColor3 = clr,
        });
        question.MouseEnter:Connect(function() show_tooltip(true, options.tip, question.AbsolutePosition - vec2(0, 30)) end)
        question.MouseLeave:Connect(function() show_tooltip(false, options.tip, question.AbsolutePosition - vec2(0, 30)) end)
    end

    local right_holder = library:create("Frame", {
        Parent = label_element,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
    })

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalAlignment = Enum.HorizontalAlignment.Right;
        Parent = right_holder;
        Padding = dim(0, 4);
        SortOrder = Enum.SortOrder.LayoutOrder
    });

    -- POPOUT LOGIC (FOR SUB-ITEMS)
    local popout_elements;
    if cfg.popout then
        local gear = library:create("ImageButton", {
            Name = "Gear",
            Parent = right_holder,
            Size = dim2(0, 14, 0, 14),
            Position = dim2(0, 0, -3, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://7059346373",
            ImageColor3 = rgb(200, 200, 200),
            LayoutOrder = 1
        })

        popout_elements = library:create("Frame", {
            Name = "PopoutMenu",
            Parent = library.gui,
            BackgroundColor3 = rgb(1, 1, 1),
            BorderColor3 = self.color,
            BorderSizePixel = 1,
            Position = dim2(1, 10, 0, 0),
            Size = dim2(0, 160, 0, 0),
            Visible = false,
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 100
        })

        local scale = library:create("UIScale", { Parent = popout_elements, Scale = 0.0 })
        library:create("UIListLayout", { Parent = popout_elements, Padding = dim(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
        library:create("UICorner", { Parent = popout_elements, CornerRadius = dim(0, 4) })
        local stroke = library:create("UIStroke", { Parent = popout_elements, Color = themes.preset.button_alt, Thickness = 1 })
        library:create("UIPadding", { Parent = popout_elements, PaddingTop = dim(0, 4), PaddingBottom = dim(0, 4), PaddingLeft = dim(0, 4), PaddingRight = dim(0, 4) })

        local visible = false
        local function update_position()
            popout_elements.Position = dim2(0, label_element.AbsolutePosition.X + label_element.AbsoluteSize.X / 2, 0, label_element.AbsolutePosition.Y + label_element.AbsoluteSize.Y * 2 + 60)
        end

        local tween, scale_tween;
        local function animate()
            if tween then tween:Cancel() end
            if scale_tween then scale_tween:Cancel() end
            stroke.Color = visible and themes.preset.button or themes.preset.button_alt
            tween = tween_service:Create(gear, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Rotation = visible and 90 or 0,
                ImageTransparency = visible and 0 or 0.5
            })
            tween:Play()

            scale_tween = tween_service:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
                Scale = visible and 1 or 0
            })
            scale_tween:Play()
        end

        animate()

        gear.MouseButton1Click:Connect(function()
            update_position()
            visible = not visible
            popout_elements.Visible = true
            animate()

            if not visible then return end

            local mouse_con
            mouse_con = uis.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if (not library:mouse_in_frame(popout_elements)) and (not library:mouse_in_frame(gear)) then
                        visible = false
                        mouse_con:Disconnect()
                        animate()
                    end
                end
            end)

            local loop_con;
            loop_con = run.RenderStepped:Connect(function()
                if not visible then loop_con:Disconnect() return end
                update_position()
            end)
        end)
    end

    function cfg:add(element_instance)
        if typeof(element_instance) == "table" then
            element_instance = element_instance.instance
        end
        if popout_elements and element_instance then
            element_instance.Parent = popout_elements
        end
        return element_instance
    end

    function cfg:set_text(val)
        nameplate.Text = val
    end

    return setmetatable(cfg, library)
end

function library:toggle(options) 
    local cfg = {
        enabled = options.enabled or nil,
        name = options.name or "Toggle",
        flag = options.flag or tostring(math.random(1,9999999)),
        default = options.default or false,
        popout = options.popout or false,
        wip = options.wip,
        beta = options.beta,
        callback = options.callback or function() end,
        color = self.color,
        count = self.count,
    }

    local is_beta = seraphAcc.role == "contributor" or seraphAcc.role == "beta"
    local clr = options.unsafe and rgb(210, 215, 192) or rgb(255, 255, 255)

    if is_beta and cfg.beta then
        clr = hex("#e67e22")
    elseif not is_beta and cfg.beta then
        clr = hex("#e67e22"):lerp(rgb(0, 0, 0), .2)
    end

    -- Main Container
    local toggle = library:create("TextButton", {
        Parent = self.elements;
        BackgroundTransparency = 1;
        Text = "";
        Size = dim2(1, 0, 0, 12);
        BorderSizePixel = 0;
    });

	cfg.instance = toggle

    local nameplate = library:create("TextLabel", {
        FontFace = library.font;
        TextColor3 = clr;
        Text = cfg.name;
        Parent = toggle;
        Size = dim2(0, 0, 1, 0);
        Position = dim2(0, 1, 0, -1);
        BackgroundTransparency = 1;
        TextXAlignment = Enum.TextXAlignment.Left;
        BorderSizePixel = 0;
        TextTransparency = (options.wip or (not is_beta and cfg.beta)) and 0.5 or 0,
        AutomaticSize = Enum.AutomaticSize.X;
        TextSize = 12;
    });

    -- Tooltip Logic
    if options.tip then
        local question = library:create("TextLabel", {
            FontFace = library.font;
            Text = '?';
            Parent = nameplate;
            Size = dim2(0, 0, 1, 0);
            Position = dim2(1, 3, 0, -3);
            BackgroundTransparency = 1;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 8;
            TextColor3 = clr,
        });
        question.MouseEnter:Connect(function() show_tooltip(true, options.tip, question.AbsolutePosition - vec2(0, 30)) end)
        question.MouseLeave:Connect(function() show_tooltip(false, options.tip, question.AbsolutePosition - vec2(0, 30)) end)
    end

    local right_holder = library:create("Frame", {
        Parent = toggle,
        Size = dim2(1, 0, 1, 0),
        BackgroundTransparency = 1,
    })

    library:create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalAlignment = Enum.HorizontalAlignment.Right;
        Parent = right_holder;
        Padding = dim(0, 4);
        SortOrder = Enum.SortOrder.LayoutOrder
    });

    -- THE GEARBOX & POPOUT
    local popout_elements;
    if cfg.popout then
        local gear = library:create("ImageButton", {
            Name = "Gear",
            Parent = right_holder,
            Size = dim2(0, 14, 0, 14),
            Position = dim2(0, 0, -3, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://7059346373",
            ImageColor3 = rgb(200, 200, 200),
            LayoutOrder = 1
        })

        popout_elements = library:create("Frame", {
            Name = "PopoutMenu",
            Parent = library.gui,
            BackgroundColor3 = rgb(1, 1, 1),
            BorderColor3 = self.color,
            BorderSizePixel = 1,
            Position = dim2(1, 10, 0, 0),
            Size = dim2(0, 160, 0, 0),
            Visible = false,
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 100
        })

        local scale = library:create("UIScale", { Parent = popout_elements, Scale = 0.0 })
        library:create("UIListLayout", { Parent = popout_elements, Padding = dim(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
        library:create("UICorner", { Parent = popout_elements, CornerRadius = dim(0, 4) })
        local stroke = library:create("UIStroke", { Parent = popout_elements, Color = themes.preset.button_alt, Thickness = 1 })
        library:create("UIPadding", { Parent = popout_elements, PaddingTop = dim(0, 4), PaddingBottom = dim(0, 4), PaddingLeft = dim(0, 4), PaddingRight = dim(0, 4) })

        local visible = false
        local function update_position()
            popout_elements.Position = dim2(0, toggle.AbsolutePosition.X + toggle.AbsoluteSize.X / 2, 0, toggle.AbsolutePosition.Y + toggle.AbsoluteSize.Y * 2 + 60)
        end

		local tween, scale_tween;
        local function animate()
			if tween then tween:Cancel() end
			if scale_tween then scale_tween:Cancel() end
			stroke.Color = visible and themes.preset.button or themes.preset.button_alt
            tween = tween_service:Create(gear, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Rotation = visible and 90 or 0,
                ImageTransparency = visible and 0 or 0.5
            })
            tween:Play()

            scale_tween = tween_service:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
                Scale = visible and 1 or 0
            })
            scale_tween:Play()
        end

		animate()

        local mouse_con
        gear.MouseButton1Click:Connect(function()
            update_position()
            visible = not visible
            popout_elements.Visible = true
            animate()

            if not visible then 
                if mouse_con then mouse_con:Disconnect() end
                return 
            end

            mouse_con = uis.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if (not library:mouse_in_frame(popout_elements)) and (not library:mouse_in_frame(gear)) then
                        visible = false
                        mouse_con:Disconnect()
                        animate()
                    end
                end
            end)

            local loop_con;
            loop_con = run.RenderStepped:Connect(function()
                if not visible then loop_con:Disconnect() return end
				if not library.gui_visible then loop_con:Disconnect() visible = false mouse_con:Disconnect() animate() return end
                update_position()
            end)
        end)
    end

	--print(options.name)
	--print(self.count)
    -- THE CHECKBOX
    local accent = library:create("Frame", {
        Parent = right_holder;
        Size = dim2(0, 12, 0, 12);
        BorderSizePixel = 0;
        BackgroundColor3 = self.color,
        LayoutOrder = 2
    }); library:apply_theme(accent, tostring(self.count), "BackgroundColor3");     

    local fill = library:create("Frame", {
        Parent = accent;
        Position = dim2(0, 1, 0, 1);
        Size = dim2(1, -2, 1, -2);
        BorderSizePixel = 0;
        BackgroundColor3 = self.color;
		ClipsDescendants = true;
    }); library:apply_theme(fill, tostring(self.count), "BackgroundColor3");  

    local c = (options.wip or (not is_beta and cfg.beta)) and 0.5 or 0.0
    library:create("UIGradient", {
        Parent = fill, Rotation = 90,
        Transparency = NumberSequence.new(math.lerp(c, 0, 0.25), c),
        Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155), rgb(155, 155, 155), rgb(177, 177, 177), rgb(55, 55, 55))
    })

    -- Functionality
    function cfg.set(bool)       
        if cfg.wip or (cfg.beta and not is_beta) then return end           
        local backgroundColor3 = bool and themes.preset.button or themes.preset.inline
		pcall(function() fill:SetAttribute("buttonPrimary", bool) end)
        fill.BackgroundColor3 = backgroundColor3
        fill.BackgroundTransparency = bool and 0 or 1
        flags[cfg.flag] = bool
        cfg.enabled = bool
        cfg.callback(bool)
    end 

    function cfg.show_element(bool)
        toggle.Visible = bool
    end

    function cfg.set_value(bool)
        cfg.set(bool)
    end

    toggle.MouseButton1Click:Connect(function()
        cfg.set(not cfg.enabled)
    end)

    -- MANUAL PARENTING METHOD
    function cfg:add(element_instance)
		if typeof(element_instance) == "table" then
			element_instance = element_instance.instance
		end
        if popout_elements and element_instance then
            element_instance.Parent = popout_elements
        end
    end

	library.config_flags[cfg.flag] = cfg.set_value

    cfg.set(cfg.default)
    return setmetatable(cfg, library) -- NO SETMETATABLE (Prevents Cyclic Error)
end

function library:list(options)
	local cfg = {
		callback = options and options.callback or function() end, 
		name = options.name or nil, 

		scale = options.size or 90, 
		items = options.items or {"1", "2", "3"}, 
		-- order = options.order or 1, 
		visible = options.visible or true,

		option_instances = {}, 
		current_instance = nil, 
		flag = options.flag or "SET A FLAG U n", 
	}

	-- Elements
	local accent = library:create("Frame", {
		BorderColor3 = rgb(0, 0, 0);
		AnchorPoint = vec2(1, 0);
		Parent = self.elements;
		Position = dim2(1, 0, 0, 0);
		Size = dim2(1, 0, 0, cfg.scale);
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundColor3 = self.color
	}); library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

	function cfg:destroy()
		accent:Destroy()
		table.clear(cfg)
	end

	function cfg.show_element(bool)
		accent.Visible = bool
	end

	local inline = library:create("Frame", {
		Parent = accent;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BackgroundColor3 = rgb(),
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	}); library:apply_theme(inline, "inline", "BackgroundColor3")

	local scrollingframe = library:create("ScrollingFrame", {
		ScrollBarImageColor3 = rgb(0, 0, 0);
		Active = true;
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ScrollBarThickness = 0;
		Parent = inline;
		Size = dim2(1, 0, 1, 0);
		LayoutOrder = -1;
		BackgroundTransparency = 1;
		ScrollBarImageTransparency = 1;
		BorderColor3 = rgb(0, 0, 0);
		BackgroundColor3 = rgb(0, 0, 0);
		BorderSizePixel = 0;
		CanvasSize = dim2(0, 0, 0, 0)
	});

	library:create("UIGradient", {
		Parent = inline;
		Rotation = 90,
		Color = rgbseq(rgb(255, 255, 255), rgb(188, 188, 188))
	})

	library:create("UIListLayout", {
		Parent = scrollingframe;
		Padding = dim(0, 6);
		SortOrder = Enum.SortOrder.LayoutOrder
	});

	library:create("UIPadding", {
		PaddingTop = dim(0, 2);
		PaddingBottom = dim(0, 4);
		Parent = scrollingframe;
		PaddingRight = dim(0, 5);
		PaddingLeft = dim(0, 5)
	});
	-- 

	-- Functions
	function cfg.render_option(text) 
		local text = library:create("TextButton", {
			FontFace = library.font;
			TextColor3 = rgb(170, 170, 170);
			BorderColor3 = rgb(0, 0, 0);
			Text = text;
			AutoButtonColor = false;
			BackgroundTransparency = 1;
			Parent = scrollingframe;
			BorderSizePixel = 0;
			Size = dim2(1, 0, 0, 0);
			AutomaticSize = Enum.AutomaticSize.Y;
			TextSize = 12;
			TextXAlignment = Enum.TextXAlignment.Left;
			BackgroundColor3 = rgb(255, 255, 255)
		}); 

		return text 
	end 

	function cfg.refresh_options(options)
		for _, v in cfg.option_instances do 
			v:Destroy() 
		end 

		for _, option in next, options do 
			local button = cfg.render_option(option) 

			insert(cfg.option_instances, button)

			button.MouseButton1Click:Connect(function()
				if cfg.current_instance and cfg.current_instance ~= button then 
					cfg.current_instance.TextColor3 = rgb(170, 170, 170)
				end 

				cfg.current_instance = button
				button.TextColor3 = rgb(255, 255, 255) 

				flags[cfg.flag] = button.text

				cfg.callback(button.text)
			end)
		end 
	end

	function cfg.filter_options(text)
		for _, v in next, cfg.option_instances do 
			if string.find(v.Text, text) then 
				v.Visible = true 
			else 
				v.Visible = false
			end
		end
	end

	function cfg.set(value)
		for _, buttons in next, cfg.option_instances do 
			if buttons.Text == value then 
				buttons.TextColor3 = rgb(255, 255, 255) 
			else 
				buttons.TextColor3 = rgb(170, 170, 170)
			end 
		end 

		flags[cfg.flag] = value
		cfg.callback(value)
	end 

	cfg.refresh_options(cfg.items) 
	-- 

	return setmetatable(cfg, library)
end     

function library:slider(options) 
	local cfg = {
		name = options.name or nil,
		suffix = options.suffix or "",
		flag = options.flag or tostring(2^789),
		callback = options.callback or function() end, 

		min = options.min or options.minimum or 0,
		max = options.max or options.maximum or 100,
		intervals = options.interval or options.decimal or 1,
		default = options.default or 10,
		value = options.default or 10, 

		ignore = options.ignore or false, 
		dragging = false,
	} 

	local is_beta = seraphAcc.role == "contributor" or seraphAcc.role == "beta"

	local clr = options.unsafe and rgb(210, 215, 192) or rgb(255, 255, 255)

	local is_active = is_beta and options.beta

	if is_beta and options.beta then
		clr = hex("#e67e22")
	elseif not is_beta and options.beta then
		clr = hex("#e67e22"):lerp(rgb(0, 0, 0), .2)
	end

	-- Instances 
	local slider = library:create("Frame", {
		Parent = self.elements;
		BackgroundTransparency = 1;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 0, 25);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});
	
	cfg.instance = slider

	function cfg.show_element(bool)
		slider.Visible = bool
	end

	function cfg:destroy()
		slider:Destroy()
		table.clear(cfg)
	end

	local eeeee = library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = rgb(255, 255, 255);
		RichText = true;
		BorderColor3 = rgb(0, 0, 0);
		Text = "max distance : 5000";
		Parent = slider;
		TextColor3 = clr,
		Size = dim2(1, 0, 0, 0);
		Position = dim2(0, 1, 0, -2);
		BackgroundTransparency = 1;
		TextXAlignment = Enum.TextXAlignment.Left;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.XY;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	local outline = library:create("TextButton", {
		Parent = slider;
		Text = "";
		AutoButtonColor = false;
		Position = dim2(0, 0, 0, 13);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 0, 12);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	}); library:apply_theme(outline, tostring(self.count), "BackgroundColor3")

	local slider_color = themes.preset.button
	if is_beta and options.beta then
		slider_color = hex("#e67e22")
	elseif not is_beta and options.beta then
		slider_color = hex("#e67e22"):lerp(rgb(0, 0, 0), .2)
	end

	local inline = library:create("Frame", {
		Parent = outline;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	}); library:apply_theme(outline, "inline", "BackgroundColor3")

	library:create("UIGradient", {
		Parent = inline;
		Rotation = 90,
		Color = rgbseq(rgb(255, 255, 255), rgb(222, 222, 222))
	})


	local accent = library:create("Frame", {
		Parent = inline;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0.5, 0, 1, 0);
		BorderSizePixel = 0;
		BackgroundColor3 = slider_color
	}); --library:apply_theme(accent, tostring(self.count), "BackgroundColor3")
	accent:SetAttribute("buttonPrimary", true)

	library:create("UIGradient", {
		Parent = accent;
		Rotation = 90,
		Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155))
	})

	if themes.corners then
		library:create("UICorner", {
			Parent = outline,
			CornerRadius = UDim.new(0, 2)
		})

		library:create("UICorner", {
			Parent = inline,
			CornerRadius = UDim.new(0, 2)
		})

		library:create("UICorner", {
			Parent = accent,
			CornerRadius = UDim.new(0, 2)
		})

		library:create("UICorner", {
			Parent = slider,
			CornerRadius = UDim.new(0, 2)
		})
	end


	-- 

	-- Functions 
	function cfg.set(value)
		local valuee = tonumber(value)

		if valuee == nil then 
			return 
		end 

		cfg.value = clamp(library:round(valuee, cfg.intervals), cfg.min, cfg.max)

		accent.Size = dim2((cfg.value - cfg.min) / (cfg.max - cfg.min), 0, 1, 0)
		eeeee.Text = cfg.name ..  "<font color='#AAAAAA'>" .. ' - ' .. tostring(cfg.value) .. cfg.suffix .. "</font>"

		flags[cfg.flag] = cfg.value

		cfg.callback(flags[cfg.flag])
	end 

	cfg.set(cfg.default)
	-- 

	-- Connections
	outline.MouseButton1Down:Connect(function()
		cfg.dragging = true 
	end)

	library:connection(uis.InputChanged, function(input)
		if cfg.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then 
			local size_x = (input.Position.X - inline.AbsolutePosition.X) / inline.AbsoluteSize.X
			local value = ((cfg.max - cfg.min) * size_x) + cfg.min

			cfg.set(value)
		end
	end)

	library:connection(uis.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			cfg.dragging = false 
		end 
	end)
	-- 

	cfg.set(cfg.default)

	config_flags[cfg.flag] = cfg.set

	return setmetatable(cfg, library)
end 

function library:dropdown(options) 
	local cfg = {
		name = options.name or nil,
		flag = options.flag or tostring(random(1,9999999)),
		items = options.items or {""},
		callback = options.callback or function() end,
		multi = options.multi or false, 
		scrolling = true, 

		-- Ignore these 
		open = false, 
		option_instances = {}, 
		multi_items = {}, 
		ignore = options.ignore or false, 
	}   

	options.scrolling = true

	cfg.default = options.default or (cfg.multi and {cfg.items[1]}) or cfg.items[1] or "None"

	flags[cfg.flag] = {} 

	-- Instances
	-- Element 
	local dropdown = library:create("Frame", {
		Parent = self.elements;
		BackgroundTransparency = 1;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 0, 16);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	cfg.instance = dropdown

	function cfg.show_element(bool)
		dropdown.Visible = bool
	end

	function cfg:destroy()
		dropdown:Destroy()
		table.clear(cfg)
	end

	local dropdown_holder = library:create("TextButton", {
		AnchorPoint = vec2(1, 0);
		AutoButtonColor = false; 
		Text = "";
		BackgroundColor3 = rgb();
		Parent = dropdown;
		Position = dim2(1, 0, 0, 0);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0.5, 0, 0, 16);
		BorderSizePixel = 0;
		--BackgroundColor3 = self.color
	}); library:apply_theme(dropdown_holder, tostring(self.count), "BackgroundColor3")

	local inline = library:create("Frame", {
		Parent = dropdown_holder;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	});

	local is_beta = seraphAcc.role == "contributor" or seraphAcc.role == "beta"

	local clr = options.unsafe and rgb(210, 215, 192) or rgb(255, 255, 255)

	local is_active = is_beta and options.beta

	if is_beta and options.beta then
		clr = hex("#e67e22")
	elseif not is_beta and options.beta then
		clr = hex("#e67e22"):lerp(rgb(0, 0, 0), .2)
	end

	local text = library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = clr,
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = inline;
		Size = dim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		Position = dim2(0, 0, 0, 1);
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});


	local title = library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = clr,
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = dropdown;
		Size = dim2(1, 0, 1, 0);
		Position = dim2(0, 1, 0, 0);
		BackgroundTransparency = 1;
		TextXAlignment = Enum.TextXAlignment.Left;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	library:create("UIGradient", {
		Parent = inline;
		Rotation = 90,
		Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155))
	})


	if themes.corners then
		library:create("UICorner", {
			Parent = inline,
			CornerRadius = UDim.new(0, 2)
		})

		library:create("UICorner", {
			Parent = dropdown_holder,
			CornerRadius = UDim.new(0, 2)
		})
	end

	-- 

	-- Holder
	local accent = library:create("Frame", {
		Parent = library.gui;
		Size = dim2(0.0907348021864891, 0, 0.006218905560672283, 20);
		Position = dim2(0, 500, 0, 100);
		BorderColor3 = rgb(0, 0, 0);
		BorderSizePixel = 0;
		Visible = false;
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundColor3 = self.color,
		ZIndex = 50000
	});	library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

	local inline_overlay = library:create("Frame", {
		Parent = accent;
		Size = dim2(1, -2, 1, -2);
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		BorderSizePixel = 0;
		Active = false,
		BackgroundColor3 = themes.preset.inline,
		ZIndex = 50005
	});	library:apply_theme(inline_overlay, "inline", "BackgroundColor3")

	library:create("UIGradient", {
		Parent = inline_overlay;
		Rotation = 90,
		Transparency = numseq({numkey(0, 1), numkey(0.7, 1), numkey(1, 0.5)}),
		Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155))
	})

	local maxInlineSize = 200
	local inline = library:create(cfg.scrolling and "ScrollingFrame" or "Frame", {
		Parent = accent;
		Size = dim2(1, -2, 1, -2);
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		BorderSizePixel = 0;
		AutomaticSize = cfg.scrolling and Enum.AutomaticSize.None or Enum.AutomaticSize.Y;
		BackgroundColor3 = themes.preset.inline,
		ZIndex = 50000
	});	library:apply_theme(inline, "inline", "BackgroundColor3")

	library:create("UIGradient", {
		Parent = inline;
		Rotation = 90,
		Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155))
	})

	library:create("UIListLayout", {
		Parent = inline;
		Padding = dim(0, 6);
		SortOrder = Enum.SortOrder.LayoutOrder
	});

	library:create("UIPadding", {
		PaddingTop = dim(0, 5);
		PaddingBottom = dim(0, 2);
		Parent = inline;
		PaddingRight = dim(0, 6);
		PaddingLeft = dim(0, 6)
	});

	local padding = library:create("UIPadding", {
		PaddingBottom = dim(0, 2);
		Parent = accent
	});
	--  
	-- 

	-- Functions

	local currentSize = 0
	function cfg.render_option(text) 
		local title = library:create("TextButton", {
			FontFace = library.font;
			AutoButtonColor = false;
			TextColor3 = clr;
			BorderColor3 = rgb(0, 0, 0);
			Text = string.lower(text);
			Parent = inline;
			Size = dim2(1, 0, 0, 0);
			Position = dim2(0, 0, 0, 1);
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			BackgroundColor3 = rgb(),
			BorderSizePixel = 0;
			AutomaticSize = Enum.AutomaticSize.Y;
			TextSize = 12;
		});

		if cfg.scrolling then
			currentSize += title.AbsoluteSize.Y + 6
			inline.Size = UDim2.new(1, -2, 0, clamp(currentSize, 0, maxInlineSize) + title.AbsoluteSize.Y / 2)
			inline.CanvasSize = UDim2.new(0, 0, 0, currentSize + title.AbsoluteSize.Y)
			inline.ScrollBarThickness = 1
		end

		inline_overlay.Size = inline.Size

		title.Name = text

		return title
	end 

	function cfg.set_visible(bool) 
		accent.Visible = bool
		local currentSize = 0
		for i, title in next, cfg.option_instances do 
			currentSize += title.AbsoluteSize.Y + 6
			inline.Size = UDim2.new(1, -2, 0, clamp(currentSize, 0, maxInlineSize) + title.AbsoluteSize.Y / 2)
			inline.CanvasSize = UDim2.new(0, 0, 0, currentSize + title.AbsoluteSize.Y)
			inline.ScrollBarThickness = 1
		end
	end

	function cfg.set(value)
		local selected = {}
		local isTable = type(value) == "table"

		if value == nil then 
			return 
		end

		for _, option in next, cfg.option_instances do 
			if option.Name == value or (isTable and find(value, option.Name)) then 
				insert(selected, option.Name)
				cfg.multi_items = selected
				option.TextColor3 = clr
			else
				option.TextColor3 = clr:Lerp(rgb(), .23)
			end
		end

		inline_overlay.Size = inline.Size

		text.Text = if isTable then concat(selected, ", ") else selected[1]
		text.Text = string.lower(text.Text)
		text.TextTruncate = Enum.TextTruncate.AtEnd

		flags[cfg.flag] = if isTable then selected else selected[1]

		cfg.callback(flags[cfg.flag]) 
	end

	function cfg.refresh_options(list) 
		for _, option in next, cfg.option_instances do 
			option:Destroy() 
		end

		cfg.option_instances = {} 

		for _, option in next, list do 
			local button = cfg.render_option(option)

			insert(cfg.option_instances, button)

			button.MouseButton1Down:Connect(function()
				if cfg.multi then 
					local selected_index = find(cfg.multi_items, button.Name)

					if selected_index then 
						remove(cfg.multi_items, selected_index)
					else
						insert(cfg.multi_items, button.Name)
					end

					cfg.set(cfg.multi_items) 				
				else 
					cfg.set_visible(false)
					cfg.open = false 

					cfg.set(button.Name)
				end
			end)
		end
	end

	cfg.refresh_options(cfg.items)

	cfg.set(cfg.default)

	config_flags[cfg.flag] = cfg.set
	-- 

	-- Connections 
	dropdown_holder.MouseButton1Click:Connect(function()
		cfg.open = not cfg.open 

		local currentSize = 0
		for i, title in next, cfg.option_instances do 
			currentSize += title.AbsoluteSize.Y + 6 * i
			inline.Size = UDim2.new(1, -2, 0, clamp(currentSize, 0, maxInlineSize) + title.AbsoluteSize.Y)
			inline.CanvasSize = UDim2.new(0, 0, 0, currentSize + title.AbsoluteSize.Y)
			inline.ScrollBarThickness = 1
		end
		accent.Size = dim2(0, dropdown_holder.AbsoluteSize.X, 0, accent.Size.Y.Offset)
		accent.Position = dim2(0, dropdown_holder.AbsolutePosition.X, 0, dropdown_holder.AbsolutePosition.Y + 77)

		cfg.set_visible(cfg.open)
	end)

	local inputEndedFunc = function(input)
		if not cfg.open then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not (library:mouse_in_frame(accent) or library:mouse_in_frame(dropdown)) then 
				cfg.open = false
				cfg.set_visible(false)
			end
		end
	end
	local inputEndedSig = uis.InputEnded:Connect(inputEndedFunc)
	inputEndedSig:Disconnect()
	-- 

	library.guiVisibilityChanged:Connect(function()
		cfg.set_visible(false)
		if library.gui_visible then inputEndedSig = uis.InputEnded:Connect(inputEndedFunc) else inputEndedSig:Disconnect() inputEndedSig = nil end
	end)

	return setmetatable(cfg, library)
end 

function library:colorpicker(options) 
	local cfg = {
		name = options.name or "Color", 
		flag = options.flag or tostring(2^789),

		color = options.color or color(1, 1, 1), -- Default to white color if not provided
		alpha = options.alpha and 1 - options.alpha or 0,

		open = false, 
		callback = options.callback or function() end,
	}

	-- Instances
	-- Element
	local colorpicker_element = library:create("TextButton", {
		Parent = self.elements;
		BackgroundTransparency = 1;
		Text = "";
		AutoButtonColor = false;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 0, 12);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	cfg.instance = colorpicker_element

	function cfg:destroy()
		colorpicker_element:Destroy()
		table.clear(cfg)
	end

	local accent = library:create("Frame", {
		AnchorPoint = vec2(1, 0);
		Parent = colorpicker_element;
		Position = dim2(1, 0, 0, 0);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0, 30, 0, 12);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	}); library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

	local colorpicker_element_color = library:create("Frame", {
		Parent = accent;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	library:create("UIGradient", {
		Parent = colorpicker_element_color;
		Rotation = 90,
		Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155))
	})


	if themes.corners then
		library:create("UICorner", {
			Parent = colorpicker_element_color,
			CornerRadius = UDim.new(0, 2)
		})

		library:create("UICorner", {
			Parent = accent,
			CornerRadius = UDim.new(0, 2)
		})
	end

	library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = colorpicker_element;
		Size = dim2(1, 0, 1, 0);
		Position = dim2(0, 1, 0, 0);
		BackgroundTransparency = 1;
		TextXAlignment = Enum.TextXAlignment.Left;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	-- 

	-- Elements
	local colorpicker = library:create("Frame", {
		Parent = library.gui;
		ZIndex = 50000,
		Position = dim2(0.6888179183006287, 0, 0.24751244485378265, 0);
		BorderColor3 = rgb(0, 0, 0);
		Visible = false;
		Size = dim2(0, 150, 0, 150);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	});	library:apply_theme(colorpicker, tostring(self.count), "BackgroundColor3")

	library:create("UICorner", {
		Parent = colorpicker;
		CornerRadius = UDim.new(0, 2)
	});

	local a = library:create("Frame", {
		Parent = colorpicker;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 1, 0);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	}); library:apply_theme(a, tostring(self.count), "BackgroundColor3")

	local e = library:create("Frame", {
		Parent = a;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 0, 0);
		BackgroundTransparency = 0.6;
		ZIndex = -1
	}); 

	local _ = library:create("UIPadding", {
		PaddingTop = dim(0, 7);
		PaddingBottom = dim(0, -13);
		Parent = e;
		PaddingRight = dim(0, 6);
		PaddingLeft = dim(0, 7)
	});

	local textbox_holder = library:create("Frame", {
		Parent = e;
		Position = dim2(0, 0, 1, -36);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -1, 0, 16);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	}); library:apply_theme(textbox_holder, tostring(self.count), "BackgroundColor3")

	local textbox = library:create("TextBox", {
		FontFace = library.font;
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = "";
		Parent = textbox_holder;
		BackgroundTransparency = 0;
		ClearTextOnFocus = false;
		PlaceholderColor3 = rgb(255, 255, 255);
		Size = dim2(1, -2, 1, -2);
		Position = dim2(0, 1, 0, 1);
		BorderSizePixel = 0;
		TextSize = 12;
		TextXAlignment = Enum.TextXAlignment.Center;
		BackgroundColor3 = themes.preset.inline
	}); library:apply_theme(textbox, "inline", "BackgroundColor3")

	local hue_button = library:create("TextButton", {
		AnchorPoint = vec2(1, 0);
		Text = "";
		AutoButtonColor = false;
		Parent = e;
		Position = dim2(1, -1, 0, 0);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0, 14, 1, -60);
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	}); library:apply_theme(hue_button, "inline", "BackgroundColor3")

	local hue_drag = library:create("Frame", {
		Parent = hue_button;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	library:create("UIGradient", {
		Rotation = -90;
		Parent = hue_drag;
		Color = rgbseq{rgbkey(0, rgb(255, 0, 0)), rgbkey(0.17, rgb(255, 255, 0)), rgbkey(0.33, rgb(0, 255, 0)), rgbkey(0.5, rgb(0, 255, 255)), rgbkey(0.67, rgb(0, 0, 255)), rgbkey(0.83, rgb(255, 0, 255)), rgbkey(1, rgb(255, 0, 0))}
	});

	local hue_picker = library:create("Frame", {
		Parent = hue_drag;
		BorderMode = Enum.BorderMode.Inset;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 2, 0, 3);
		Position = dim2(0, -1, 0, -1);
		BackgroundColor3 = rgb(255, 255, 255)
	});

	local alpha_button = library:create("TextButton", {
		AnchorPoint = vec2(0, 0.5);
		Text = "";
		AutoButtonColor = false;
		Parent = e;
		Position = dim2(0, 0, 1, -48);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -1, 0, 14);
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	}); library:apply_theme(alpha_button, "inline", "BackgroundColor3")

	local alpha_color = library:create("Frame", {
		Parent = alpha_button;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 221, 255)
	});

	local alphaind = library:create("ImageLabel", {
		ScaleType = Enum.ScaleType.Tile;
		BorderColor3 = rgb(0, 0, 0);
		Parent = alpha_color;
		Image = "rbxassetid://18274452449";
		BackgroundTransparency = 1;
		Size = dim2(1, 0, 1, 0);
		TileSize = dim2(0, 4, 0, 4);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	library:create("UIGradient", {
		Parent = alphaind;
		Rotation = 180;
		Transparency = numseq{numkey(0, 0), numkey(1, 1)}
	});

	local alpha_picker = library:create("Frame", {
		Parent = alpha_color;
		BorderMode = Enum.BorderMode.Inset;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0, 3, 1, 2);
		Position = dim2(0, -1, 0, -1);
		BackgroundColor3 = rgb(255, 255, 255)
	});

	local saturation_value_button = library:create("TextButton", {
		Parent = e;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -20, 1, -60);
		Text = "";
		AutoButtonColor = false;
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	}); library:apply_theme(saturation_value_button, "inline", "BackgroundColor3")

	local colorpicker_color = library:create("Frame", {
		Parent = saturation_value_button;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 221, 255)
	});

	local val = library:create("TextButton", {
		Parent = colorpicker_color;
		Text = "";
		AutoButtonColor = false;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 1, 0);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	library:create("UIGradient", {
		Parent = val;
		Transparency = numseq{numkey(0, 0), numkey(1, 1)}
	});

	local saturation_value_picker = library:create("Frame", {
		Parent = colorpicker_color;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0, 3, 0, 3);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(0, 0, 0)
	});

	local inline = library:create("Frame", {
		Parent = saturation_value_picker;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	local saturation_button = library:create("TextButton", {
		Parent = colorpicker_color;
		Text = "";
		AutoButtonColor = false;
		Size = dim2(1, 0, 1, 0);
		BorderColor3 = rgb(0, 0, 0);
		ZIndex = 2;
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	library:create("UIGradient", {
		Rotation = 270;
		Transparency = numseq{numkey(0, 0), numkey(1, 1)};
		Parent = saturation_button;
		Color = rgbseq{rgbkey(0, rgb(0, 0, 0)), rgbkey(1, rgb(0, 0, 0))}
	});


	-- 
	-- 

	-- Functions 
	local dragging_sat = false 
	local dragging_hue = false 
	local dragging_alpha = false 

	local h, s, v = cfg.color:ToHSV() 
	local a = cfg.alpha 

	flags[cfg.flag] = {} 

	function cfg.set_visible(bool) 
		colorpicker.Visible = bool

		colorpicker.Position = dim_offset(colorpicker_element_color.AbsolutePosition.X - 1, colorpicker_element_color.AbsolutePosition.Y + colorpicker_element_color.AbsoluteSize.Y + 65)
	end

	function cfg.show_element(bool)
		colorpicker_element.Visible = bool
	end

	function cfg.set(color, alpha)
		if color then
			h, s, v = color:ToHSV()
		end

		if alpha then 
			a = alpha
		end 

		local Color = Color3.fromHSV(h, s, v)

		hue_picker.Position = dim2(0, -1, 1 - h, -1)
		alpha_picker.Position = dim2(1 - a, -1, 0, -1)
		saturation_value_picker.Position = dim2(s, -1, 1 - v, -1)

		--element_alpha.ImageTransparency = 1 - a

		alpha_color.BackgroundColor3 = Color
		colorpicker_element_color.BackgroundColor3 = Color
		colorpicker_color.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

		flags[cfg.flag] = {
			Color = Color;
			Transparency = a 
		}

		local color = colorpicker_element_color.BackgroundColor3
		textbox.Text = string.format("%s, %s, %s, ", library:round(color.R * 255), library:round(color.G * 255), library:round(color.B * 255))
		textbox.Text ..= library:round(1 - a, 0.01)

		cfg.callback(Color, a)
	end

	function cfg.update_color() 
		local mouse = uis:GetMouseLocation() 
		local offset = vec2(mouse.X, mouse.Y - gui_offset) 

		if dragging_sat then	
			s = math.clamp((offset - saturation_value_button.AbsolutePosition).X / saturation_value_button.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((offset - saturation_value_button.AbsolutePosition).Y / saturation_value_button.AbsoluteSize.Y, 0, 1)
		elseif dragging_hue then
			h = 1 - math.clamp((offset - hue_button.AbsolutePosition).Y / hue_button.AbsoluteSize.Y, 0, 1)
		elseif dragging_alpha then
			a = 1 - math.clamp((offset - alpha_button.AbsolutePosition).X / alpha_button.AbsoluteSize.X, 0, 1)
		end

		cfg.set(nil, nil)
	end

	cfg.set(cfg.color, cfg.alpha)

	config_flags[cfg.flag] = cfg.set
	-- 

	-- Connections 
	colorpicker_element.MouseButton1Click:Connect(function()
		cfg.open = not cfg.open 

		cfg.set_visible(cfg.open)            
	end)

	uis.InputChanged:Connect(function(input)
		if (dragging_sat or dragging_hue or dragging_alpha) and input.UserInputType == Enum.UserInputType.MouseMovement then
			cfg.update_color() 
		end
	end)

	library:connection(uis.InputEnded, function(input)
		if not cfg.open then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging_sat = false
			dragging_hue = false
			dragging_alpha = false  

			if not (library:mouse_in_frame(colorpicker_element) or library:mouse_in_frame(colorpicker)) then 
				cfg.open = false
				cfg.set_visible(false)
			end
		end
	end)

	alpha_button.MouseButton1Down:Connect(function()
		dragging_alpha = true 
	end)

	hue_button.MouseButton1Down:Connect(function()
		dragging_hue = true 
	end)

	saturation_button.MouseButton1Down:Connect(function()
		dragging_sat = true  
	end)

	textbox.FocusLost:Connect(function()
		local s, hex = pcall(hex, textbox.Text)
		if hex and s then
			local r, g, b = floor(hex.R * 255), floor(hex.G * 255), floor(hex.B * 255)
			cfg.set(rgb(r, g, b), cfg.alpha)
			return
		end

		local r, g, b, a = library:convert(textbox.Text)

		if not a then
			a = 1
		end

		if r and g and b and a then 
			cfg.set(rgb(r, g, b), 1 - a)
		end 
	end)

	library.guiVisibilityChanged:Connect(function()
		cfg.set_visible(false)
	end)
	-- 

	return setmetatable(cfg, library)
end

function library:textbox(options) 
	local cfg = {
		name = options.name or "...",
		placeholder = options.placeholder or options.placeholdertext or options.holder or options.holdertext or "type here...",
		default = options.default,
		flag = options.flag or "SET ME rawr",
		callback = options.callback or function() end,
		visible = options.visible or true,
	}

	-- Instances 
	local frame = library:create("TextButton", {
		AnchorPoint = vec2(1, 0);
		Text = "";
		AutoButtonColor = false;
		Parent = self.elements;
		Position = dim2(1, 0, 0, 0);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 0, 16);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	});

	local frame_inline = library:create("Frame", {
		Parent = frame;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	});

	local input = library:create("TextBox", {
		Parent = frame,
		Name = "",
		FontFace = library.font,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextSize = 12,
		Size = dim2(1, -6, 1, 0),
		RichText = true,
		TextColor3 = rgb(255, 255, 255),
		BorderColor3 = rgb(0, 0, 0),
		CursorPosition = -1,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = dim2(0, 6, 0, 0),
		BorderSizePixel = 0,
		PlaceholderColor3 = rgb(170, 170, 170),
	})
	-- 

	-- Functions
	function cfg:destroy()
		frame:Destroy()
		table.clear(cfg)
	end

	function cfg.set(text) 
		flags[cfg.flag] = text

		input.Text = text

		cfg.callback(text)
	end 

	config_flags[cfg.flag] = cfg.set

	if cfg.default then 
		cfg.set(cfg.default) 
	end
	--

	-- Connections 
	input:GetPropertyChangedSignal("Text"):Connect(function()
		cfg.set(input.Text) 
	end)
	-- 

	return setmetatable(cfg, library)
end 

local keybinds = {}
function library:keybind(options) 
	local cfg = {
		flag = options.flag or "SET ME A FLAG NOWWW!!!!",
		callback = options.callback or function() end,
		open = false,
		binding = nil, 
		name = options.name or nil, 
		ignore_key = options.ignore or false, 

		key = options.key or nil, 
		display = options.display or nil,
		mode = options.mode or "hold",
		active = options.default or false,
		text = Drawing.new("Text"),

		hold_instances = {},
	}

	insert(keybinds, cfg)

	flags[cfg.flag] = {} 

	-- Instances
	-- Element 
	local keybind = library:create("Frame", {
		Parent = self.elements;
		BackgroundTransparency = 1;
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 0, 16);
		BorderSizePixel = 0;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	cfg.instance = keybind

	function cfg:destroy()
		keybind:Destroy()
		table.clear(cfg)
	end

	function cfg.show_element(bool)
		keybind.Visible = bool
	end

	local keybind_holder = library:create("TextButton", {
		AnchorPoint = vec2(1, 0);
		AutoButtonColor = false; 
		Text = "";
		Parent = keybind;
		BackgroundTransparency = 1;
		Position = dim2(1, 0, 0, 0);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(0.5, 0, 0, 16);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	}); library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

	local inline = library:create("Frame", {
		Parent = keybind_holder;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		BackgroundTransparency = 1;
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	});

	library:create("UIGradient", {
		Parent = inline;
		Rotation = 90,
		Color = rgbseq(rgb(255, 255, 255), rgb(155, 155, 155))
	})

	local text = library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = inline;
		Size = dim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		Position = dim2(0, 0, 0, -1);
		TextColor3 = rgb(221, 221, 221),
		BorderSizePixel = 0;
		TextXAlignment = Enum.TextXAlignment.Right;
		AutomaticSize = Enum.AutomaticSize.X;
		TextSize = 10;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	local title = library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = keybind;
		Size = dim2(0, 0, 1, 0);
		Position = dim2(0, 1, 0, 0);
		BackgroundTransparency = 1;
		TextXAlignment = Enum.TextXAlignment.Left;
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		TextColor3 = options.unsafe and rgb(210, 215, 192) or rgb(255, 255, 255),
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});

	if options.tip then
		--87959697501504
		local question = library:create("TextLabel", {
			FontFace = library.font;
			TextColor3 = title.TextColor3;
			BorderColor3 = rgb(0, 0, 0);
			Text = '?';
			Parent = title;
			Size = dim2(0, 0, 1, 0);
			Position = dim2(1, 3, 0, -3);
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			BorderSizePixel = 0;
			TextTransparency = (options.wip or (not is_beta and cfg.beta)) and 0.5 or 0,
			AutomaticSize = Enum.AutomaticSize.X;
			TextSize = 8;
			BackgroundColor3 =rgb(255, 255, 255)
		});
		question.MouseEnter:Connect(function()
			show_tooltip(true, options.tip, question.AbsolutePosition - vec2(0, 30))
		end)
		question.MouseLeave:Connect(function()
			show_tooltip(false, options.tip, question.AbsolutePosition - vec2(0, 30))
		end)
	end
	-- 

	-- Holder
	local accent = library:create("Frame", {
		Parent = library.gui;
		Visible = false;
		Size = dim2(0.0907348021864891, 0, 0.006218905560672283, 20);
		Position = dim2(0, 500, 0, 100);
		BorderColor3 = rgb(0, 0, 0);
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundColor3 = self.color;
		ZIndex = 50000
	});	library:apply_theme(accent, tostring(self.count), "BackgroundColor3")

	local inline = library:create("Frame", {
		Parent = accent;
		Size = dim2(1, -2, 1, -2);
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundColor3 = themes.preset.inline;
		ZIndex = 50000
	});	library:apply_theme(inline, "inline", "BackgroundColor3")

	library:create("UIListLayout", {
		Parent = inline;
		Padding = dim(0, 6);
		SortOrder = Enum.SortOrder.LayoutOrder
	});

	library:create("UIPadding", {
		PaddingTop = dim(0, 5);
		PaddingBottom = dim(0, 2);
		Parent = inline;
		PaddingRight = dim(0, 6);
		PaddingLeft = dim(0, 6)
	});

	local padding = library:create("UIPadding", {
		PaddingBottom = dim(0, 2);
		Parent = accent
	});

	local options = {"Hold", "Toggle", "Always"}

	for _, v in options do
		local option = library:create("TextButton", {
			FontFace = library.font;
			TextColor3 = rgb(170, 170, 170);
			BorderColor3 = rgb(0, 0, 0);
			Text = v;
			Parent = inline;
			Position = dim2(0, 0, 0, 1);
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			BorderSizePixel = 0;
			AutomaticSize = Enum.AutomaticSize.XY;
			TextSize = 12;
			BackgroundColor3 = rgb(255, 255, 255)
		}); cfg.hold_instances[v] = option

		option.MouseButton1Click:Connect(function()
			cfg.set(v)

			cfg.set_visible(false)

			cfg.open = false
		end)
	end
	--  
	--

	-- Functions 
	function cfg.modify_mode_color(path) -- ts so frikin tuff ðŸ’€
		for _, v in cfg.hold_instances do 
			v.TextColor3 = rgb(170, 170, 170)
		end

		if cfg.hold_instances[path] then 
			cfg.hold_instances[path].TextColor3 = rgb(255, 255, 255)
		end
	end 

	function cfg.set_mode(mode) 
		cfg.mode = mode 

		if mode == "Always" then
			cfg.set(true)
		elseif mode == "Hold" then
			cfg.set(false)
		end

		flags[cfg.flag]["mode"] = mode
		cfg.modify_mode_color(mode)
	end 

	function cfg.set(input)
		if type(input) == "boolean" then 
			local __cached = input 

			if cfg.mode == "Always" then 
				__cached = true 
			end 

			cfg.active = __cached 
			cfg.callback(__cached)
		elseif tostring(input):find("Enum") then 
			input = input.Name == "Escape" and "..." or input

			cfg.key = input or "..."	

			cfg.callback(cfg.active or false)
		elseif find({"Toggle", "Hold", "Always"}, input) then 
			cfg.set_mode(input)

			if input == "Always" then 
				cfg.active = true 
			end 

			cfg.callback(cfg.active or false)
		elseif type(input) == "table" then 
			input.key = type(input.key) == "string" and input.key ~= "..." and library:convert_enum(input.key) or input.key

			input.key = input.key == Enum.KeyCode.Escape and "..." or input.key
			cfg.key = input.key or "..."

			cfg.mode = input.mode or "Toggle"
			cfg.set_mode(input.mode)

			if input.active then
				cfg.active = input.active
			end
		end 

		flags[cfg.flag] = {
			mode = cfg.mode,
			key = cfg.key, 
			active = cfg.active
		}

		local _text = tostring(cfg.key) ~= "Enums" and (keys[cfg.key] or tostring(cfg.key):gsub("Enum.", "")) or nil
		local __text = _text and (tostring(_text):gsub("KeyCode.", ""):gsub("UserInputType.", ""))

		text.Text = "[".. __text .."]"

		-- if keybind_list_text then
		--     keybind_list_text.Text = "[ ".. __text  .." ] ".. cfg.name ..":".. string.lower(cfg.mode) .."";
		--     keybind_list_text.Visible = cfg.active
		-- end
	end

	function cfg.set_visible(bool)
		accent.Visible = bool

		accent.Size = dim2(0, keybind_holder.AbsoluteSize.X, 0, accent.Size.Y.Offset)
		accent.Position = dim2(0, keybind_holder.AbsolutePosition.X, 0, keybind_holder.AbsolutePosition.Y + 77)
	end
	-- 

	-- Connections
	keybind_holder.MouseButton1Down:Connect(function()
		task.wait()
		text.Text = "[-]"	

		cfg.binding = library:connection(uis.InputBegan, function(input, game_event)  
			cfg.set((input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType))

			cfg.binding:Disconnect() 
			cfg.binding = nil
		end)
	end)

	keybind_holder.MouseButton2Down:Connect(function()
		cfg.open = not cfg.open 

		cfg.set_visible(cfg.open) 
	end)

	library:connection(uis.InputBegan, function(input, game_event) 
		if not game_event then 
			if input.KeyCode == cfg.key then 
				if cfg.mode == "Toggle" then 
					cfg.active = not cfg.active
					cfg.set(cfg.active)
				elseif cfg.mode == "Hold" then 
					cfg.set(true)
				end
			elseif input.UserInputType == cfg.key then
				if cfg.mode == "Toggle" then 
					cfg.active = not cfg.active
					cfg.set(cfg.active)
				elseif cfg.mode == "Hold" then 
					cfg.set(true)
				end
			end
		end
	end)

	library:connection(uis.InputEnded, function(input, game_event) 
		if game_event then 
			return 
		end 

		local selected_key = input.UserInputType == Enum.UserInputType.Keyboard and (input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType)

		if input.KeyCode == cfg.key or input.UserInputType == cfg.key then
			if cfg.mode == "Hold" then 
				cfg.set(false)
			end
		end

		if library.gui_visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not (library:mouse_in_frame(keybind_holder) or library:mouse_in_frame(accent)) then 
				cfg.open = false
				cfg.set_visible(false)
			end
		end
	end)

	config_flags[cfg.flag] = cfg.set
	cfg.set({mode = cfg.mode, active = cfg.active, key = cfg.key})
	cfg.set_mode(cfg.mode)

	library.guiVisibilityChanged:Connect(function()
		cfg.set_visible(false)
	end)

	return setmetatable(cfg, library)
end

function library:button(options) 
	local cfg = {
		name = options.name or "button",
		callback = options.callback or function() end,
	}

	-- Instances 
	local frame = library:create("TextButton", {
		AnchorPoint = vec2(1, 0);
		Text = "";
		AutoButtonColor = false;
		Parent = self.elements;
		Position = dim2(1, 0, 0, 0);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, 0, 0, 16);
		BorderSizePixel = 0;
		BackgroundColor3 = self.color
	}); library:apply_theme(frame, tostring(self.count), "BackgroundColor3")

	local frame_inline = library:create("Frame", {
		Parent = frame;
		Position = dim2(0, 1, 0, 1);
		BorderColor3 = rgb(0, 0, 0);
		Size = dim2(1, -2, 1, -2);
		BorderSizePixel = 0;
		BackgroundColor3 = themes.preset.inline
	}); library:apply_theme(frame_inline, "inline", "BackgroundColor3")


	library:create("UIGradient", {
		Parent = frame_inline;
		Rotation = 90,
		Color = rgbseq(rgb(255, 255, 255), rgb(188, 188, 188))
	})

	if themes.corners then
		library:create("UICorner", {
			Parent = frame_inline,
			CornerRadius = UDim.new(0, 2)
		})

		library:create("UICorner", {
			Parent = frame,
			CornerRadius = UDim.new(0, 2)
		})
	end

	local text = library:create("TextLabel", {
		FontFace = library.font;
		TextColor3 = rgb(255, 255, 255);
		BorderColor3 = rgb(0, 0, 0);
		Text = cfg.name;
		Parent = frame;
		Size = dim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		Position = dim2(0, 1, 0, 1);
		BorderSizePixel = 0;
		AutomaticSize = Enum.AutomaticSize.X;
		TextSize = 12;
		BackgroundColor3 = rgb(255, 255, 255)
	});
	-- 

	-- Connections 
	frame.MouseButton1Click:Connect(function()
		cfg.callback()
	end)
	--

	function cfg:destroy()
		frame:Destroy()
		table.clear(cfg)
	end

	return setmetatable(cfg, library)
end 
-- 
-- 
-- 

local function rgbstr(rgb)
	local values = {}

	values.r = floor(rgb.r * 255)
	values.g = floor(rgb.g * 255)
	values.b = floor(rgb.b * 255)

	return `rgb({values.r},{values.g},{values.b})`
end


local function setup(obj, prop)
	for k, v in prop do
		obj[k] = v
	end
	return obj
end

local function applyMatrix(v, M)
	return Vector3.new(
		v.X * M.R00 + v.Y * M.R01 + v.Z * M.R02,
		v.X * M.R10 + v.Y * M.R11 + v.Z * M.R12,
		v.X * M.R20 + v.Y * M.R21 + v.Z * M.R22
	)
end

local function worldToScreenPoint(point)
	local cam = workspace.CurrentCamera
	local dp = cam.CFrame:PointToObjectSpace(typeof(point) == 'CFrame' and point.Position or (typeof(point) == 'Instance' and point.Position or point))
	local distorted = dp, applyMatrix(dp, globalStretch)
	local worldDistorted = cam.CFrame:PointToWorldSpace(distorted)
	local vector, onScreen = cam:WorldToViewportPoint(worldDistorted)

	return Vector2.new(vector.X, vector.Y), onScreen
end


local services = setmetatable({}, {
	__index = function(self, t)
		return game:GetService(t:gsub("^%l", string.upper))
	end,
})


pcall(game.Destroy, services.coreGui:FindFirstChild("PRIV9CHAMS"))
pcall(game.Destroy,  lighting:FindFirstChild("\233"))

local sky = Instance.new("Sky")
sky.Name = "\233"
sky.StarCount = 0
sky.MoonTextureId, sky.SunTextureId = '', ''
local skyboxes = {
	blank = {
		SkyboxBk = 'http://www.roblox.com/asset/?ID=1361097',
		SkyboxDn = 'http://www.roblox.com/asset/?ID=1361097',
		SkyboxFt = 'http://www.roblox.com/asset/?ID=1361097',
		SkyboxLf = 'http://www.roblox.com/asset/?ID=1361097',
		SkyboxRt = 'http://www.roblox.com/asset/?ID=1361097',
		SkyboxUp = 'http://www.roblox.com/asset/?ID=1361097',
		MoonTextureId = '',
		SunTextureId = '',
		StarCount = 0,
		SunAngularSize = 1
	},
	["red night sky"] = {
		SkyboxBk = 'http://www.roblox.com/Asset/?ID=401664839',
		SkyboxDn = 'http://www.roblox.com/asset/?ID=401664862',
		SkyboxFt = 'http://www.roblox.com/asset/?ID=401664960',
		SkyboxLf = 'http://www.roblox.com/asset/?ID=401664881',
		SkyboxRt = 'http://www.roblox.com/asset/?ID=401664901',
		SkyboxUp = 'http://www.roblox.com/asset/?ID=401664936',
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["purple galaxy"] = {
		SkyboxBk = 'http://www.roblox.com/Asset/?ID=14543264135',
		SkyboxDn = 'http://www.roblox.com/asset/?ID=14543358958',
		SkyboxFt = 'http://www.roblox.com/asset/?ID=14543257810',
		SkyboxLf = 'http://www.roblox.com/asset/?ID=14543275895',
		SkyboxRt = 'http://www.roblox.com/asset/?ID=14543280890',
		SkyboxUp = 'http://www.roblox.com/asset/?ID=14543371676',
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
		["purple clouds"] = {
		SkyboxLf = "rbxassetid://151165191",
		SkyboxBk = "rbxassetid://151165214",
		SkyboxDn = "rbxassetid://151165197",
		SkyboxFt = "rbxassetid://151165224",
		SkyboxRt = "rbxassetid://151165206",
		SkyboxUp = "rbxassetid://151165227",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["cloudy skies"] = {
		SkyboxLf = "rbxassetid://151165191",
		SkyboxBk = "rbxassetid://151165214",
		SkyboxDn = "rbxassetid://151165197",
		SkyboxFt = "rbxassetid://151165224",
		SkyboxRt = "rbxassetid://151165206",
		SkyboxUp = "rbxassetid://151165227",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["purple nebula"] = {
		SkyboxLf = "rbxassetid://159454286",
		SkyboxBk = "rbxassetid://159454299",
		SkyboxDn = "rbxassetid://159454296",
		SkyboxFt = "rbxassetid://159454293",
		SkyboxRt = "rbxassetid://159454300",
		SkyboxUp = "rbxassetid://159454288",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["purple and blue"] = {
		SkyboxLf = "rbxassetid://149397684",
		SkyboxBk = "rbxassetid://149397692",
		SkyboxDn = "rbxassetid://149397686",
		SkyboxFt = "rbxassetid://149397697",
		SkyboxRt = "rbxassetid://149397688",
		SkyboxUp = "rbxassetid://149397702",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["vivid Skies"] = {
		SkyboxLf = "rbxassetid://271042310",
		SkyboxBk = "rbxassetid://271042516",
		SkyboxDn = "rbxassetid://271077243",
		SkyboxFt = "rbxassetid://271042556",
		SkyboxRt = "rbxassetid://271042467",
		SkyboxUp = "rbxassetid://271077958",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["twighlight"] = {
		SkyboxLf = "rbxassetid://264909758",
		SkyboxBk = "rbxassetid://264908339",
		SkyboxDn = "rbxassetid://264907909",
		SkyboxFt = "rbxassetid://264909420",
		SkyboxRt = "rbxassetid://264908886",
		SkyboxUp = "rbxassetid://264907379",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["vaporwave"] = {
		SkyboxLf = "rbxassetid://1417494402",
		SkyboxBk = "rbxassetid://1417494030",
		SkyboxDn = "rbxassetid://1417494146",
		SkyboxFt = "rbxassetid://1417494253",
		SkyboxLf = "rbxassetid://1417494402",
		SkyboxRt = "rbxassetid://1417494499",
		SkyboxUp = "rbxassetid://1417494643",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["clouds"] = {
		SkyboxLf = "rbxassetid://570557620",
		SkyboxBk = "rbxassetid://570557514",
		SkyboxDn = "rbxassetid://570557775",
		SkyboxFt = "rbxassetid://570557559",
		SkyboxLf = "rbxassetid://570557620",
		SkyboxRt = "rbxassetid://570557672",
		SkyboxUp = "rbxassetid://570557727",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["night sky"] = {
		SkyboxBk = "rbxassetid://12064107",
		SkyboxDn = "rbxassetid://12064152",
		SkyboxFt = "rbxassetid://12064121",
		SkyboxLf = "rbxassetid://12063984",
		SkyboxRt = "rbxassetid://12064115",
		SkyboxUp = "rbxassetid://12064131",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["setting sun"] = {
		SkyboxBk = "rbxassetid://626460377",
		SkyboxDn = "rbxassetid://626460216",
		SkyboxFt = "rbxassetid://626460513",
		SkyboxLf = "rbxassetid://626473032",
		SkyboxRt = "rbxassetid://626458639",
		SkyboxUp = "rbxassetid://626460625",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["fade blue"] = {
		SkyboxBk = "rbxassetid://153695414",
		SkyboxDn = "rbxassetid://153695352",
		SkyboxFt = "rbxassetid://153695452",
		SkyboxLf = "rbxassetid://153695320",
		SkyboxRt = "rbxassetid://153695383",
		SkyboxUp = "rbxassetid://153695471",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["elegant morning"] = {
		SkyboxBk = "rbxassetid://153767241",
		SkyboxDn = "rbxassetid://153767216",
		SkyboxFt = "rbxassetid://153767266",
		SkyboxLf = "rbxassetid://153767200",
		SkyboxRt = "rbxassetid://153767231",
		SkyboxUp = "rbxassetid://153767288",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["neptune"] = {
		SkyboxBk = "rbxassetid://218955819",
		SkyboxDn = "rbxassetid://218953419",
		SkyboxFt = "rbxassetid://218954524",
		SkyboxLf = "rbxassetid://218958493",
		SkyboxRt = "rbxassetid://218957134",
		SkyboxUp = "rbxassetid://218950090",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["redshift"] = {
		SkyboxBk = "rbxassetid://401664839",
		SkyboxDn = "rbxassetid://401664862",
		SkyboxFt = "rbxassetid://401664960",
		SkyboxLf = "rbxassetid://401664881",
		SkyboxRt = "rbxassetid://401664901",
		SkyboxUp = "rbxassetid://401664936",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	},
	["aesthetic night"] = {
		SkyboxBk = "rbxassetid://1045964490",
		SkyboxDn = "rbxassetid://1045964368",
		SkyboxFt = "rbxassetid://1045964655",
		SkyboxLf = "rbxassetid://1045964655",
		SkyboxRt = "rbxassetid://1045964655",
		SkyboxUp = "rbxassetid://1045962969",
		MoonTextureId = 'rbxasset://sky/moon.jpg',
		SunTextureId = 'rbxasset://sky/sun.jpg',
		SunAngularSize = 21,
		StarCount = 1000
	}
}
sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = 'http://www.roblox.com/asset/?ID=1361097', 'http://www.roblox.com/asset/?ID=1361097', 'http://www.roblox.com/asset/?ID=1361097', 'http://www.roblox.com/asset/?ID=1361097', 'http://www.roblox.com/asset/?ID=1361097', 'http://www.roblox.com/asset/?ID=1361097'
local chamsContainer = Instance.new("ScreenGui", services.coreGui) chamsContainer.Name = "PRIV9CHAMS"
cons[#cons + 1] = players.PlayerRemoving:Connect(function(plr)
	if chamsContainer:FindFirstChild(plr.Name) then
		chamsContainer:FindFirstChild(plr.Name):Destroy()
	end
end)
local viewport = Instance.new("ViewportFrame") viewport.Size = UDim2.new(1,0,1,0) viewport.BackgroundTransparency = 1 viewport.CurrentCamera = camera viewport.Parent = library.gui
local tearParts, materialParts = {}, {}


function upperString(t)
	return t:gsub("^%l", string.upper)
end

local cf, angles, thread = CFrame.new, CFrame.Angles, task.spawn
local params = RaycastParams.new()
params.RespectCanCollide = false

local globals = {
	frametime = 0
}


local notifications = {}
function createNotification(info)
	local notif = Instance.new("Frame")
	notif.Name = "notif"
	notif.Position = UDim2.new(1, -5, 1, -5)
	notif.Size = UDim2.new(0, 500, 0, 23)
	notif.BackgroundColor3 = Color3.new(0.129412, 0.129412, 0.129412)
	notif.BorderSizePixel = 0
	notif.BorderColor3 = Color3.new(0, 0, 0)
	notif.AnchorPoint = Vector2.new(1, 1)
	notif.Parent = library.gui

	local holder = Instance.new("Frame")
	holder.Name = "holder"
	holder.Position = UDim2.new(0.5, 0, 0.5, 0)
	holder.Size = UDim2.new(1, -5, 1, -5)
	holder.BackgroundColor3 = Color3.new(0.117647, 0.117647, 0.117647)
	holder.BorderSizePixel = 0
	holder.BorderColor3 = Color3.new(0, 0, 0)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Parent = notif

	local textContainer = Instance.new("Frame")
	textContainer.Name = "textContainer"
	textContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	textContainer.Size = UDim2.new(1, -5, 1, -5)
	textContainer.BackgroundColor3 = Color3.new(0.0705882, 0.0705882, 0.0705882)
	textContainer.BackgroundTransparency = 1
	textContainer.BorderSizePixel = 0
	textContainer.BorderColor3 = Color3.new(0, 0, 0)
	textContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	textContainer.Transparency = 1
	textContainer.Parent = holder

	local start = Instance.new("TextLabel")
	start.Name = "start"
	start.Size = UDim2.new(0, 0, 0, 11)
	start.BackgroundColor3 = Color3.new(1, 1, 1)
	start.BackgroundTransparency = 1
	start.BorderSizePixel = 0
	start.BorderColor3 = Color3.new(0, 0, 0)
	start.AutomaticSize = Enum.AutomaticSize.X
	start.Text = "seraph.wtf"
	start.TextColor3 = themes.preset.button_alt
	start.TextSize = 14
	start.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	start.Parent = textContainer

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Name = "UIListLayout"
	UIListLayout.Padding = UDim.new(0, 5)
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = textContainer

	local sub = Instance.new("TextLabel")
	sub.Name = "sub"
	sub.Size = UDim2.new(0, 0, 0, 11)
	sub.BackgroundColor3 = Color3.new(1, 1, 1)
	sub.BackgroundTransparency = 1
	sub.BorderSizePixel = 0
	sub.BorderColor3 = Color3.new(0, 0, 0)
	sub.AutomaticSize = Enum.AutomaticSize.X
	sub.Text = "|"
	sub.TextColor3 = Color3.new(1, 1, 1)
	sub.TextSize = 14
	sub.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	sub.Parent = textContainer

	local real = Instance.new("TextLabel")
	real.Name = "real"
	real.Size = UDim2.new(0, 0, 0, 11)
	real.BackgroundColor3 = Color3.new(1, 1, 1)
	real.BackgroundTransparency = 1
	real.BorderSizePixel = 0
	real.BorderColor3 = Color3.new(0, 0, 0)
	real.AutomaticSize = Enum.AutomaticSize.X
	real.Text = "welcome to seraph.wtf!"
	real.TextColor3 = Color3.new(1, 1, 1)
	real.TextSize = 14
	real.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	real.Parent = textContainer

	local border = Instance.new("UIStroke")
	border.Name = "border"
	border.Transparency = 0.800000011920929
	border.Parent = holder

	local border2 = Instance.new("UIStroke")
	border2.Name = "border"
	border2.Color = Color3.new(0.129412, 0.129412, 0.129412)
	border2.LineJoinMode = Enum.LineJoinMode.Miter
	border2.Parent = notif

	local border3 = Instance.new("UIStroke")
	border3.Name = "border"
	border3.Color = Color3.new(0.143126, 0.143126, 0.143126)
	border3.Thickness = 1.5
	border3.LineJoinMode = Enum.LineJoinMode.Miter
	border3.Parent = notif

	local border4 = Instance.new("UIStroke")
	border4.Name = "border"
	border4.Color = Color3.new(0.153327, 0.153327, 0.153327)
	border4.Thickness = 2
	border4.LineJoinMode = Enum.LineJoinMode.Miter
	border4.Parent = notif

	local border5 = Instance.new("UIStroke")
	border5.Name = "border"
	border5.Color = Color3.new(0.163528, 0.163528, 0.163528)
	border5.Thickness = 2.5
	border5.LineJoinMode = Enum.LineJoinMode.Miter
	border5.Parent = notif

	local border6 = Instance.new("UIStroke")
	border6.Name = "border"
	border6.Color = Color3.new(0.173728, 0.173728, 0.173728)
	border6.Thickness = 3
	border6.LineJoinMode = Enum.LineJoinMode.Miter
	border6.Parent = notif

	local border7 = Instance.new("UIStroke")
	border7.Name = "border"
	border7.Color = Color3.new(0.183929, 0.183929, 0.183929)
	border7.Thickness = 3.5
	border7.LineJoinMode = Enum.LineJoinMode.Miter
	border7.Parent = notif

	local border8 = Instance.new("UIStroke")
	border8.Name = "border"
	border8.Color = Color3.new(0.19413, 0.19413, 0.19413)
	border8.Thickness = 4
	border8.LineJoinMode = Enum.LineJoinMode.Miter
	border8.Parent = notif

	local border9 = Instance.new("UIStroke")
	border9.Name = "border"
	border9.Color = Color3.new(0.204331, 0.204331, 0.204331)
	border9.Thickness = 4.5
	border9.LineJoinMode = Enum.LineJoinMode.Miter
	border9.Parent = notif

	local loading = Instance.new("Frame")
	loading.Name = "loading"
	loading.Size = UDim2.new(1, 0, 0, 1)
	loading.BackgroundColor3 = themes.preset.button_alt
	loading.BorderSizePixel = 0
	loading.BorderColor3 = Color3.new(0, 0, 0)
	loading.Parent = notif

	local gradient = Instance.new("UIGradient")
	gradient.Name = "gradient"
	gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.419608, 0.419608, 0.419608))})
	gradient.Rotation = 90
	gradient.Parent = loading

	local border10 = Instance.new("UIStroke")
	border10.Name = "border"
	border10.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	border10.Transparency = 0.8

	border10.Parent = loading

	local scale = Instance.new("UIScale")
	scale.Name = "scale"

	scale.Parent = notif

	task.spawn(function()
		if not info.time then
			info.time = math.clamp((#info.text / 4) / 2, 5, 50)
		end
		info.text ..= "   "
		for i = 1, #info.text do
			real.Text = string.sub(info.text, 1, i)
			start.TextColor3 = themes.preset.button_alt
			if i % 4 == 0 then
				services.runService.RenderStepped:Wait()
			end
		end
	end)

	if flags.notifSound then
		local sound = Instance.new("Sound")
		sound.SoundId = math.random() > .5 and sfx.bubble2 or sfx.bubble
		sound.Name = ""
		sound.Volume = 1
		sound.PlaybackSpeed = 1
		sound.PlayOnRemove = true
		sound.Parent = coregui
		task.defer(game.Destroy, sound)
	end

	task.defer(function()
		notif.Size = UDim2.new(0,0,0,23)

		scale.Parent = notif
		scale.Scale = 0.0


		insert(notifications, {
			time = info.time or 5,
			totalTime = info.time or info.duration or 5,
			notif = notif
		})
	end)
end

local function checkfile(dir, src)
	if not isfile(dir) then
		writefile(dir, game:HttpGetAsync(src))
	end
end

local function correctAlpha(t, dt_)
	return 1 - (1 - t) ^ (dt_ * 60)
end

local function getTimeString()
	local t=os.date"*t"
	local h=t.hour%12; if h==0 then h=12 end
	return ("%02d:%02d:%02d %s"):format(h,t.min,t.sec, t.hour>=12 and "PM" or "AM")
end

local currentText = "v01.misyn.fix"
if string.match(currentText, "replaceThisVersion") then
	currentText = "development"
end

--[[
do
	local frame = Instance.new("Frame")
	frame.Name = "frame"
	frame.Position = UDim2.new(0, 50, 0, 50)
	frame.Size = UDim2.new(0, 0, 0, 25)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.10000000149011612
	frame.BorderSizePixel = 0
	frame.BorderColor3 = Color3.new(0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.Transparency = 0.10000000149011612
	frame.Parent = library.gui

	local UICorner = Instance.new("UICorner")
	UICorner.Name = "UICorner"

	UICorner.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "icon"
	icon.Size = UDim2.new(0, 25, 0, 25)
	icon.BackgroundColor3 = Color3.new(1, 1, 1)
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.BorderColor3 = Color3.new(0, 0, 0)
	icon.Transparency = 1
	icon.Image = "rbxassetid://101942723117519"
	icon.Parent = frame

	local icon2 = Instance.new("ImageLabel")
	icon2.Name = "icon"
	icon2.Size = UDim2.new(0, 26, 0, 26)
	icon2.BackgroundColor3 = Color3.new(0.592157, 0.490196, 0.839216)
	icon2.BackgroundTransparency = 1
	icon2.BorderSizePixel = 0
	icon2.BorderColor3 = Color3.new(0, 0, 0)
	icon2.Transparency = 1
	icon2.Image = "rbxassetid://101942723117519"
	icon2.ImageColor3 = Color3.new(0.592157, 0.490196, 0.839216)
	icon2.ImageTransparency = 0.5
	icon2.Parent = icon

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Name = "UIStroke"
	UIStroke.Thickness = 2
	UIStroke.Parent = frame

	local UIStroke2 = Instance.new("UIStroke")
	UIStroke2.Name = "UIStroke"
	UIStroke2.Thickness = 2.5
	UIStroke2.Transparency = 0.25
	UIStroke2.Parent = frame

	local UIStroke3 = Instance.new("UIStroke")
	UIStroke3.Name = "UIStroke"
	UIStroke3.Thickness = 3
	UIStroke3.Transparency = 0.5
	UIStroke3.Parent = frame

	local UIStroke4 = Instance.new("UIStroke")
	UIStroke4.Name = "UIStroke"
	UIStroke4.Thickness = 4
	UIStroke4.Transparency = 0.75
	UIStroke4.Parent = frame

	local UIStroke5 = Instance.new("UIStroke")
	UIStroke5.Name = "UIStroke"
	UIStroke5.Thickness = 5
	UIStroke5.Transparency = 0.9900000095367432
	UIStroke5.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "title"
	title.Size = UDim2.new(0, 0, 0, 25)
	title.BackgroundColor3 = Color3.new(1, 1, 1)
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.BorderColor3 = Color3.new(0, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.X
	title.LayoutOrder = 1
	title.Text = "seraph"
	title.TextColor3 = Color3.new(0.956863, 0.956863, 0.956863)
	title.TextSize = 16
	title.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	title.TextWrapped = true
	title.Parent = frame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Name = "UIListLayout"
	UIListLayout.Padding = UDim.new(0, 6)
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = frame

	local version = Instance.new("TextLabel")
	version.Name = "version"
	version.Size = UDim2.new(0, 0, 0, 25)
	version.BackgroundColor3 = Color3.new(1, 1, 1)
	version.BackgroundTransparency = 1
	version.BorderSizePixel = 0
	version.BorderColor3 = Color3.new(0, 0, 0)
	version.AutomaticSize = Enum.AutomaticSize.X
	version.LayoutOrder = 4
	version.Text = currentText
	version.TextColor3 = Color3.new(0.956863, 0.956863, 0.956863)
	version.TextSize = 16
	version.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	version.TextWrapped = true
	version.Parent = frame


	local splitter = Instance.new("Frame")
	splitter.Name = "splitter"
	splitter.Size = UDim2.new(0, 10, 0, 1)
	splitter.BackgroundColor3 = Color3.new(1, 1, 1)
	splitter.BorderSizePixel = 0
	splitter.BorderColor3 = Color3.new(0, 0, 0)
	splitter.LayoutOrder = 2
	splitter.Parent = frame

	local UIGradient3 = Instance.new("UIGradient")
	UIGradient3.Name = "UIGradient"
	UIGradient3.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.501247, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)})
	UIGradient3.Parent = splitter

	local splitter2 = Instance.new("Frame")
	splitter2.Name = "splitter"
	splitter2.Size = UDim2.new(0, 10, 0, 1)
	splitter2.BackgroundColor3 = Color3.new(1, 1, 1)
	splitter2.BorderSizePixel = 0
	splitter2.BorderColor3 = Color3.new(0, 0, 0)
	splitter2.LayoutOrder = 5
	splitter2.Parent = frame

	local UIGradient4 = Instance.new("UIGradient")
	UIGradient4.Name = "UIGradient"
	UIGradient4.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.501247, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)})
	UIGradient4.Parent = splitter2

	local time = Instance.new("TextLabel")
	time.Name = "time"
	time.Size = UDim2.new(0, 0, 0, 25)
	time.BackgroundColor3 = Color3.new(1, 1, 1)
	time.BackgroundTransparency = 1
	time.BorderSizePixel = 0
	time.BorderColor3 = Color3.new(0, 0, 0)
	time.AutomaticSize = Enum.AutomaticSize.X
	time.LayoutOrder = 11
	time.Text = "4:32 am"
	time.TextColor3 = Color3.new(0.956863, 0.956863, 0.956863)
	time.TextSize = 16
	time.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	time.TextWrapped = true
	time.Parent = frame

	local vers = Instance.new("ImageLabel")
	vers.Name = "vers"
	vers.Size = UDim2.new(0, 25, 0, 25)
	vers.BackgroundColor3 = Color3.new(1, 1, 1)
	vers.BackgroundTransparency = 1
	vers.BorderSizePixel = 0
	vers.BorderColor3 = Color3.new(0, 0, 0)
	vers.Visible = false
	vers.LayoutOrder = 3
	vers.Transparency = 1
	vers.Image = "rbxassetid://91840508165296"
	vers.Parent = frame

	local frames = Instance.new("ImageLabel")
	frames.Name = "frames"
	frames.Size = UDim2.new(0, 25, 0, 25)
	frames.BackgroundColor3 = Color3.new(1, 1, 1)
	frames.BackgroundTransparency = 1
	frames.BorderSizePixel = 0
	frames.BorderColor3 = Color3.new(0, 0, 0)
	frames.Visible = false
	frames.LayoutOrder = 6
	frames.Transparency = 1
	frames.Image = "rbxassetid://12684119225"
	frames.Parent = frame

	local fps = Instance.new("TextLabel")
	fps.Name = "fps"
	fps.Size = UDim2.new(0, 0, 0, 25)
	fps.BackgroundColor3 = Color3.new(1, 1, 1)
	fps.BackgroundTransparency = 1
	fps.BorderSizePixel = 0
	fps.BorderColor3 = Color3.new(0, 0, 0)
	fps.AutomaticSize = Enum.AutomaticSize.X
	fps.LayoutOrder = 7
	fps.Text = "0 fps"
	fps.TextColor3 = Color3.new(0.956863, 0.956863, 0.956863)
	fps.TextSize = 16
	fps.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	fps.TextWrapped = true
	fps.Parent = frame


	local splitter3 = Instance.new("Frame")
	splitter3.Name = "splitter"
	splitter3.Size = UDim2.new(0, 10, 0, 1)
	splitter3.BackgroundColor3 = Color3.new(1, 1, 1)
	splitter3.BorderSizePixel = 0
	splitter3.BorderColor3 = Color3.new(0, 0, 0)
	splitter3.LayoutOrder = 8
	splitter3.Parent = frame

	local UIGradient7 = Instance.new("UIGradient")
	UIGradient7.Name = "UIGradient"
	UIGradient7.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.501247, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)})
	UIGradient7.Parent = splitter3

	local UIPadding = Instance.new("UIPadding")
	UIPadding.Name = "UIPadding"
	UIPadding.PaddingRight = UDim.new(0, 5)
	UIPadding.Parent = frame

	local splitter4 = Instance.new("Frame")
	splitter4.Name = "splitter"
	splitter4.Size = UDim2.new(0, 10, 0, 1)
	splitter4.BackgroundColor3 = Color3.new(1, 1, 1)
	splitter4.BorderSizePixel = 0
	splitter4.BorderColor3 = Color3.new(0, 0, 0)
	splitter4.LayoutOrder = 10
	splitter4.Parent = frame

	local UIGradient8 = Instance.new("UIGradient")
	UIGradient8.Name = "UIGradient"
	UIGradient8.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1, 0), NumberSequenceKeypoint.new(0.501247, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)})
	UIGradient8.Parent = splitter4

	local ping = Instance.new("TextLabel")
	ping.Name = "ping"
	ping.Size = UDim2.new(0, 0, 0, 25)
	ping.BackgroundColor3 = Color3.new(1, 1, 1)
	ping.BackgroundTransparency = 1
	ping.BorderSizePixel = 0
	ping.BorderColor3 = Color3.new(0, 0, 0)
	ping.AutomaticSize = Enum.AutomaticSize.X
	ping.LayoutOrder = 9
	ping.Text = "0 ms"
	ping.TextColor3 = Color3.new(0.956863, 0.956863, 0.956863)
	ping.TextSize = 16
	ping.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	ping.TextWrapped = true
	ping.Parent = frame

	library:draggify(frame)

	pcall(function()
		local savedFramePos = http_service:JSONDecode(readfile('seraph/configs/watermark.vector'))
		local translated = Vector2.new(savedFramePos.X, savedFramePos.Y)

		frame.Position = UDim2.new(0,translated.X,0,translated.Y)
	end)

	local fpsValue, targetFPS = 0, 0
	local pingValue, targetPing = 0, 0
	local last = os.clock()
	cons[#cons + 1] = services.runService.RenderStepped:Connect(function(dt)
		frame.Visible = flags.watermark
		if os.clock() - last > 0.25 then
			last = os.clock()
			targetFPS,targetPing = floor(1/dt),floor(services.stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			globals.ping = services.stats.Network.ServerStatsItem["Data Ping"]:GetValue()

			writefile('seraph/configs/watermark.vector', http_service:JSONEncode({
				X = frame.Position.X.Offset,
				Y = frame.Position.Y.Offset
			}))
		end
		fpsValue = math.lerp(fpsValue, targetFPS, correctAlpha(0.35, dt))
		pingValue = math.lerp(pingValue, targetPing, correctAlpha(0.35, dt))
		frame.Parent = library.gui
		fps.Text = `{floor(fpsValue)} fps`
		time.Text = getTimeString()
		ping.Text = `{floor(pingValue)} ms`
	end)
end
]]

do
	local watermark = Instance.new("ScreenGui")
	watermark.Name = "watermark"
	watermark.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	watermark.Parent = library.gui
	watermark.DisplayOrder = 9999

	local frame = Instance.new("Frame")
	frame.Name = "frame"
	frame.Position = UDim2.new(0, 5, 0, 5)
	frame.Size = UDim2.new(0, 0, 0, 25)
	frame.BackgroundColor3 = Color3.new(0.105882, 0.101961, 0.101961)
	frame.BorderSizePixel = 0
	frame.BorderColor3 = Color3.new(0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.Parent = watermark

	local outer = Instance.new("UIStroke")
	outer.Name = "outer"
	outer.Color = Color3.new(0.129412, 0.12549, 0.12549)
	outer.Thickness = 4
	outer.LineJoinMode = Enum.LineJoinMode.Miter
	outer.Parent = frame

	local outer2 = Instance.new("UIStroke")
	outer2.Name = "outer"
	outer2.Color = Color3.new(0.164706, 0.164706, 0.164706)
	outer2.Thickness = 2
	outer2.LineJoinMode = Enum.LineJoinMode.Miter
	outer2.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "label"
	label.Position = UDim2.new(0, 0, 0.5, 0)
	label.Size = UDim2.new(0, 0, 1, 0)
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.BorderColor3 = Color3.new(0, 0, 0)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Text = ""
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 12
	label.FontFace = fonts["ProggyClean"] or Font.new("rbxassetid://12187370747", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.RichText = true
	label.Parent = frame

	local outer3 = Instance.new("UIStroke")
	outer3.Name = "outer"
	outer3.Color = Color3.new(0.141176, 0.141176, 0.141176)
	outer3.Thickness = 3
	outer3.LineJoinMode = Enum.LineJoinMode.Miter
	outer3.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.Name = "pad"
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = frame

	local outer4 = Instance.new("UIStroke")
	outer4.Name = "outer"
	outer4.Color = Color3.new(0.164706, 0.164706, 0.164706)
	outer4.LineJoinMode = Enum.LineJoinMode.Miter
	outer4.Parent = frame

	local bar = Instance.new("Frame")
	bar.Name = "bar"
	bar.Position = UDim2.new(0.5, 0, 0, 0)
	bar.Size = UDim2.new(1, 8, 0, 2)
	bar.BackgroundColor3 = Color3.new(1, 0, 0)
	bar.BorderSizePixel = 0
	bar.BorderColor3 = Color3.new(0, 0, 0)
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Parent = frame

	local grad = Instance.new("UIGradient")
	grad.Name = "grad"
	grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.394015, 0, 0), NumberSequenceKeypoint.new(1, 1, 0)})
	grad.Rotation = 90
	grad.Parent = bar

	library:draggify(frame, 5)

	pcall(function()
		local savedFramePos = http_service:JSONDecode(readfile('seraph/configs/watermark.vector'))
		local translated = Vector2.new(savedFramePos.X, savedFramePos.Y)

		frame.Position = UDim2.new(0,translated.X,0,translated.Y)
	end)

	local function time12h()
		local t = os.date("*t")
		return string.format(
			"%d:%02d %s",
			(t.hour % 12 == 0 and 12 or t.hour % 12),
			t.min,
			t.hour >= 12 and "PM" or "AM"
		)
	end


	local fpsValue, targetFPS = 0, 0
	local pingValue, targetPing = 0, 0
	local last = os.clock()

	local renderFuncs = {
		uid = function()
			return `uid {seraphAcc.userid or 1}`
		end,
		fps = function()
			return `{targetFPS} fps`
		end,
		ping = function()
			return `{targetPing} ms`
		end,
		time = function()
			return `{time12h()}`
		end,
		username = function()
			return seraphAcc.username or "Unknown"
		end
	}
	local corner_text = library:create("TextLabel", {
		Size = dim2(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = dim2(1, -5, 0, 5),
		AnchorPoint = vec2(1, 0),
		BackgroundTransparency = 1,
		TextColor3 = rgb(255,255,255),
		TextStrokeTransparency = 0,
		RichText = true,
		TextSize = 11,
		Font = fonts.verdana,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = library.gui
	})
	local sine = 0
	cons[#cons + 1] = services.runService.RenderStepped:Connect(function(dt)
    if not library or not library.gui then return end
		frame.Visible = flags.watermark and (flags.watermark_style == "classic")
		sine += (dt * 60)
		corner_text.Visible = flags.watermark and (flags.watermark_style == "corner")
		if os.clock() - last > 0.85 then
			last = os.clock()
			targetFPS,targetPing = floor(1/dt),floor(services.stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			globals.ping = services.stats.Network.ServerStatsItem["Data Ping"]:GetValue()

			writefile('seraph/configs/watermark.vector', http_service:JSONEncode({
				X = frame.Position.X.Offset,
				Y = frame.Position.Y.Offset
			}))
		end
		fpsValue = math.lerp(fpsValue, targetFPS, correctAlpha(0.1, dt))
		pingValue = math.lerp(pingValue, targetPing, correctAlpha(0.1, dt))
		bar.BackgroundColor3 = themes.preset.button
pcall(function()
    if frame and frame.Parent ~= library.gui then
        frame.Parent = library.gui
    end
    if corner_text and corner_text.Parent ~= library.gui then
        corner_text.Parent = library.gui
        corner_text.ZIndex = 99999
    end
end)
		local activeText = ""
		local splitter = flags.watermark_style == "classic" and "|" or "Â·"
		for _, renderName in flags.watermark_options or {} do
			activeText ..= ` {splitter} {renderFuncs[renderName]()}`
		end
		label.Text = `seraph<font color="{rgbstr(themes.preset.button)}">.wtf</font> beta{activeText}`
		local interpValue = rgbstr( themes.preset.button:Lerp(rgb(), math.abs(0.1 - 0.05 * cos(sine / 30))) )
		corner_text.Text = `seraph<font color="{interpValue}">.wtf</font> beta{activeText}`
	end)
end

-- documentation 
local build_str = (function(targetStr)
	local len, build = string.len(targetStr), ""

	for i = 1, len do
		build ..= `<font color="{rgbstr(themes.preset.button:lerp(themes.preset.button_alt, i/len))}">{targetStr:sub(i, i)}</font>`
	end

	return build
end)(currentText)

local window = library:window({
	name = `seraph<font color="{rgbstr(themes.preset.button_alt)}">.wtf</font> {build_str}`,
	size = dim2(0, 460, 0, 362)
})

checkfile('seraph/cache/von.png', 'https://raw.githubusercontent.com/ravegirls/cdn/refs/heads/main/image-removebg-preview.png')

createNotification({text = "loading menu..."})
createNotification({text = "loading modules..."})

local dependants = {}
local function depend(element, f)
	insert(dependants, {element, f})
end

local rage = window:tab({name = "rage"})
rage:change_visibility(false)


local bullets = {
	--[[line = function(from, to, playSound)
		local bullet = Instance.new("Part")
		bullet.CFrame = cf(from, to) * cf(0, 0, -(from - to).Magnitude / 2)
		bullet.Size = Vector3.new(0,0,(from - to).Magnitude)
		bullet.Material = Enum.Material.Neon
		bullet.Name = ""
		bullet.Anchored = true
		bullet.CanCollide = false
		bullet.Transparency = 1
		bullet.Parent = workspace.Terrain
		local sphere = Instance.new("SpecialMesh")
		sphere.MeshType = Enum.MeshType.Sphere
		sphere.Scale = Vector3.new(1, 1, 1)
		sphere.Parent = bullet
		tween_service:Create(bullet,TweenInfo.new(0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0,false,0),{Color = flags.bullet_tracer_color.Color}):Play()
		tween_service:Create(bullet,TweenInfo.new(0.25,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0,false,0),{Transparency = 1 - flags.bullet_tracer_color.Transparency}):Play()
		tween_service:Create(bullet,TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut,0,false,0),{Size = Vector3.new(flags.bullet_tracer_thickness,flags.bullet_tracer_thickness,(from - to).Magnitude)}):Play()
		task.delay(1.5, function() tween_service:Create(bullet,TweenInfo.new(4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0,false,0),{Transparency = 1}):Play() end)
		task.delay(6, game.Destroy, bullet)
	end,]]
	lightning = function(from, to, playSound)
		local parts = {}
		local translated = {}
		local origin, originOffset = from, from
		local length = clamp(floor((from - to).Magnitude / 25), 10, 100)

		local scale = .5
		for i = 1, length do
			local new = origin:Lerp(to, i/length)
			local offset = vec3(
				math.random() * math.random(-1,1) * scale,
				math.random() * math.random(-1,1) * scale,
				math.random() * math.random(-1,1) * scale
			)
			local part = Instance.new("Part")
			local length = (origin - new).Magnitude
			part.CFrame = cf(origin, new) * cf(0, 0, -length / 2)
			part.Size = Vector3.new(0, 0, length)
			part.Color = Color3.new(

			)
			local length = (originOffset - (new + offset)).Magnitude
			tween_service:Create(part, TweenInfo.new(0.2 + i/5,Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut,0,false,0),{
				Size = Vector3.new(flags.bullet_tracer_thickness, flags.bullet_tracer_thickness, length),
				CFrame = cf(originOffset, (new + offset)) * cf(0, 0, -length / 2)
			}):Play()
			tween_service:Create(part, TweenInfo.new(0.05 + i/5,Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut,0,false,0),{
				Color = flags.bullet_tracer_color.Color
			}):Play()
			tween_service:Create(part, TweenInfo.new(0.5 + i/5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0,false,0),{
				Transparency = 1
			}):Play()
			task.delay(0.5 + i/5,game.Destroy,part)
			part.Material = Enum.Material.Neon
			part.Name = ""
			part.Anchored = true
			part.Transparency = 1 - flags.bullet_tracer_color.Transparency
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part.Parent = workspace.Terrain
			origin = new
			originOffset = new + offset
		end
	end,
	spiral = function(from, to)
		local distance = (from - to).Magnitude
		local direction = (to - from).Unit

		local right = Vector3.new(0, 1, 0):Cross(direction).Unit
		if right.Magnitude == 0 then right = Vector3.new(1, 0, 0) end
		local up = direction:Cross(right).Unit
		local brush = Instance.new("Part")
		brush.Size = Vector3.new(0.01, 0.01, 0.01)
		brush.Transparency = 1
		brush.CanCollide = false
		brush.Anchored = true
		brush.CFrame = CFrame.new(from)
		brush.Parent = workspace.Terrain
		local a0 = Instance.new("Attachment", brush)
		local a1 = Instance.new("Attachment", brush)
		a0.Position = Vector3.new(0, flags.bullet_tracer_thickness, 0)
		a1.Position = Vector3.new(0, -flags.bullet_tracer_thickness, 0)

		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.LightEmission = 1
		trail.Texture = "rbxassetid://6091329339"
		trail.Transparency = NumberSequence.new(0, 1)
		trail.TextureMode = Enum.TextureMode.Wrap
		trail.Color = ColorSequence.new(flags.bullet_tracer_color.Color)
		trail.Transparency = NumberSequence.new(1 - flags.bullet_tracer_color.Transparency, 1)
		trail.Lifetime = 3.5 -- How long the tracer stays visible
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.FaceCamera = true
		trail.Parent = brush
		local segments = 90 
		local rotations = 2
		local radius = math.clamp(math.random(), 0.5, 0.9)

		for i = 0, segments do
			local t = i / segments
			local basePos = from:Lerp(to, t)
			local angle = t * math.pi * 2 * rotations
			local offset = (right * math.cos(angle) * radius) + (up * math.sin(angle) * radius)
			brush.Position = basePos + offset
			if i % 3 == 0 then
				task.wait()
			end
		end
		task.delay(trail.Lifetime, game.Destroy, brush)
	end,
	smooth = function(from, to)
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")

		a0.WorldPosition = from
		a1.WorldPosition = to

		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.LightEmission = 1
		beam.TextureLength = 3.5
		beam.Texture = "rbxassetid://446111271"
		beam.TextureSpeed = math.random()
		beam.FaceCamera = true
		beam.Width0 = flags.bullet_tracer_thickness * .9
		beam.Width1 = flags.bullet_tracer_thickness * .9
		beam.TextureMode = Enum.TextureMode.Wrap

		beam.Parent = workspace.Terrain
		a0.Parent = workspace.Terrain
		a1.Parent = workspace.Terrain

		local tween = tween_service:Create(beam, TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut,-1,true,0),{
			Width0 = flags.bullet_tracer_thickness,
		})

		tween:Play()

		task.delay(0.25 / 2, function()
			local tween = tween_service:Create(beam, TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut,-1,true,0),{
				Width1 = flags.bullet_tracer_thickness,
			})

			tween:Play()
		end)

		for i = 1, 5 do
			beam.Transparency = NumberSequence.new(1-i/5, 1-i/5)
			beam.Color = ColorSequence.new(flags.bullet_tracer_color.Color)
			task.wait()
		end

		task.wait(5)

		for i = 1, 50 do
			beam.Transparency = NumberSequence.new(i/50, i/50)
			beam.Width0 = math.lerp(beam.Width0, 0, 1/50)
			beam.Width1 = math.lerp(beam.Width1, 0, 1/50)
			beam.Color = ColorSequence.new(flags.bullet_tracer_color.Color)
			task.wait()
		end

		a0:Destroy()
		beam:Destroy()
		a1:Destroy()
	end,
	line = function(from, to)
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")

		a0.WorldPosition = from
		a1.WorldPosition = to

		local boxhandle = library:create("BoxHandleAdornment", {
			Size = Vector3.new(0.02, 0.02, (from - to).Magnitude),
			CFrame = cf(from, to) * cf(0, 0, -(from - to).Magnitude / 2),
			Adornee = workspace.Terrain,
			AlwaysOnTop = true,
			ZIndex = 1,
			Transparency = 1,
			Color3 = flags.bullet_tracer_color.Color,
			Parent = workspace.Terrain
		})

		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.LightEmission = .5
		beam.LightInfluence = 0
		beam.TextureLength = 3.5
		beam.TextureSpeed = .5
		beam.FaceCamera = true
		beam.Width0 = 0 --flags.bullet_tracer_thickness * .8
		beam.Width1 = 0 --flags.bullet_tracer_thickness * .9
		beam.TextureMode = Enum.TextureMode.Wrap

		beam.Parent = workspace.Terrain
		a0.Parent = workspace.Terrain
		a1.Parent = workspace.Terrain

		tween_service:Create(beam, TweenInfo.new(1.0,Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut),{
			Width0 = flags.bullet_tracer_thickness,
			Width1 = flags.bullet_tracer_thickness,
		}):Play()

		for i = 1, 5 do
			beam.Transparency = NumberSequence.new(1-i/5, 1-i/5)
			boxhandle.Transparency = 1-i/10
			beam.Color = ColorSequence.new(flags.bullet_tracer_color.Color)
			task.wait()
		end

		task.wait(3)

		for i = 1, 90 do
			beam.Transparency = NumberSequence.new(i/90, i/90)
			boxhandle.Transparency = math.lerp(boxhandle.Transparency, 1, 1/90)
			boxhandle.Size = boxhandle.Size:lerp(Vector3.new(0, 0, boxhandle.Size.Z), i/90)
			beam.Width0 = math.lerp(beam.Width0, 0, 1/90)
			beam.Width1 = math.lerp(beam.Width1, 0, 1/90)
			beam.Color = ColorSequence.new(flags.bullet_tracer_color.Color)
			task.wait()
		end

		a0:Destroy()
		beam:Destroy()
		a1:Destroy()
	end,
	lightning2 = function(from, to, playSound)
		local parts = {}
		local translated = {}
		local origin, originOffset = from, from
		local length = clamp(floor((from - to).Magnitude / 25), 10, 100)

		local scale = .5
		for i = 1, length do
			local new = origin:Lerp(to, i/length)
			local offset = vec3(
				math.random() * math.random(-1,1) * scale,
				math.random() * math.random(-1,1) * scale,
				math.random() * math.random(-1,1) * scale
			)
			local part = Instance.new("Part")
			local length = (origin - new).Magnitude
			part.CFrame = cf(origin, new) * cf(0, 0, -length / 2)
			part.Size = Vector3.new(0, 0, length)
			local sphere = Instance.new("SpecialMesh")
			sphere.MeshType = Enum.MeshType.Sphere
			sphere.Scale = Vector3.new(1, 1, 1)
			sphere.Parent = part
			part.Color = Color3.new(

			)
			local length = (originOffset - (new + offset)).Magnitude
			tween_service:Create(part, TweenInfo.new(0.2 + i/5,Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut,0,false,0),{
				Size = Vector3.new(flags.bullet_tracer_thickness, flags.bullet_tracer_thickness, length),
				CFrame = cf(originOffset, (new + offset)) * cf(0, 0, -length / 2)
			}):Play()
			tween_service:Create(part, TweenInfo.new(0.05 + i/5,Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut,0,false,0),{
				Color = flags.bullet_tracer_color.Color
			}):Play()
			tween_service:Create(part, TweenInfo.new(0.5 + i/5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,0,false,0),{
				Transparency = 1
			}):Play()
			task.delay(0.5 + i/5,game.Destroy,part)
			part.Material = Enum.Material.Neon
			part.Name = ""
			part.Anchored = true
			part.Transparency = 1 - flags.bullet_tracer_color.Transparency
			part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
			part.Parent = workspace.Terrain
			origin = new
			originOffset = new + offset
		end
	end
}
function draw_bullet(from, to, playSound)
	if not flags.bullet_tracers then return end
	local func = bullets[flags.bullet_tracer_style]
	task.spawn(func, from, to, playSound)
	local sfxId = sfx[flags.killsound_l]
	if sfxId and (playSound == nil or playSound == true) then
		local sound = Instance.new("Sound")
		sound.SoundId = sfxId
		sound.Name = ""
		sound.Volume = flags.sound_volume or 1.0
		sound.PlaybackSpeed = flags.pitchrng_l and math.random(95, 105) / 100 or 1
		sound.PlayOnRemove = true
		sound.Parent = services.soundService
		task.delay(0, game.Destroy, sound)
	end
end

local barsRendered, listAdd = {}, 0
function drawBar(barName, progress, visible, startColor, endColor)
	if not barsRendered[barName] then
		barsRendered[barName] = {
			outerBar = Drawing.new("Square"),
			innerBar = Drawing.new("Square"),
			text = Drawing.new("Text"),
			transparency = 0
		}
	end


	progress = clamp(progress, 0, 1)
	local outerBar, innerBar, text = barsRendered[barName].outerBar, barsRendered[barName].innerBar, barsRendered[barName].text
	local where = camera.ViewportSize / 2 + vec2(0, 45 + listAdd)
	local size, padding = vec2(50, 2), vec2(1, 1)
	outerBar.Position = where - size / 2 - padding
	outerBar.Size = size + padding * 2
	outerBar.Color = rgb(11, 11, 11)

	text.Center = false
	text.Position = where - vec2(size.x / 2, size.Y + 13)
	text.Size = 12
	text.Color = rgb(255, 255, 255)
	text.Outline = true
	text.Text = barName

	innerBar.Size = vec2(math.lerp(0, size.X, progress), size.Y)
	innerBar.Position = where - size / 2 --+ vec2(innerBar.Size.X, 0)

	innerBar.Color = startColor:lerp(endColor, progress)

	barsRendered[barName].transparency = clamp(barsRendered[barName].transparency + (visible and 0.1 or -0.1), 0, 1)

	local visible = barsRendered[barName].transparency ~= 0


	text.Transparency, outerBar.Transparency, innerBar.Transparency =
		barsRendered[barName].transparency,
	barsRendered[barName].transparency,
	barsRendered[barName].transparency
	outerBar.Filled, innerBar.Filled = true, true
	outerBar.Visible, innerBar.Visible, text.Visible = visible, visible, visible

	if visible then
		listAdd += 25
	end
end

local legit
task.spawn(function()
if game.GameId == 113491250 then
	-- PF AIMBOT TAB [PHANTOM FORCES]
	createNotification({text = "Attempting to attach into Phantom Forces.", duration = 5})
	local t = tick()
	repeat
		task.wait()
	until getrenv().shared and getrenv().shared.require or (tick() - t) > 2
	if not getgenv().replacementForModules and not getrenv().shared.require then
		task.spawn(messagebox, 'Failed to attach into Phantom Forces environment.', 'seraph.wtf', bit32.bxor(32,0,256))
		services.teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
		return
	else
		createNotification({text = "Successfully attached into Phantom Forces.", duration = 5})
	end
	local moduleCache = getgenv().replacementForModules and getgenv().replacementForModules[1] or debug.getupvalue(getrenv().shared.require, 1)._cache;
	local indexPrevious = {}
	local modules = setmetatable({}, {
		__index = function(Self, Index)
			if not moduleCache[Index] then
				repeat task.wait() until moduleCache[Index]
			end
			local inst_;
			for _, obj in moduleCache[Index] do
				if typeof(obj) == "Instance" and obj:IsA("ModuleScript") then
					inst_ = obj
					break
				end
			end
			inst_:Clone().Parent = game:GetService'ReplicatedStorage'
			return moduleCache[Index].module;
		end
	});
	local ragebot = window:tab({name = "ragebot"}) ragebot:open_tab()
	local column = ragebot:column({})
	local column2 = ragebot:column({})
	-- Combined Combat Multisection
	local combat_tab = column:multisection({
		name = "combat", 
		sections = {"aimbot", "scanning", "anti-aim"}, 
		auto_fill = false, 
		size = 0.3
	})

	-- Aimbot Tab
	local aimbot = combat_tab:get_tab("aimbot")
	aimbot:toggle({name = "enabled", flag = "rageaim", tip = "Enables the rage aimbot."})
	aimbot:toggle({name = "sound override", flag = "fakeragesound", tip = "Changes the shoot sound."})
	aimbot:toggle({name = "multithreading", flag = "pf_rage_multithreading", tip = "Uses multiple threads to improve performance."})
	aimbot:toggle({name = "resolver", flag = "resolver", tip = "Resolves enemy fake positions"})
	aimbot:toggle({name = "damage prediction", flag = "damageprediction", tip = "Predicts damage to prevent overshooting"})
	aimbot:dropdown({
		name = "filtering",
		flag = "filter_type",
		items = {"none", "whitelist", "blacklist"},
		multi = false,
		scrolling = true,
	})

	-- Scanning Tab
	local origin_scan = combat_tab:get_tab("scanning")
	origin_scan:toggle({name = "bulking", flag = "detailedScanning", tip = "Listens to incoming events to instantly kill players."})
	origin_scan:toggle({name = "tp scanning", flag = "spider", tip = "Teleports you to places where you can hit people."})
	origin_scan:dropdown({
		name = "scan mode",
		flag = "origin_scan_mode",
		items = {"teleport", "origin", "target", "warp"},
		multi = true,
		scrolling = true
	})
	origin_scan:slider({name = "max targets per scan", min = 1, max = 32, default = 8, interval = 1, suffix = 'targets', flag = "max_targets"})
	origin_scan:dropdown({name = "algorithm", flag = "pf_rage_algorithm", items = {"random", "advanced", "sweep", "experimental"}, multi = false, scrolling = true, default = "random"})
	origin_scan:dropdown({name = "scan verticies", flag = "pf_rage_scan_vertices", items = {"low", "medium", "high", "extreme"}, multi = false, scrolling = true, default = "low"})
	depend(origin_scan:slider({name = "tp distance", min = 3, max = 2000 --[[35]], default = 3, interval = 0.1, suffix = 'studs', flag = "origin_teleport"}), function()
		return find(flags.origin_scan_mode, "teleport")
	end)
	depend(origin_scan:slider({name = "origin shift", min = 0, max = 15.9, default = 0, interval = 0.1, suffix = 'studs', flag = "origin_shift"}), function()
		return find(flags.origin_scan_mode, "origin")
	end)
	depend(origin_scan:slider({name = "target shift", min = 0, max = 9.9, default = 0, interval = 0.1, suffix = 'studs', flag = "target_shift"}), function()
		return find(flags.origin_scan_mode, "target")
	end)
	depend(origin_scan:slider({name = "warping distance", min = 9.9, max = 9.9 * 4, default = 9.9 * 3, interval = 0.1, suffix = 'studs', flag = "warp_distance"}), function()
		return find(flags.origin_scan_mode, "warp")
	end)

	-- Anti-Aim Tab
	local aa = combat_tab:get_tab("anti-aim")
	aa:toggle({name = "enabled", flag = "aa", tip = "Enables anti-aim"})
	aa:dropdown({
		name = "pitch",
		flag = "pitch",
		items = {"none", "zero", "down", "up", "random", "inversion", "sine", "bob"},
		default = 'none',
		multi = false,
		scrolling = true
	})
	aa:dropdown({
		name = "yaw",
		flag = "yaw",
		items = {"none", "spin", "fast spin", "sine spin", "random", "backwards", "jitter"},
		multi = false,
		default = 'none',
		scrolling = true
	})
	local stateparent = aa:label({name = "state desync", flag = "statedesync_label", popout = true})
	local statedesync = aa:keybind({name = "enabled", flag = "statedesync", display = "state desync"})
	stateparent:add(desync)
	stateparent:add(aa:dropdown({
		name = "mode",
		flag = "statedesync_mode",
		items = {"stiff", "full", "jitter"},
		multi = false,
		scrolling = true
	}))
	local fakeduck = aa:keybind({name = "fakeduck", flag = "fakeduck", display = "fakeduck"})
	local anti_resolver = aa:keybind({name = "anti-resolver", flag = "anti_resolver", display = "anti-resolver"})
	aa:slider({name = "update rate", min = 0.01, max = 4, default = 2, interval = 1e-3, suffix = 's', flag = "updaterate", tip = "Delay per step"})
	aa:toggle({name = "extra packets", flag = "extend_packets"})
	aa:toggle({name = "jitter move", flag = "jitter_move", tip = "Jitters movement to prevent being hit."})

	-- Manipulation Multisection
	local manip_multi = column2:multisection({
		name = "manipulation", 
		sections = {"movement", "misc", "backtrack"}, 
		auto_fill = false, 
		size = 0.3
	})

	-- Movement Tab
	local movement = manip_multi:get_tab("movement")
	local parent = movement:toggle({name = "auto pathfind", flag = "auto_move", tip = "palantir ai pathfinding", popout = true})
	parent:add(movement:toggle({name = "prefer safe", flag = "auto_peek", tip = "prefers LOS paths so you don't walk straight to the enemy."}))
	parent:add(movement:toggle({name = "simple", flag = "auto_peek_shoot", tip = "keeps path simple"}))
	parent:add(movement:toggle({name = "client move", flag = "auto_move_client", tip = "client-side movement on paths"}))
	parent:add(movement:toggle({name = "rotations", flag = "auto_rotate", tip = "palantir camera rotator v9"}))
	local walkspeed_parent = movement:toggle({
		name = "walkspeed", 
		flag = "force_speed", 
		tip = "Speed exploit",
		popout = true -- This makes it a parent for sub-items
	})
	walkspeed_parent:add(movement:keybind({
		name    = "keybind", 
		flag    = "speedkey", 
		display = "speed"
	}))
    walkspeed_parent:add(movement:toggle({
		name = "control", 
		flag = "speed_control", 
		tip = "Improves player control"
	}))
    walkspeed_parent:add(movement:slider({
        name     = "speed", 
        flag     = "speedvalue",
        min      = 16, 
        max      = 110, 
        default  = 16, 
        interval = 1, 
        suffix   = 'studs/s', 
        tip      = "Exploit speed value"
    }))
	local jump_parent = movement:toggle({
		name = "jump power", 
		flag = "force_jump", 
		tip = "Jump exploit",
		popout = true -- This makes it a parent for sub-items
	})

	jump_parent:add(movement:keybind({
		name    = "keybind", 
		flag    = "jumpkey", 
		display = "jump"
	}))
	jump_parent:add(movement:slider({
		name     = "height", 
		flag     = "jump_strength",
		min      = 1, 
		max      = 75, 
		default  = 50, 
		interval = 1, 
		suffix   = 'studs/s', 
		tip      = "Exploit jump value"
	}))

	-- Exploits Tab
	local exploits = manip_multi:get_tab("misc")
	exploits:toggle({name = "auto spawn", flag = "autospawn", tip = "palantir ai auto spawn xp farm v6"})
	local burst_exploit = exploits:keybind({name = "firerate bypass", flag = "burst_exploit", tip = "Abuses a vulnerability to shoot multiple rounds.", display = "rapidfire"})
	exploits:dropdown({
		name = "firerate mode",
		flag = "rapidfire_type",
		items = {"regular", "onshot", "triple"},
		multi = false,
		scrolling = true
	})

	-- Ghosting / Tickbase Tab
	local ghosting = manip_multi:get_tab("backtrack")
	local tickbase_manip = ghosting:keybind({name = "tickbase", flag = "tickbase_manip", tip = "Manipulates tickbase for some features.", display = "tickbase"})
	ghosting:toggle({name = "backtrack", flag = "pf_rage_backtrack", tip = "Allows you to shoot at previous positions of players."})
	depend(ghosting:slider({name = "backtrack ticks", min = 1, max = 3000, default = 400, interval = 1, suffix = 'ms', flag = "pf_rage_backtrack_time", tip = "How far back in time should we track players?"}), function()
		return flags.pf_rage_backtrack
	end)
	--[[local aimbot = column:section({name = "aimbot", auto_fill = false, size = 0.3})
	aimbot:toggle({name = "enabled", flag = "rageaim", tip = "Enables the rage aimbot."})
	aimbot:toggle({name = "sound override", flag = "fakeragesound", tip = "Changes the shoot sound."})
	aimbot:toggle({name = "multithreading", flag = "pf_rage_multithreading", tip = "Uses multiple threads to improve performance."})
	aimbot:toggle({name = "resolver", flag = "resolver", tip = "Resolves enemy fake positions"})
	aimbot:toggle({name = "damage prediction", flag = "damageprediction", tip = "Predicts damage to prevent overshooting"})
	local origin_scan = column:section({name = "scanning", auto_fill = false, size = 0.3})
	origin_scan:toggle({name = "bulking", flag = "detailedScanning", tip = "Listens to incoming events to instantly kill players."})
	origin_scan:toggle({name = "tp scanning", flag = "spider", tip = "Teleports you to places where you can hit people."})
	origin_scan:dropdown({
		name = "scan mode",
		flag = "origin_scan_mode",
		items = {"teleport", "origin", "target"},
		multi = true,
		scrolling = true
	})
	origin_scan:dropdown({name = "algorithm", flag = "pf_rage_algorithm", items = {"random", "advanced", "sweep", "experimental"}, multi = false, scrolling = true, default = "random"})
	origin_scan:dropdown({name = "scan verticies", flag = "pf_rage_scan_vertices", items = {"low", "medium", "high", "extreme"}, multi = false, scrolling = true, default = "low"})
	depend(origin_scan:slider({name = "tp distance", min = 3, max = 35, default = 3, interval = 0.1, suffix = 'studs', flag = "origin_teleport"}), function()
		return find(flags.origin_scan_mode, "teleport")
	end)
	depend(origin_scan:slider({name = "origin shift", min = 0, max = 15.9, default = 0, interval = 0.1, suffix = 'studs', flag = "origin_shift"}), function()
		return find(flags.origin_scan_mode, "origin")
	end)
	depend(origin_scan:slider({name = "target shift", min = 0, max = 9.9, default = 0, interval = 0.1, suffix = 'studs', flag = "target_shift"}), function()
		return find(flags.origin_scan_mode, "target")
	end)
	local manipulation = column2:section({name = "manipulation", auto_fill = false, size = 0.3})
	--manipulation:toggle({name = "multi shot", flag = "pf_multishot", tip = "Allows you to shoot multiple bullets at once."})
	manipulation:toggle({name = "auto pathfind", flag = "auto_move", tip = "palantir ai pathfinding"})
	depend(manipulation:toggle({name = "prefer safe paths", flag = "auto_peek", tip = "prefers LOS paths so you don't walk straight to the enemy."}), function()
		return flags.auto_move
	end)
	depend(manipulation:toggle({name = "rotate to path", flag = "auto_rotate", tip = "palantir camera rotator v9"}), function()
		return flags.auto_move
	end)
	manipulation:toggle({name = "auto spawn", flag = "autospawn", tip = "palantir ai auto spawn xp farm v6"})
	local burst_exploit = manipulation:keybind({name = "firerate bypass", flag = "burst_exploit", tip = "Abuses a vulnerability to shoot multiple rounds.", display = "rapidfire"})
	manipulation:dropdown({
		name = "firerate mode",
		flag = "rapidfire_type",
		items = {"regular", "onshot", "triple"},
		multi = false,
		scrolling = true
	})
	local tickbase_manip = manipulation:keybind({name = "tickbase", flag = "tickbase_manip", tip = "Manipulates tickbase for some features.", display = "tickbase"})
	--manipulation:toggle({name = "force hit", flag = "pf_forceaim", tip = "Forces your shots to hit the target by manipulating multiple things, but it may cause issues."})
	manipulation:toggle({name = "backtrack", flag = "pf_rage_backtrack", tip = "Allows you to shoot at previous positions of players."})
	manipulation:toggle({name = "walkspeed", flag = "force_speed", tip = "Speed exploit"})
	depend(manipulation:slider({name = "speed value", min = 16, max = 110, default = 16, interval = 1, suffix = 'studs/s', flag = "speedvalue", tip = "Exploit speed value"}), function()
		return flags.force_speed
	end)
	depend(manipulation:slider({name = "backtrack ticks", min = 1, max = 3000, default = 400, interval = 1, suffix = 'ms', flag = "pf_rage_backtrack_time", tip = "How far back in time should we track players?"}), function()
		return flags.pf_rage_backtrack
	end)
	local aa = column:section({name = "anti-aim", auto_fill = false, size = 0.3})
	aa:toggle({name = "enabled", flag = "aa", tip = "Enables anti-aim"})
	aa:dropdown({
		name = "pitch",
		flag = "pitch",
		items = {"none", "zero", "down", "up", "random", "inversion", "sine", "bob"},
		default = 'none',
		multi = false,
		scrolling = true
	})
	aa:dropdown({
		name = "yaw",
		flag = "yaw",
		items = {"none", "spin", "fast spin", "sine spin", "random", "backwards", "jitter"},
		multi = false,
		default = 'none',
		scrolling = true
	})
	local statedesync = aa:keybind({name = "state desync", flag = "statedesync", display = "state desync"})
	local fakeduck = aa:keybind({name = "fakeduck", flag = "fakeduck", display = "fakeduck"})
	local anti_resolver = aa:keybind({name = "anti-resolver", flag = "anti_resolver", display = "anti-resolver"})
	aa:slider({name = "update rate", min = 0.01, max = 4, default = 2, interval = 1e-3, suffix = 's', flag = "updaterate", tip = "Delay per step"})
	aa:toggle({name = "jitter move", flag = "jitter_move", tip = "Jitters movement to prevent being hit."})]]
	--[[local velocity_desync = aa:keybind({name = "velocity desync", flag = "velocity_desync", display = "velocity desync"})
	local state_desync = aa:keybind({name = "state desync", flag = "statedesync", display = "state desync"})
	aa:slider({name = "ticks", min = 1, max = 32, default = 14, interval = 1, suffix = "t", flag = "ticks"})
	local fakeduck = aa:keybind({name = "fakeduck", flag = "fakeduck", display = "fakeduck"})
	local position_desync = aa:keybind({name = "position desync", flag = "posdesync", display = "position desync"})
	aa:slider({name = "max distance", min = 5, max = 999, default = 6, interval = 5, suffix = 'studs', flag = "posdesyncdistance", tip = "Max distance you can go away (Higher distances mean you will get rubberbanded back)"})
	local velocity_desync = aa:keybind({name = "packet delay", flag = "delaypacket", display = "packet delay"})
	aa:slider({name = "delay", min = 1, max = 1000, default = 150, interval = 1, suffix = "ms", flag = "delaypacketms"})
	local anti_resolver = aa:keybind({name = "anti-resolver", flag = "anti_resolver", display = "anti-resolver"})
	aa:slider({name = "max distance", min = 5, max = 20, default = 6, interval = 1, suffix = 'studs', flag = "max_distance", tip = "Max distance you can go away using anti-resolver"})
	aa:slider({name = "step size", min = 0.25, max = 8, default = 1, interval = 0.1, suffix = 'studs', flag = "stepsize", tip = "Step size for anti-resolver"})]]
	
	local legit = window:tab({name = "legit"})
	local column = legit:column({})
	local column2 = legit:column({})

	local repObject = modules.ReplicationObject
	local gameClock = modules.GameClock
	local charInterface = modules.CharacterInterface
	--[[
		local networkclient = getrenv().shared.require('NetworkClient');
		local last_replication = -1;

		local function random_range(int)
			return math.random() * ((math.random(0, 1) == 1 and -1) or 1) * int;
		end;
		_G.enabled = true;
		local send = networkclient.send;
		networkclient.send = function(self, method, ...)
			if method == 'repupdate' and _G.enabled then
				local real_pos, view_angles, barrel_view_angles, tick_time = ...;

				if tick() - last_replication > 3.5 + math.random() then -- u can change 3.5 to 4 they both work. its the time ur desynced for
					local offsetted_vector = Vector3.new(random_range(6), 0, random_range(6));
					print(offsetted_vector);

					local fake_pos = real_pos + offsetted_vector;

					send(self, method, real_pos, view_angles, barrel_view_angles, tick_time);
					send(self, method, fake_pos, view_angles, barrel_view_angles, tick_time);

					last_replication = tick();
					print('my packet');
				end;

				return;
			end;

			if method == 'flaguser' or method == 'debug' then
				return;
			end;

			return send(self, method, ...);
		end;
		]]
	do -- ty legacy <3
		local function require(moduleName) return modules[moduleName] end	
		local crosshairsInterface = require("HudCrosshairsInterface")
		local weaponInterface = require("WeaponControllerInterface")
		local renderSteppedUpdater = require("RenderSteppedUpdater")
		local replicationInterface = require("ReplicationInterface")
		local roundSystem = require("RoundSystemClientInterface")
		local environmentInterfaceClient = require("EnvironmentInterfaceClient")
		local replicationObject = require("ReplicationObject")
		local thirdPersonObject = require("ThirdPersonObject")
		local charInterface = require("CharacterInterface")
		local publicSettings = require("PublicSettings")
		local camInterface = require("CameraInterface")
		local firearmObject = require("FirearmObject")
		local statusEvents = require("PlayerStatusEvents")
		local charObject = require("CharacterObject")
		local charEvents = require("CharacterEvents")
		local bulletCheck = require("BulletCheck")
		local audioSystem = require("AudioSystem")
		local network = require("NetworkClient")
		local vector = require("VectorLib")
		local effects = require("Effects")

		local resolver = {
			records = {}, -- [player] = { {pos, time}, ... }
			maxRecords = 8
		}

		local player_state = {}

		library.player_state = player_state


		local partList = {}
		local thicknessFactor = Vector2.new(1.1, 1.25) -- x, z
		local neonSizeFactor = 1.02
		local updateEnemyState = replicationObject.updateEnemyState
		function replicationObject:updateEnemyState(...)
			updateEnemyState(self, ...)
			local object = self:getThirdPersonObject()
			local character = object and object:getCharacterHash()
			
			--thread(tryScan)
		end

		local old = modules.ReplicationObject.updateReplication
		modules.ReplicationObject.updateReplication = newlclosure(function(self, ...)
			local entry = self
			local player = entry._player
			if player and typeof(player) == 'Instance' then
				local pos = entry._receivedPosition
				if player and pos then
					if not player_state[player] then
						player_state[player] = {
							exploiting = false
						}
					end
					local list = resolver.records[player]
					if not list then
						list = {}
						resolver.records[player] = list
					end

					table.insert(list, 1, {
						pos = pos,
						time = tick()
					})

					if #list > resolver.maxRecords then
						table.remove(list)
					end
				end
			end
			return old(self, ...)
		end)

		function resolver:resolve(player)
			local records = self.records[player]
			if not records or #records < 2 then
				return records and records[1] and records[1].pos
			end

			local MAX_SPEED = 60
			local MAX_ACCEL = 350
			local STABLE_DIST = 6

			local ping = math.clamp((globals.ping or 50) / 1000, 0, 0.2)

			local r1 = records[1]
			local r2 = records[2]
			local r3 = records[3]

			local dt = r1.time - r2.time
			if player_state[player].exploitCharge and player_state[player].exploitCharge <= 0 then player_state[player].exploitCharge = 0 player_state[player].exploiting = false end
			if player_state[player].exploitCharge then player_state[player].exploitCharge -= 0.05 end
			if dt <= 0 or dt > 0.35 and dt <= 1.0 then
				return r1.pos
			end

			do
				local r1 = records[1]
				local r2 = records[2]

				local dt = r1.time - r2.time
				if dt > 0 and dt < 0.25 then
					local delta = r1.pos - r2.pos
					local speed = delta.Magnitude / dt

					if speed < 45 then
						return r1.pos
					end
				end
			end

			if dt > 9.5 then
				return records[#records].pos
			end

			local v1 = (r1.pos - r2.pos) / dt
			local speed = v1.Magnitude

			local dt2 = r2.time - r3.time
			
			local speed = (r1.pos - r2.pos).Magnitude
			local MAX_SPEED = 9.9

			if speed > MAX_SPEED * 0.8 and dt2 > 1/30 then
				for i = 3, #records do
					local a = records[i - 1]
					local b = records[i]
					if (a.pos - b.pos).Magnitude < STABLE_DIST then
						return a.pos
					end
				end
				player_state[player].exploiting = true
				player_state[player].exploitCharge = 0.5
				print(speed, MAX_SPEED*1.4, dt2)
				return r2.pos
			end

			if dt2 > 1 or speed > MAX_SPEED * 0.8 then
				player_state[player].exploiting = true
				player_state[player].exploitCharge = 2.0
				warn(dt2, speed)
			end

			if r3 then
				local dt2 = r2.time - r3.time
				if dt2 > 0 and dt2 < 0.35 then
					local v2 = (r2.pos - r3.pos) / dt2
					if v1:Dot(v2) < -0.4 then
						return r2.pos
					end
				end
			end

			local predicted = r1.pos

			return predicted
		end




		replicationInterface.operateOnAllEntries(function(player, entry)
			local object = entry:getThirdPersonObject()

			if object then
				for part, size in object._partSizes do
					part.Size = size
				end

				--addEsp(object:getRootPart(), object:getCharacterHash(), object)
				entry:updateEnemyState()
			end
		end)
		
		local spawn = replicationObject.spawn

		local setBaseWalkSpeed = charObject.setBaseWalkSpeed
		function charObject:setBaseWalkSpeed(speed)
			return setBaseWalkSpeed(self, ((flags.force_speed and flags.speedkey.active) and flags.speedvalue or speed))
		end

		local networkCache = {updateDebt = 0}

		library.networkCache = networkCache

		local dependencyTaskStepper = renderSteppedUpdater._dependencyTaskStepper
		for taskData, _ in dependencyTaskStepper._taskContainers.CharacterInterface.tasks do
			if taskData.id == "CharacterInterface" then
				--dependencyTaskStepper._removals[taskData] = true
				--dependencyTaskStepper:_processRemovals()
				debug.setupvalue(taskData.task, 9, {send = function(...)
					if ((flags.force_speed and flags.speedkey.active) or networkCache.teleporting) and (tick() - networkCache.spawn) > 0.5 then
						return
					end
					
					library.networkCache = networkCache

					return network.send(...)
				end}) -- stop repupdate
			end
		end

		local function random_range(int)
			return math.random() * ((math.random(0, 1) == 1 and -1) or 1) * int;
		end;

		local pendingDamage = {} -- [player] = { {dmg, hitTime}, ... }

				
		local function trajectory(o, a, t, s)
			local f = -a
			local ld = t - o
			local a = f:Dot(f)
			local b = 4 * ld:Dot(ld)
			local k = (4 * (f:Dot(ld) + s * s)) / (2 * a)
			local v = (k * k - b / a) ^ 0.5
			local t, t0 = k - v, k + v

			t = t < 0 and t0 or t; t = t ^ 0.5
			return f * t / 2 + ld / t, t
		end


		local function dp_cleanup(player)
			local list = pendingDamage[player]
			if not list then return 0 end

			local now = tick()
			local total = 0

			for i = #list, 1, -1 do
				local shot = list[i]
				if shot.hitTime <= now then
					table.remove(list, i)
				else
					total += shot.dmg
				end
			end

			if #list == 0 then
				pendingDamage[player] = nil
			end

			return total
		end

		local function dp_register(player, dmg, distance, bulletspeed)
			local ping = (globals.ping or 50) * 0.0005
			local travel = distance / bulletspeed
			local hitTime = tick() + travel + ping

			local list = pendingDamage[player]
			if not list then
				list = {}
				pendingDamage[player] = list
			end

			list[#list + 1] = {
				dmg = dmg,
				hitTime = hitTime
			}
		end

		local function estimateDamage(weapon, distance)
			local base = weapon:getWeaponStat("damage") or 35
			local range = weapon:getWeaponStat("range") or 300
			local falloff = math.clamp(1 - (distance / range), 0.45, 1)

			return base * falloff * 1.25
		end

		local physicsignore = {workspace.Terrain, workspace.Ignore, workspace.Players, workspace.CurrentCamera}
		local raycastparameters = RaycastParams.new()
		local function raycast(origin, direction, filterlist, whitelist)
			raycastparameters.IgnoreWater = true
			raycastparameters.FilterDescendantsInstances = filterlist or physicsignore
			raycastparameters.FilterType = Enum.RaycastFilterType[whitelist and "Whitelist" or "Blacklist"]

			local result = workspace:Raycast(origin, direction, raycastparameters)
			return result and result.Instance, result and result.Position, result and result.Normal, result and result.Distance
		end

		networkCache.pathfinding = {
			nodes = {},
			reversed = {},
			finished = true,
			queue = false,
			busy = false
		}

	
		

		local function pushOffWalls(pos, radius)
			local dirs = {
				Vector3.new(1, 0, 0),
				Vector3.new(-1, 0, 0),
				Vector3.new(0, 0, 1),
				Vector3.new(0, 0, -1),
			}

			for i = 1, 4 do
				local result, pos, normal, distance = raycast(pos, dirs[i] * radius)
				if result then
					pos += normal * (radius - (distance + 0.1))
				end
			end

			return pos
		end

		local function pathfind(final)
			local pf = networkCache.pathfinding
			if not pf or not pf.nodes then
				pf = {
					nodes = {},
					reversed = {},
					finished = true,
					queue = false,
					busy = false,
					lastScan = 0
				}
				networkCache.pathfinding = pf
			end

			if (tick() - networkCache.spawn) < 1 then return end
			if pf.busy then return end
			if tick() - pf.lastScan < 1 then return end
			if #pf.nodes > 0 and #pf.reversed > 0 then return end

			pf.busy = true

			local pathObj = services.pathfindingService:CreatePath({
				AgentRadius = 1.25,
				AgentHeight = 2.0,
				WaypointSpacing = 4.0,
				AgentCanJump = false,
				Costs = { Water = math.huge }
			})

			table.clear(pf.nodes)
			table.clear(pf.reversed)

			local success, reason = pcall(pathObj.ComputeAsync, pathObj, networkCache.lastUpdate, final)
			if not success or pathObj.Status ~= Enum.PathStatus.Success then
				createNotification({ text = "Pathfinding failed!", time = 5 })
				pf.busy = false
				pf.lastScan = tick()
				return
			end

			local function snapToGround(pos)
				local result = workspace:Raycast(pos + vec3(0, 3, 0), vec3(0, -10, 0), raycastparameters)
				return result and result.Position + vec3(0,2.8,0) or pos
			end

			local waypoints = pathObj:GetWaypoints()
			local maxChunkDist = 6.5
			local preciseDist = 1.5

			local nodes = pf.nodes
			local nodeIndex = 0
			local lastPos = nil

			for i = 1, #waypoints do
				local wp = waypoints[i]
				local pos = wp.Position
				for i = 1, 6 do
					pos = pushOffWalls(pos, 1.45)
				end
				pos = snapToGround(pos)

				nodes[i] = pos

				if flags.auto_peek_shoot then
					if i > 20 then
						break
					end
				end
			end

			pf.busy = false
			pf.lastScan = tick()
		end

		
		local acceleration = modules.PublicSettings.bulletAcceleration

		local function ballisticVisible(from, to, bulletSpeed)
			if typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3" then
				return false
			end

			local low, high = 0, 1
			local bestPoint = nil

			for i = 1, 3 do
				local alpha = (low + high) * 0.5
				local testPoint = from:Lerp(to, alpha)

				-- get velocity & travel time from trajectory
				local velocity, travelTime = trajectory(from, acceleration, testPoint, bulletSpeed)
				if not velocity then
					return false
				end

				-- call BulletCheck using your exact signature
				local isVisible = bulletCheck(
					from,
					testPoint,
					velocity,
					acceleration,
					4,
					travelTime
				) -- assume 4

				if isVisible then
					bestPoint = testPoint
					high = alpha
				else
					low = alpha
				end
			end

			-- only valid if the ballistic line reaches very close to the target
			return bestPoint ~= nil and (bestPoint - to).Magnitude < 0.5
		end

		
		local lastTime
		local send = network.send
		function network:send(name, ...)
			if name == "repupdate" then
				local position, angles, gunAngles, time = ...
				if networkCache.currentTime then
					networkCache.velocity = ((position - networkCache.currentPosition) / (time - networkCache.currentTime)).Magnitude
				end
				networkCache.currentTime = time
				networkCache.currentPosition = position

				if ((time - (lastTime or 0)) < (1 / 60)) then
					return
				end

				if networkCache.updateDebt > 0 then
					networkCache.updateDebt -= 1
					return
				end

				if (tick() - networkCache.spawn) < 1 then
					networkCache.pathfinding = nil
					networkCache.instantTeleport = nil
				end
			
				if networkCache.instantTeleport then
					if networkCache.isBusy then return end
					print("lol")
					print(networkCache.instantTeleport.nodes, #networkCache.instantTeleport.nodes)
					networkCache.isBusy = true
					local thread = task.delay(2.25, function()
						networkCache.isBusy = false
					end)
					if #networkCache.instantTeleport.nodes > 0 then
						while #networkCache.instantTeleport.nodes > 0 do
							for i = 1, 2 do
								if #networkCache.instantTeleport.nodes <= 0 then break end
								position = networkCache.instantTeleport.nodes[1]
								networkCache.instantTeleport.visited[#networkCache.instantTeleport.nodes] = position
								remove(networkCache.instantTeleport.nodes, 1)
								networkCache.lastTime = network.getTime()
								networkCache.lastUpdate = position
								send(self, name, position, angles, gunAngles, network.getTime())
								if library.char then library.char.HumanoidRootPart.CFrame = CFrame.new(position) * library.char.HumanoidRootPart.CFrame.Rotation end
								task.wait()
							end
							task.wait(1/30)
						end
						networkCache.instantTeleport = nil
					end
					pcall(task.cancel, thread)
					networkCache.isBusy = false
					return
				elseif networkCache.teleporting then
					position = networkCache.rage.queue[1]
					table.remove(networkCache.rage.queue, 1)

					if #networkCache.rage.queue < 1 then
						if not networkCache.rage.finished then
							local reversedTeleports = {}
							local teleports = networkCache.rage.teleports

							for index = 1, #teleports do
								table.insert(reversedTeleports, 1, teleports[index])
							end

							networkCache.rage.queue = reversedTeleports
							networkCache.rage.finished = true
							networkCache.rage.callback()

							networkCache.lastTick = network.getTime() + 1.0
						else
							networkCache.teleporting = false
						end
					end
					--[[networkCache.pathfinding.nodes  = {}
					networkCache.pathfinding.reversed = {}
					networkCache.pathfinding.finished = false
					networkCache.pathfinding.lastScan = tick()
					networkCache.forcePosition = nil]]
					networkCache.isBusy = false
					networkCache.instantTeleport = nil
				elseif networkCache.pathfinding then
					if not networkCache.pathfinding.finished then
						if #networkCache.pathfinding.nodes > 0 then
							position = networkCache.pathfinding.nodes[1]
							networkCache.pathfinding.reversed[#networkCache.pathfinding.nodes] = position
							networkCache.forcePosition = position
							--if library.char then library.char.HumanoidRootPart.CFrame = CFrame.new(position) * library.char.HumanoidRootPart.CFrame.Rotation end
							table.remove(networkCache.pathfinding.nodes, 1)
						else
							networkCache.pathfinding.finished = true
						end
					elseif #networkCache.pathfinding.reversed > 0 then
						position = networkCache.pathfinding.reversed[1]
						networkCache.forcePosition = position
						--if library.char then library.char.HumanoidRootPart.CFrame = CFrame.new(position) * library.char.HumanoidRootPart.CFrame.Rotation end
						table.remove(networkCache.pathfinding.reversed, 1)
						networkCache.pathfinding.finished = false
					else
						networkCache.forcePosition = nil
						networkCache.pathfinding.finished = false
					end
				end
				
				if (anti_resolver.active and networkCache.lastUpdate)
					and (tick() - networkCache.spawn) >= 0.95 and not networkCache.teleporting then

					local realPos = position
					local lastPos = networkCache.lastUpdate
					local currentTime = tick()

					local totalDist = (realPos - lastPos).Magnitude
					if totalDist > 9.5 then
						local stepPos = lastPos + (realPos - lastPos).Unit * 9.5
						
						send(self, name, stepPos, angles, gunAngles, time)
						
						networkCache.lastUpdate = stepPos
						networkCache.lastTime = time
						networkCache.updateDebt = 0 
						return
					end

					if (time - networkCache.lastTime) < flags.updaterate then
						return;
					end

					local fakePos = nil
					for i = 1, 64 do
						local offset = Vector3.new(random_range(6), 0, random_range(6))
						local candidate = realPos + offset
						
						if not raycast(realPos, offset) then
							fakePos = candidate
							break
						end
					end

					if fakePos then
						local newPos = fakePos + Vector3.new(random_range(2), 0, random_range(2))
						local newPos2 = newPos + Vector3.new(random_range(2), 0.5, random_range(2))
						if flags.updaterate > 3 then newPos = newPos + vec3(0, 5, 0) end
						send(self, name, realPos, angles, gunAngles, time)
						send(self, name, fakePos, angles, gunAngles, time)
						if flags.updaterate > 2 then send(self, name, newPos, angles, gunAngles, time) end
						if flags.updaterate > 3 then send(self, name, newPos2, angles, gunAngles, time) end

						draw_bullet(realPos, fakePos, false)
						if flags.updaterate > 2 then draw_bullet(fakePos, newPos, false) end
						if flags.updaterate > 3 then draw_bullet(newPos, newPos2, false) end
						
						networkCache.lastUpdate = flags.updaterate > 3 and newPos2 or flags.updaterate > 2 and newPos or fakePos
						networkCache.lastTime = time
						networkCache.updateDebt = 4
						networkCache.forceClientPosition = newPos2
						
						return 
					end
					
					return send(self, name, realPos, angles, gunAngles, time)
				end

				networkCache.forceClientPosition = nil

				if networkCache.teleporting then
					if networkCache.lastUpdate then
						-- god
						send(self, name, networkCache.lastUpdate, angles, gunAngles, time)
						networkCache.updateDebt += 2
						
						if (networkCache.lastUpdate - position).Magnitude > 9.5 then
							position = networkCache.lastUpdate + (position - networkCache.lastUpdate).Unit * 9.5
							
							local rayHitPart = raycast(position, vec3(0, -4, 0))
							if not rayHitPart then
								networkCache.offFloor = (networkCache.offFloor or 0) + (time - (networkCache.lastTime or time))
							else
								networkCache.offFloor = 0
							end

							-- air respawn fix
							if networkCache.offFloor and networkCache.offFloor >= 0.2 then
								position -= vec2(0, 2 * (networkCache.offFloor - 2), 0)
								local rayHitPart, rayPos = raycast(position, vec3(0, -4, 0))
								if rayHitPart then
									position = rayPos + vec3(0, 3, 0)
								end
								position = networkCache.lastUpdate + (position - networkCache.lastUpdate).Unit * 9.5
							end
							networkCache.forceClientPosition = position
						end
					end
				elseif (flags.force_speed and flags.speedkey.active) and networkCache.lastUpdate and (tick() - networkCache.spawn) > 1 then
					send(self, name, networkCache.lastUpdate, angles, gunAngles, time)
					networkCache.updateDebt += 3
					if (networkCache.lastUpdate - position).Magnitude > 7.95 then
						position = networkCache.lastUpdate + (position - networkCache.lastUpdate).Unit * 7.9
					end
				end

				if flags.jitter_move and networkCache.lastUpdate and (tick() - networkCache.spawn) >= 0.7 then
					local new = position:lerp(networkCache.lastUpdate, clamp(math.random() * math.random(-3,3),-2.8,2.8))
					if (new - networkCache.lastUpdate).Magnitude >= 6.5 then
						new = networkCache.lastUpdate + ((new - networkCache.lastUpdate).Unit * 6.5)
					end
					position = new
				end


				networkCache.lastTime = time
				networkCache.lastUpdate = position
				lastTime = time
				return send(self, name, position, angles, gunAngles, time)
			elseif name == "spawn" then
				networkCache = {
					updateDebt = (networkCache and networkCache.updateDebt) or 0,
					spawn = tick(),
					lastTick = network.getTime()
				}
			elseif name == "swapweapon" then
				print(name, ...)
				for _, arg in { ... } do
					if typeof(arg) == "table" then
						print(" Viewing Array", arg, "length:", #arg)
						for key, value in pairs(arg) do
							print("  ", key, value)
						end
						print(" End of Array")
					end
				end
			elseif name == "falldamage" and flags.nofalldamage then
				return
			end

			return send(self, name, ...)
		end

		local localPlayer = game:GetService("Players").LocalPlayer
		local function getAlivePlayers(origin)
			local entries = {}
			local distances = {}

			replicationInterface.operateOnAllEntries(function(player, entry)
				--if player.TeamColor ~= localPlayer.TeamColor then
				if entry._isEnemy and not entry.isDead then
					local player = entry._player
					if (flags.filter_type == "blacklist" and player_list[player.Name].ignore_player) then
						return
					end
					if (flags.filter_type == "whitelist" and not player_list[player.Name].ignore_player) then
						return
					end
					local position = flags.resolver and resolver:resolve(player) or entry._receivedPosition

					if position then
						distances[player] = (position - origin).Magnitude
						table.insert(entries, entry)
					end
				end
			end)

			table.sort(entries, function(entry0, entry1)
				return distances[entry0._player] < distances[entry1._player]
			end)

			return entries
		end

		local onSpawned = charEvents.onSpawned:connect(function(object)
			object._destructor:add(function() -- runs when character is destroyed
				networkCache = {
					updateDebt = (networkCache and networkCache.updateDebt) or 0
				}
				print("i ded")
			end)
		end)
		
		local onPlayerSpawned = statusEvents.onPlayerSpawned:connect(function(player)
			local entry = replicationInterface.getEntry(player)
			if entry then
				entry.isDead = false
			end
		end)

		local onPlayerDied = statusEvents.onPlayerDied:connect(function(array)
			local entry = replicationInterface.getEntry(array.victim)
			if entry then
				entry.isDead = true
			end
		end)

		local thickness = 1
		local corners = {
			middle = Vector3.new(0, 0, 0),
			topLeft = Vector3.new(-1, 1, 0),
			topRight = Vector3.new(1, 1, 0),
			bottomLeft = Vector3.new(-1, -1, 0),
			bottomRight = Vector3.new(1, -1, 0),
		}

		local function thickRaycast(origin, direction, filterlist, whitelist)
			local size = thickness * 0.5
			local cframe = CFrame.new(origin, origin + direction)

			for _, offset in corners do
				offset *= size
				local hit, position, normal = raycast(cframe * offset, direction, filterlist, whitelist)

				if hit then
					return hit, position, normal
				end
			end

			return nil
		end

		local scanVerticies = {}

		local baseVerticies = {
			Vector3.new(0, 0, -1),
			Vector3.new(0, -1, 0),
			Vector3.new(-1, 0, 0),
			Vector3.new(0, 1, 0),
			Vector3.new(1, 0, 0)
		}

		local medVerticies = {
			Vector3.new(-1, 0, -1).Unit,
			Vector3.new(1, 0, -1).Unit,
			Vector3.new(-1, 0, 1).Unit,
			Vector3.new(1, 0, 1).Unit
		} 

		for _, vertex in table.clone(medVerticies) do
			table.insert(medVerticies, vertex + Vector3.new(0, 1, 0))
			table.insert(medVerticies, vertex - Vector3.new(0, 1, 0))
		end

		local highVerticies = {
			Vector3.new(-1, 0, -1).Unit,
			Vector3.new(1, 0, -1).Unit,
			Vector3.new(-1, 0, 1).Unit,
			Vector3.new(1, 0, 1).Unit
		} 

		for _, vertex in table.clone(highVerticies) do
			table.insert(highVerticies, vertex + Vector3.new(0, 1, 0))
			table.insert(highVerticies, vertex - Vector3.new(0, 1, 0))
		end

		for _, vertex in baseVerticies do
			table.insert(highVerticies, vertex)
		end

		local function generateSubSteps()
			local newVerticies = {}

			for _, vertex in medVerticies do
				table.insert(newVerticies, vertex)
			end

			for _, baseVert in scanVerticies do
				for _, diag in medVerticies do
					table.insert(newVerticies, baseVert:lerp(diag, 0.5).Unit)
				end
			end

			return newVerticies
		end

		local function setupVerticies()
			if flags.pf_rage_scan_vertices == "low" then
				scanVerticies = baseVerticies
			elseif flags.pf_rage_scan_vertices == "medium" then
				scanVerticies = medVerticies
			elseif flags.pf_rage_scan_vertices == "high" then
				scanVerticies = highVerticies
			elseif flags.pf_rage_scan_vertices == "extreme" then
				scanVerticies = generateSubSteps()
			else
				scanVerticies = baseVerticies
			end
		end

		local PI = math.pi
		local SQRT5 = math.sqrt(5)
		local GOLDEN_ANGLE = PI * (3 - SQRT5)

		local ModeFunctions = {
			["random"] = function(cframe, vertices, offset)
				local offsets = {}
				for i = 1, #vertices do
					offsets[i] = cframe * (vertices[i] * offset)
				end
				return offsets
			end,

			["advanced"] = function(cframe, vertices, offset)
				local offsets = {}
				local count = #vertices
				for i = 1, count do
					local r = math.sqrt(i / count) * offset
					local theta = i * GOLDEN_ANGLE
					offsets[i] = cframe * Vector3.new(math.cos(theta) * r, math.sin(theta) * r, 0)
				end
				return offsets
			end,

			["sweep"] = function(cframe, vertices, offset)
				local count = #vertices
				local offsets = table.create(count)

				local origin = cframe.Position
				local look = cframe.LookVector

				local right = cframe.RightVector
				local up = cframe.UpVector

				for i = 1, count do
					local t = i / count
					local radius = math.sqrt(t) * offset

					local theta = i * GOLDEN_ANGLE

					local x = cos(theta) * radius
					local y = sin(theta) * radius

					local dir =
						look +
						right * x +
						up * y

					local mag = math.sqrt(dir.X * dir.X + dir.Y * dir.Y + dir.Z * dir.Z)
					dir = dir / mag

					offsets[i] = origin + dir * offset
				end

				return offsets
			end,

			["experimental"] = function(cframe, vertices, offset)
				local offsets = {}
				local origin = networkCache.lastUpdate or cframe.Position
				local weaponController = weaponInterface.getActiveWeaponController()
				local firearm = weaponController and weaponController:getActiveWeapon()

				local bulletSpeed = firearm and firearm:getWeaponStat("bulletspeed") or 3000
				local acceleration = acceleration
				local penetration = firearm and firearm:getWeaponStat("penetrationdepth") or 1

				for i = 1, #vertices do
					local centerPos = cframe.Position
					local targetVertex = cframe * (vertices[i] * offset)

					local low, high = 0, 1
					local bestPoint = targetVertex

					
					for step = 1, 3 do
						local alpha = (low + high) / 2
						local testPoint = centerPos:Lerp(targetVertex, alpha)
						
						local velocity, travelTime = trajectory(origin, acceleration, testPoint, bulletSpeed)
						local isVisible = bulletCheck(origin, testPoint, velocity, acceleration, penetration)
						
						if isVisible then
							bestPoint = testPoint
							high = alpha
						else
							low = alpha
						end
					end
					
					local safetyJitter = Vector3.new(math.random(-1, 1)/200, math.random(-1, 1)/200, 0)
					offsets[i] = bestPoint + safetyJitter
				end
				
				return offsets
			end
		}

		local function getPositionOffsets(origin, target, offset)
			if not offset or offset == 0 then return {origin} end
			
			local mode = flags.pf_rage_algorithm or "random"
			local cframe = CFrame.new(origin, target) * CFrame.Angles(0, 0, math.rad(math.random(1, 90)))
			
			-- Direct lookup - no "if/else" chain
			local scanFunc = ModeFunctions[mode] or ModeFunctions["random"]
			return scanFunc(cframe, scanVerticies, offset)
		end

		--[[local function getPositionOffsets(origin, target, offset)
			if offset then
				local cframe = CFrame.new(origin, target) * CFrame.Angles(0, 0, math.rad(math.random(1, 90)))
				local offsets = {}
		
				for vertexIndex = 1, #scanVerticies do
					table.insert(offsets, cframe * (scanVerticies[vertexIndex] * offset))
				end
		
				return offsets
			end
		
			return {origin}
		end]]
		local function getImpactPoints(origin, velocity, acceleration, travelTime)
			local impacts = {}
			local currentPos = origin
			local step = 0.05
			
			local function samplePos(t)
				return origin + velocity * t + 0.5 * acceleration * t * t
			end

			local t = step
			while t <= travelTime do
				local nextPos = samplePos(t)
				local direction = nextPos - currentPos
				
				local hitInstance, hitPos, hitNormal = raycast(currentPos, direction)

				if hitInstance then
					table.insert(impacts, hitPos)
					
					local dirUnit = direction.Unit
					local piercePos = hitPos + (dirUnit * 0.05)
					
					local farPoint = piercePos + (dirUnit * 10)
					local backHit, backPos = raycast(farPoint, -dirUnit * 10, {hitInstance}, true)
					
					if backHit then
						table.insert(impacts, backPos)
						currentPos = backPos + (dirUnit * 0.05)
					else
						currentPos = piercePos
					end
				else
					currentPos = nextPos
				end
				
				t = t + step
			end

			return impacts
		end

		local function getPositionOffsetWithRaycast(origin, target, offset, originOffset)
			if offset then
				local cframe = CFrame.new(origin, target) * CFrame.Angles(0, 0, rad(random(1, 90)))
				local offsets = {}

				for vertexIndex = 1, #scanVerticies do
					local offsetVector = scanVerticies[vertexIndex]
					local relativeDestination = offsetVector * originOffset
					local worldDestination = cframe:VectorToWorldSpace(relativeDestination)
					local hit, hitPosition = raycast(origin, worldDestination)
					
					local travelDistance = originOffset
					
					if hit then
						local availableDist = (hitPosition - origin).Magnitude
						
						if availableDist < 2 then
							continue 
						end
						
						travelDistance = availableDist - 1
					end

					local newOrigin = origin + (cframe:VectorToWorldSpace(offsetVector) * travelDistance)
					local endPoint = newOrigin + (cframe:VectorToWorldSpace(offsetVector) * (offset or 0))

					table.insert(offsets, {newOrigin, endPoint})
				end

				return offsets
			end

			return {{origin, origin}}
		end

		local raycastStep = 1 / 30
		--[[local function scanPositions(origin, target, accel, speed, penetration)
			local origins = getPositionOffsets(origin, target, find(flags.origin_scan_mode, "origin") and flags.origin_shift or 0)
			local targets = getPositionOffsets(target, origin, find(flags.origin_scan_mode, "target") and flags.target_shift or 0)
		
			for originIndex = 1, #origins do
				local newOrigin = origins[originIndex]
				
				for targetIndex = 1, #targets do
					local newTarget = targets[targetIndex]
					local velocity, hitTime = trajectory(newOrigin, accel, newTarget, speed)
		
					if bulletCheck(newOrigin, newTarget, velocity, accel, penetration, raycastStep) then
						return newOrigin, newTarget, velocity, hitTime
					end
				end
			end
		
			return false
		end]]

		local function scanPositions(origin, target, accel, speed, penetration)
			local originScanMode = flags.origin_scan_mode
			local useOrigin = find(originScanMode, "origin")
			local useTarget = find(originScanMode, "target")
			
			local originShift = useOrigin and flags.origin_shift or 0
			local targetShift = useTarget and flags.target_shift or 0
			local v, ht = trajectory(origin, accel, target, speed)
			if bulletCheck(origin, target, v, accel, penetration, raycastStep) then
				return origin, target, v, ht
			end
			local origins = getPositionOffsets(origin, target, originShift)
			local targets = getPositionOffsets(target, origin, targetShift)
			local targetsChecked = 0
			for i = 1, #origins do
				local newOrigin = origins[i]
				for j = 1, #targets do
					local newTarget = targets[j]
					if newOrigin == origin and newTarget == target then continue end
					targetsChecked += 1
					local velocity, hitTime = trajectory(newOrigin, accel, newTarget, speed)
					if bulletCheck(newOrigin, newTarget, velocity, accel, penetration, raycastStep) then
						return newOrigin, newTarget, velocity, hitTime
					end

					if targetsChecked >= flags.max_targets then
						break
					end
				end
			end

			return false
		end

		--[[local function scanPositionsWithOrigin(origin, target, accel, speed, penetration)
			local origins = getPositionOffsets(origin, target, flags.origin_shift, find(flags.origin_scan_mode, "teleport") and flags.origin_teleport or 0)
			local targets = getPositionOffsets(target, origin, find(flags.origin_scan_mode, "target") and flags.target_shift or 0)
		
			for originIndex = 1, #origins do
				local originPos, newOrigin = table.unpack(origins[originIndex])
				
				for targetIndex = 1, #targets do
					local newTarget = targets[targetIndex]
					local velocity, hitTime = trajectory(newOrigin, accel, newTarget, speed)
		
					if bulletCheck(newOrigin, newTarget, velocity, accel, penetration, raycastStep) then
						return originPos, newOrigin, newTarget, velocity, hitTime
					end
				end
			end
		
			return false
		end]]

		--[[local function scanPositionsWithOrigin(origin, target, accel, speed, penetration)
			local originScanMode = flags.origin_scan_mode
			local isTeleport = find(originScanMode, "teleport")
			local useTargetShift = find(originScanMode, "target")
			local teleportDist = isTeleport and flags.origin_teleport or 0
			local targetShift = useTargetShift and flags.target_shift or 0
			local delayThreads = flags.pf_rage_multithreading
			local origins = getPositionOffsetWithRaycast(origin, target, flags.origin_shift, teleportDist)
			local targets = getPositionOffsets(target, origin, targetShift)
			local targetsChecked = 0
			for i = 1, #origins do
				local data = origins[i]
				local originPos = data[1]
				local newOrigin = data[2]
				
				for j = 1, #targets do
					local newTarget = targets[j]
					targetsChecked += 1
					local velocity, hitTime = trajectory(newOrigin, accel, newTarget, speed)
					if bulletCheck(newOrigin, newTarget, velocity, accel, penetration, raycastStep) then
						return originPos, newOrigin, newTarget, velocity, hitTime
					end
					
					if targetsChecked >= flags.max_targets then
						break
					end
				end
			end

			return false
		end]]

		--[[local function scanPositionsWithOrigin(origin, target, accel, speed, penetration)
			local originScanMode = flags.origin_scan_mode
			local isTeleport = find(originScanMode, "teleport")
			local useTargetShift = find(originScanMode, "target")
			
			local maxTeleportDist = isTeleport and flags.origin_teleport or 0
			local targetShift = useTargetShift and flags.target_shift or 0
			local targetsChecked = 0

			--print(maxTeleportDist)
			
			for currentDist = 0, maxTeleportDist, 32 do
				local scanDist = math.min(currentDist, maxTeleportDist)
				
				local origins = getPositionOffsetWithRaycast(origin, target, flags.origin_shift, scanDist)
				local targets = getPositionOffsets(target, origin, targetShift)
				
				for i = 1, #origins do
					local data = origins[i]
					local originPos = data[1]
					local newOrigin = vec3(data[2].X, clamp(data[2].Y, origin.Y - 128, origin.Y + 128), data[2].Z)
					local rayInst, rayPos, _, _, rayDist = raycast(newOrigin, vec3(0, -1000, 0))
					--return result and result.Instance, result and result.Position, result and result.Normal, result and result.Distance
					if rayDist and rayDist >= 256 then
						newOrigin = rayPos + vec3(0, 3.5, 0)
					end
					
					for j = 1, #targets do
						local newTarget = targets[j]
						targetsChecked += 1
						
						local velocity, hitTime = trajectory(newOrigin, accel, newTarget, speed)
						
						if bulletCheck(newOrigin, newTarget, velocity, accel, penetration, raycastStep) then
							return originPos, newOrigin, newTarget, velocity, hitTime
						end
						
						if targetsChecked >= flags.max_targets then
							return false
						end
					end
				end

				if maxTeleportDist == 0 then break end
			end

			return false
		end]]

		--[[local function scanPositionsWithOrigin(origin, target, accel, speed, penetration)
			local origins = getPositionOffsetWithRaycast(origin, target, flags.origin_shift, find(flags.origin_scan_mode, "teleport") and flags.origin_teleport or 0)
			local targets = getPositionOffsets(target, origin, find(flags.origin_scan_mode, "target") and flags.target_shift or 0)
			
			local targetsChecked = 0
			local maxLimit = flags.max_targets or 16
			local lerpSteps = {1, 0.75, 0.5, 0.25} 

			for targetIndex = 1, #targets do
				local newTarget = targets[targetIndex]
				
				for originIndex = 1, #origins do
					local originData = origins[originIndex]
					local startPos, offsetPos = originData[1], originData[2]
					
					for _, alpha in ipairs(lerpSteps) do
						local sampledPos = startPos:lerp(offsetPos, alpha)
						
						-- 1. Use your custom Wall-Push logic
						local safePos = sampledPos
						for i = 1, 4 do -- Matching your pathfind loop
							safePos = pushOffWalls(safePos, 1.45)
						end

						-- 2. Use your custom Snap-To-Ground logic
						-- Cast from 3 studs up to 10 studs down
						local hit, hitPos = raycast(safePos + Vector3.new(0, 3, 0), Vector3.new(0, -10, 0))
						
						local newOrigin
						if hit then
							-- Uses your exact offset: 2.8 studs above hit point
							newOrigin = hitPos + Vector3.new(0, 2.8, 0)
						else
							-- If no ground, skip this step to avoid rubberbanding in air
							continue
						end

						local velocity, hitTime = trajectory(newOrigin, accel, newTarget, speed)
						targetsChecked = targetsChecked + 1
						
						if bulletCheck(newOrigin, newTarget, velocity, accel, penetration) then
							library:spawnLog(
								`BulletCheck success [origin={tostring(newOrigin)}, target={tostring(newTarget)}]`
							)
							return startPos, newOrigin, newTarget, velocity, hitTime
						end

						if targetsChecked >= maxLimit then return false end
					end
				end
			end

			return false
		end

		local function scanPositionsWithOrigin(origin, target, accel, speed, penetration)
			local origins = getPositionOffsetWithRaycast(origin, target, flags.origin_shift, find(flags.origin_scan_mode, "teleport") and flags.origin_teleport or 0)
			local targets = getPositionOffsets(target, origin, find(flags.origin_scan_mode, "target") and flags.target_shift or 0)
		
			for originIndex = 1, #origins do
				local originPos, newOrigin = table.unpack(origins[originIndex])
				newOrigin = vec3(newOrigin.X, origin.Y, newOrigin.Z)
				
				for targetIndex = 1, #targets do
					local newTarget = targets[targetIndex]
					local velocity, hitTime = trajectory(newOrigin, accel, newTarget, speed)
		
					if bulletCheck(newOrigin, newTarget, velocity, accel, penetration, raycastStep) then
						return originPos, newOrigin, newTarget, velocity, hitTime
					end
				end
			end
		
			return false
		end]]

		local function scanPositionsWithOrigin(origin, target, accel, speed, penetration)
			local origins = getPositionOffsetWithRaycast(origin, target, flags.origin_shift, find(flags.origin_scan_mode, "teleport") and flags.origin_teleport or 0)
			local targets = getPositionOffsets(target, origin, find(flags.origin_scan_mode, "target") and flags.target_shift or 0)
		
			for originIndex = 1, #origins do
				local originPos, newOrigin = table.unpack(origins[originIndex])
				newOrigin = vec3(newOrigin.X, origin.Y, newOrigin.Z)
				
				for targetIndex = 1, #targets do
					local newTarget = targets[targetIndex]
					local velocity, hitTime = trajectory(newOrigin, accel, newTarget, speed)
		
					if bulletCheck(newOrigin, newTarget, velocity, accel, penetration, raycastStep) then
						return originPos, newOrigin, newTarget, velocity, hitTime
					end
				end
			end
		
			return false
		end

		local threadsAlive = 0
		local function newDeferFunction(func, ...)
			threadsAlive += 1
			local result = {func(...)}
			threadsAlive -= 1
			return table.unpack(result)
		end
		local eventListener = Instance.new("BindableEvent")
		local function callWithReturn(func, ...)
			local result
			task.spawn(function(...)
				threadsAlive += 1
				result = { func(...) }
				eventListener:Fire()
				threadsAlive -= 1
			end, ...)

			eventListener.Event:Wait()
			return table.unpack(result)
		end

		local projectiles, debree = {}, {}
		local function updateProjectiles(delta)
			for i,v in projectiles do
				v.Velocity = v.Velocity * (1 - delta * 2)
				v.TimeInWorld -= delta
				v.Object.CFrame += v.Velocity * delta
				if v.Outline then
					v.Outline.CFrame = v.Object.CFrame
				end
				if v.TimeInWorld <= 0 then
					v.Object:Destroy()
					table.remove(projectiles, i)
				end
				if v.Rot then
					v.Object.CFrame *= CFrame.fromAxisAngle(v.Rot * delta, 0.1)
				end
			end
			for i,v in debree do
				v.TimeInWorld -= delta
				v.Object.Transparency = 1.0 - (v.TimeInWorld / v.TotalTime)
				v.Outline.Transparency = v.Object.Transparency
				v.Intensity += delta / 5
				v.Intensity = math.min(v.Intensity, 1)
				v.Object.CFrame *= (CFrame.Angles(v.AngleX*delta,v.AngleY*delta,v.AngleZ*delta)*CFrame.new(v.PosX*delta,v.PosY*delta,v.PosZ*delta)):Lerp(CFrame.identity, v.Intensity)
				v.Outline.CFrame = v.Object.CFrame
				if v.TimeInWorld <= 0 then
					v.Outline:Destroy()
					v.Object:Destroy()
					table.remove(debree, i)
				end
			end
		end

		local path = {}
		for i = 1, 64 do
			path[i] = library:create("Part", {
				Anchored = true,
				CanCollide = false,
				Material = Enum.Material.Neon,
				Color = Color3.new(1, 0, 0),
				Size = Vector3.new(0.1, 0.1, 0.1),
				Transparency = 1,
			})
		end

		local function setupPathpoints()
			local from =
				(library.char and library.char:FindFirstChild("HumanoidRootPart"))
				and library.char.HumanoidRootPart.Position
				or (networkCache.lastUpdate or Vector3.zero) - vec3(0,3,0)

			for i = 1, 64 do
				local part = path[i]
				local node = (networkCache.pathfinding and networkCache.pathfinding.nodes) and networkCache.pathfinding.nodes[i]

				if not node then
					part.Parent = nil
					continue
				end

				local distance = (from - node).Magnitude

				part.Parent = workspace
				part.Transparency = i <= 3 and 1 - i / 3 or 0
				part.Color = Color3.new(1,1,1):Lerp(themes.preset.button_alt, clamp(i/3,0,1))
				part.Size = Vector3.new(0.1, 0.1, distance)
				part.CFrame =
					CFrame.new(from, node) *
					CFrame.new(0, 0, -distance / 2)

				from = node
			end
		end

		local function draw_line(from, to)
			local part = library:create("Part", {
				Anchored = true,
				CanCollide = false,
				Color = themes.preset.button_alt,
				Size = Vector3.new(0.1, 0.1, 0.1),
				Material = Enum.Material.Neon,
				Color = Color3.new(1, 0, 0),
				Transparency = 1,
			})

			part.Parent = workspace

			local distance = (from - to).Magnitude
			part.CFrame = CFrame.new(from, to) * CFrame.new(0, 0, -distance / 2)
			part.Size = Vector3.new(0, 0, distance)

			tween_service:Create(part, TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut,0,false), {Transparency = 0.5}):Play()
			tween_service:Create(part, TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut,0,false), {Size = Vector3.new(0.1, 0.1, distance)}):Play()
			task.delay(12.89, function()
				part:Destroy()
			end)
		end

		local randomGen = Random.new()

		local originalShoot = clonefunction(firearmObject.fireRound)
		local maxTeleportStuds = 9.9
		local runService = game:GetService("RunService")

		

		local function buildMultiTargetBullets(originPos, entryList, weapon, data)
			local accel = publicSettings.bulletAcceleration
			local speed = data.bulletspeed
			local penetration = data.penetrationdepth
			local basePellets = weapon and (weapon:getWeaponStat("pelletcount") or 1) or (data.pelletcount or 1)
			local bullets = {}
			local bulletTargets = {}
			for i = 1, #entryList do
				local e = entryList[i]
				local pos = e and (flags.resolver and resolver:resolve(e._player) or e._receivedPosition)
				if pos then
					local o2, firepos2, v2, ht2 = scanPositions(originPos, pos, accel, speed, penetration)
					if firepos2 then
						for p = 1, 1 do
							local ticket = debug.getupvalue(originalShoot, 11) + 1
							table.insert(bullets, {v2.Unit, ticket})
							table.insert(bulletTargets, {player = e._player, target = firepos2})
							debug.setupvalue(originalShoot, 11, ticket)
						end
					end
				end
			end

			local cap = 32
			if #bullets > basePellets then
				while #bullets > basePellets do
					table.remove(bullets)
					table.remove(bulletTargets)
				end
			end
			return bullets, bulletTargets
		end

		local lastVertUpdate = tick()

		local function pathfindToLOS(targetEntry)
			local targetPos = flags.resolver and resolver:resolve(targetEntry._player) or targetEntry._receivedPosition
			local myRoot = charInterface:getCharacterObject():getRootPart()
			local myPos = myRoot.Position
			
			if not targetPos or not myPos then return end

			local controller = weaponInterface.getActiveWeaponController()
			local weapon = controller and controller:getActiveWeapon()
			if not weapon then return end
			
			local accel = publicSettings.bulletAcceleration
			local speed = weapon._weaponData.bulletspeed
			local penetration = weapon._weaponData.penetrationdepth
			
			local bestPoint = nil
			local bestScore = -math.huge
			
			-- Directional Math
			local dirToEnemy = (targetPos - myPos).Unit
			local sideStep = Vector3.new(-dirToEnemy.Z, 0, dirToEnemy.X)

			-- INCREASED SCAN RADIUS: 
			-- We check a 5x5 grid around a projected forward point
			for x = -3, 3 do
				for z = -1, 4 do -- Prioritize forward (z) more than backward
					local forwardDist = z * 20
					local sideDist = x * 15
					
					local testPoint = myPos + (dirToEnemy * forwardDist) + (sideStep * sideDist)

					local hit, groundPos = raycast(testPoint + Vector3.new(0, 10, 0), Vector3.new(0, -25, 0), {charInterface:getCharacterObject():getRealRootPart().Parent})
					
					if hit and groundPos then
						local finalPoint = groundPos + Vector3.new(0, 2, 0)

						local footOrigin = finalPoint + Vector3.new(0, 3, 0)
						local originPosCandidate, newOrigin, newTarget, velocity, hitTime = scanPositionsWithOrigin(footOrigin, targetPos, accel, speed, penetration)

						local canIHit, canTheyHitMe
						if originPosCandidate and newOrigin then
							canIHit = bulletCheck(newOrigin, newTarget, velocity, accel, penetration, 1/30)
							local enemyVel, enemyTime = trajectory(newTarget, accel, newOrigin, speed)
							canTheyHitMe = bulletCheck(newTarget, newOrigin, enemyVel, accel, penetration, 1/30)
						else
							local fallbackVel, fallbackHit = trajectory(footOrigin, accel, targetPos, speed)
							velocity = fallbackVel
							hitTime = fallbackHit
							canIHit = bulletCheck(footOrigin, targetPos, fallbackVel, accel, penetration, 1/30)
							local enemyVel, enemyTime = trajectory(targetPos, accel, footOrigin, speed)
							canTheyHitMe = bulletCheck(targetPos, footOrigin, enemyVel, accel, penetration, 1/30)
						end

						local score = 0
						local distToTarget = (targetPos - finalPoint).Magnitude
						
						score = score - (distToTarget * 0.1)
						
						if canIHit and not canTheyHitMe then
							score = score + 1000
							if originPosCandidate then
								score = score + 500
							end
						elseif not canIHit and not canTheyHitMe then
							score = score + 250
						elseif canIHit and canTheyHitMe then
							score = score - 100
						end

						if score > bestScore then
							bestScore = score
							bestPoint = finalPoint
						end
					end
				end
			end

			-- 3. Final Execution with Validation
			if bestPoint then
				-- Optional: Debug visualizer (uncomment to see where it's trying to go)
				-- debug_part.Position = bestPoint
				
				pathfind(bestPoint)
			else
				pathfind(targetPos)
			end
		end

		
		function network:startTeleport(origin, target, bulletSpeed)
			if networkCache.isBusy or networkCache.instantTeleport then return false end

			if networkCache.lastTeleport and (tick() - networkCache.lastTeleport) < 0.5 then
				return false
			end

			local cache = {nodes = {}, visited = {}}
			networkCache.networkDebt = 2
			networkCache.lastTeleport = tick()

			local STEP_SIZE = 9.9 
			local maxDist = flags.warp_distance or 150 
			local penetration = 2
			local accel = acceleration or Vector3.new(0, -196.2, 0)

			local pathfinder = services.pathfindingService:CreatePath({
				AgentRadius = 2.0,
				AgentHeight = 5,
				AgentCanJump = true,
				WaypointSpacing = 4
			})

			local success, _ = pcall(function()
				pathfinder:ComputeAsync(origin, target)
			end)

			if not success or pathfinder.Status ~= Enum.PathStatus.Success then return false end

			local waypoints = pathfinder:GetWaypoints()
			local pathPoints = {}
			for _, wp in ipairs(waypoints) do
				table.insert(pathPoints, wp.Position + Vector3.new(0, 3, 0))
			end

			local finalNodes = {}
			local currentPosition = origin
			local totalDistanceTravelled = 0

			while totalDistanceTravelled < maxDist do
				local nextPoint = nil
				local foundPoint = false
				for i = 1, #pathPoints do
					local p = pathPoints[i]
					local d = (p - currentPosition).Magnitude
					
					if d >= STEP_SIZE then
						nextPoint = currentPosition + (p - currentPosition).Unit * STEP_SIZE
						foundPoint = true
						for j = 1, i - 1 do table.remove(pathPoints, 1) end
						break
					end
				end
				if not foundPoint then
					nextPoint = pathPoints[#pathPoints]
					if not nextPoint or (nextPoint - currentPosition).Magnitude < 0.1 then break end
				end
				local resPos, newOrigin, newTarget, velocity, hitTime = scanPositionsWithOrigin(nextPoint, target, accel, bulletSpeed, penetration)
				local moveVel, moveTime = trajectory(currentPosition, accel, nextPoint, bulletSpeed)
				if moveVel and moveTime and bulletCheck(currentPosition, nextPoint, moveVel, accel, penetration, moveTime) then
					
					table.insert(finalNodes, nextPoint)
					currentPosition = nextPoint
					totalDistanceTravelled = (currentPosition - origin).Magnitude

					if resPos and newOrigin then
						local enemyVel, enemyTime = trajectory(newTarget, accel, newOrigin, bulletSpeed)
						local canTheyHitMe = false
						if enemyVel and enemyTime then
							canTheyHitMe = bulletCheck(newTarget, newOrigin, enemyVel, accel, penetration, enemyTime)
						end
						if not canTheyHitMe then
							table.insert(finalNodes, nextPoint) 
							cache.nodes = finalNodes
							networkCache.instantTeleport = cache
							for _, node in ipairs(finalNodes) do
								task.spawn(function()
									local p = Instance.new("Part")
									p.Size = Vector3.new(0.1, 0.1, 0.1)
									p.Anchored, p.CanCollide, p.CanTouch = true, false, false
									p.Shape, p.Material = Enum.PartType.Ball, Enum.Material.Neon
									p.Color, p.CFrame, p.Parent = Color3.new(0, 1, 1), CFrame.new(node), workspace
									
									tween_service:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
										Size = Vector3.new(1.4, 1.4, 1.4), Transparency = 1
									}):Play()
									task.wait(0.6)
									p:Destroy()
								end)
							end
							return true
						end
					end
				else
					break
				end

				if not foundPoint then break end
			end

			if #finalNodes > 0 then
				cache.nodes = finalNodes
				networkCache.instantTeleport = cache
				return true
			end

			return false
		end

		function tryScan()
			if flags.rageaim and networkCache.lastUpdate and not networkCache.teleporting then
				if tick() - lastVertUpdate > 0.35 then
					task.defer(setupVerticies)
					lastVertUpdate = tick()
				end

				local origin = networkCache.lastUpdate
				local entries = getAlivePlayers(origin)

				if flags.auto_move and entries[1] and entries[1]._receivedPosition then
					thread((flags.auto_peek and pathfindToLOS or pathfind), flags.auto_peek and entries[1] or entries[1]._receivedPosition)
				end

				for i = 1, #entries do
					if find(flags.origin_scan_mode, "warp") and entries[i]._receivedPosition then
						network:startTeleport(origin, entries[i]._receivedPosition, 3000)
						break
					end
				end

				for index = 1, #entries do
					if flags.pf_rage_multithreading then
						thread(scanPlayer, entries[index], entries[index]._receivedPosition)
					else
						scanPlayer(entries[index], entries[index]._receivedPosition)
					end
				end
			end
		end

		function scanPlayer(entry, position)
			if flags.rageaim and networkCache.lastUpdate and not networkCache.teleporting then

				-- Vertex Setup Update
				if tick() - lastVertUpdate > 0.35 then
					task.defer(setupVerticies)
					lastVertUpdate = tick()
				end

				local controller = weaponInterface.getActiveWeaponController()
				local weapon = controller and controller:getActiveWeapon()

				if not weapon then return end
				if not weapon._nextShot then return end

				-- Condition check for firing
				if weapon and (not roundSystem.roundLock) and ((weapon._magCount > 0) or (weapon._spareCount > 0)) and ((not weapon._nextShot) or (gameClock.getTime() >= weapon._nextShot)) then
					local rpm = weapon:getWeaponStat("firecap") or (weapon:getWeaponStat("autoburst") and weapon._auto and weapon:getWeaponStat("burstfirerate")) or weapon:getFirerate()
					
					local data = weapon._weaponData
					local penetration = data.penetrationdepth
					local speed = data.bulletspeed
					local origin = networkCache.lastUpdate

					-- Auto-peek / Pathfinding logic (Using the passed player/position)
					if flags.auto_move and entry then
						thread((flags.auto_peek and pathfindToLOS or pathfind), flags.auto_peek and entry or position)
					end

					-- Warp Scan Mode
					if find(flags.origin_scan_mode, "warp") then
						network:startTeleport(networkCache.lastUpdate, position, speed)
					end

					if not networkCache.rage then
						networkCache.rage = {
							scans = 0,
							lastScan = 0
						}
					end

					-- Single Player Logic (Arguments: entry, position)
					local targetPosition = flags.resolver and resolver:resolve(entry._player) or position
					local originPos, firepos, target, velocity, travelTime

					-- Damage Prediction
					if flags.damageprediction then
						local futureDamage = dp_cleanup(entry._player)
						local predictedHealth = (entry._health or 100) - futureDamage

						if predictedHealth <= -5 then
							return
						end
					end

					-- Spider/Origin Scanning
					if flags.spider and (networkCache.rage.scans < 4) and (network.getTime() - networkCache.rage.lastScan > 1 / 30) and (network.getTime() - (networkCache.lastTick or 0) > 0.1) then 
						originPos, firepos, target, velocity, travelTime = scanPositionsWithOrigin(origin, targetPosition, publicSettings.bulletAcceleration, speed, penetration)
						if not originPos then
							firepos, target, velocity, travelTime = scanPositions(origin, targetPosition, publicSettings.bulletAcceleration, speed, penetration)
							networkCache.rage.scans = 0
						end
						networkCache.rage.lastScan = network.getTime()
					else
						firepos, target, velocity, travelTime = scanPositions(origin, targetPosition, publicSettings.bulletAcceleration, speed, penetration)
						networkCache.rage.scans = 0
					end
					
					if firepos then
						local function callback()
							if weapon._nextShot and gameClock.getTime() < weapon._nextShot then
								return
							end

							-- Auto-Reload
							if weapon._magCount < 1 then
								if weapon._spareCount >= data.magsize then
									weapon._magCount = data.magsize
									weapon._spareCount = weapon._spareCount - weapon._magCount
								else
									weapon._magCount = weapon._spareCount
									weapon._spareCount = 0
								end
								network:send("reload")
							end

							local bullets = {}
							local bulletData = {
								camerapos = originPos or origin,
								firepos = firepos,
								bullets = bullets
							}


							-- Ticket Generation
							for _ = 1, (weapon:getWeaponStat("pelletcount") or 1) do
								local ticket = debug.getupvalue(originalShoot, 11) + 1
								table.insert(bullets, {velocity.Unit, ticket})
								debug.setupvalue(originalShoot, 11, ticket)
							end

							weapon:fireInput("shoot", network.getTime())

							-- Register DP
							if flags.damageprediction then
								local dmg = estimateDamage(weapon, (origin - target).Magnitude)
								local pellets = weapon:getWeaponStat("pelletcount") or 1
								local b_speed = weapon._weaponData.bulletspeed or 3000
								dp_register(entry._player, dmg * pellets, (origin - target).Magnitude, b_speed)
							end

							-- Impacts & Visuals
							if flags.impacts then
								local traj_vel, traj_time = trajectory(firepos, acceleration, target, speed)
								local hits = getImpactPoints(firepos, traj_vel, acceleration, penetration, traj_time)
								for _, p in hits do
									local impact = library:create("Part",{
										Size = vec3(),
										Anchored = true,
										CanCollide = false,
										CanQuery = false,
										CanTouch = false,
										Color = themes.preset.button_alt,
										CFrame = cf(p, firepos),
										Material = Enum.Material.ForceField,
										Parent = workspace.Ignore
									})
									local selection = library:create("SelectionBox", {
										Adornee = impact,
										LineThickness = 0.01,
										Color3 = themes.preset.button_alt,
										SurfaceColor3 = themes.preset.button_alt,
										Transparency = 0.2,
										SurfaceTransparency = 0.8,
										Parent = impact
									})
									local mesh = library:create("SpecialMesh", {
										MeshType = Enum.MeshType.Brick,
										TextureId = "rbxassetid://10398333767",
										Scale = vec3(),
										Parent = impact
									})

									tween_service:Create(mesh, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = vec3(0.5, 0.5, 0.5)}):Play()
									tween_service:Create(impact, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = vec3(0.5, 0.5, 0.5)}):Play()
									
									task.delay(3.5, function()
										tween_service:Create(mesh, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Scale = vec3()}):Play()
										tween_service:Create(impact, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = vec3()}):Play()
										task.delay(0.5, game.Destroy, impact)
									end)
								end
							end

							-- Rapidfire Exploits
							if tickbase_manip.active and burst_exploit.active then
								local fm_index = (weapon._firemodeIndex % #weapon:getWeaponStat("firemodes")) + 1
								setreadonly(weapon._weaponData, false)
								weapon._weaponData.burstfirerate = 5
								weapon._firemodeIndex = fm_index
								weapon._burst = 1
								if not table.find(weapon:getWeaponStat("firemodes"), "SWITCH") then
									setreadonly(weapon:getWeaponStat("firemodes"), false)
									table.insert(weapon:getWeaponStat("firemodes"), "SWITCH")
									setreadonly(weapon:getWeaponStat("firemodes"), true)
								end
								setreadonly(weapon._weaponData, true)

								if flags.rapidfire_type == "regular" then
									library:shift_tickbase()
									send(network, "newbullets", weapon.uniqueId, bulletData, gameClock.getTime())
									for _, b in bullets do send(network, "bullethit", weapon.uniqueId, entry._player, target, "Head", b[2], gameClock.getTime()) end
								elseif flags.rapidfire_type == "onshot" then
									send(network, "newbullets", weapon.uniqueId, bulletData, gameClock.getTime())
									for _, b in bullets do send(network, "bullethit", weapon.uniqueId, entry._player, target, "Head", b[2], gameClock.getTime()) end
								elseif flags.rapidfire_type == "triple" then
									local shifts = 0
									repeat
										shifts += 1
										library:shift_tickbase()
										send(network, "newbullets", weapon.uniqueId, bulletData, gameClock.getTime())
										for _, b in bullets do send(network, "bullethit", weapon.uniqueId, entry._player, target, "Head", b[2] + (shifts - 1), gameClock.getTime()) end
									until shifts >= 3
								end
							else
								send(network, "newbullets", weapon.uniqueId, bulletData, gameClock.getTime())
								for _, b in bullets do send(network, "bullethit", weapon.uniqueId, entry._player, target, "Head", b[2], gameClock.getTime()) end
							end

							-- Tracers & Audio
							draw_bullet(firepos, -(firepos - target).Unit * 2048, true)
							draw_bullet(origin, firepos, false)
							--draw_line(origin, firepos, false)
							effects.muzzleflash(weapon._barrelPart, data.hideflash, 0.9)

							if data.type == "SNIPER" then audioSystem.play("metalshell", 0.1)
							elseif data.type == "SHOTGUN" then audioSystem.play("shotWeaponshell", 0.2)
							elseif data.type == "REVOLVER" and not data.caselessammo then audioSystem.play("metalshell", 0.15, 0.8) end

							if data.sniperbass then
								audioSystem.play("1PsniperBass", 0.75)
								audioSystem.play("1PsniperEcho", 1)
							end

							local fireSound = (flags.fakeragesound and 'rbxassetid://73029807886084') or data.firesoundid
							audioSystem.playSoundId(fireSound, 2, data.firevolume, data.firepitch, weapon._barrelPart, nil, 0, 0.05)

							if flags.shoot_effects then
								for i = 1, 8 do
									local trailPart = _assets.Trails.A:Clone()
									trailPart.CFrame = barrel.CFrame * CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360)))
									trailPart.CanCollide = false
									trailPart.Anchored = true
									trailPart.Transparency = 1
									for _, trailObject in trailPart:GetDescendants() do
										if not trailObject:IsA("Trail") then continue end
										trailObject.Color = ColorSequence.new(flags.shoot_effects_color.Color, flags.shoot_effects_color.Color:Lerp(rgb(), .3))
									end
									trailPart.Parent = workspace.Terrain
									table.insert(projectiles,{
										Object = trailPart,
										TimeInWorld = flags.shoot_effects_lifetime,
										Velocity = Vector3.new(math.random(-16,16),math.random(-16,16),math.random(-16,16))
									})
								end

								for i = 1, 6 do
									local trailPart = _assets.Trails.A:Clone()
									trailPart.CFrame = barrel.CFrame * CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360)))
									trailPart.CanCollide = false
									trailPart.Anchored = true
									trailPart.Transparency = 0
									trailPart.Material = Enum.Material.Neon
									trailPart.Color = flags.shoot_effects_color.Color
									trailPart.Parent = workspace.Terrain
									local outline = _assets.Trails.A:Clone()
									outline.CFrame = barrel.CFrame
									outline.CanCollide = false
									outline.Anchored = true
									outline.Transparency = 0
									outline.Material = Enum.Material.ForceField
									outline.Size *= 1.1
									outline.Color = flags.shoot_effects_color.Color
									outline.Parent = trailPart
									outline:ClearAllChildren()
									for _, trailObject in trailPart:GetDescendants() do
										if not trailObject:IsA("Trail") then continue end
										trailObject.Color = ColorSequence.new(flags.shoot_effects_color.Color, flags.shoot_effects_color.Color:Lerp(rgb(), .3))
									end
									table.insert(debree,{
										Object = trailPart,
										Outline = outline,
										TimeInWorld = flags.shoot_effects_lifetime or 5,
										TotalTime = flags.shoot_effects_lifetime or 5,
										AngleX = math.random(-8,8),
										AngleY = math.random(-8,8),
										AngleZ = 0,
										PosX = randomGen:NextNumber(5,10),
										PosY = randomGen:NextNumber(5,10),
										PosZ = randomGen:NextNumber(5,10),
										Intensity = 0
									})
								end
							end

							weapon._magCount = weapon._magCount - 1
							local shotTime = modules.GameClock.getTime()
							weapon._nextShot = shotTime + (((weapon._burst > 0 and weapon._weaponData.firecap) and 60 / weapon._weaponData.firecap) or ((weapon:isAiming() and weapon._weaponData.aimedfirerate) and 60 / weapon._weaponData.aimedfirerate) or (60 / rpm))
							--[[
							if weaponObject._burst <= 0 and (weaponObject:getWeaponStat("firecap") and (weaponObject:getFiremode() ~= true and weaponObject:getFiremode() ~= 1)) then
								weaponObject._nextShot = currentTime + 60 / weaponObject:getWeaponStat("firecap")
							elseif weaponObject:isAiming() and weaponObject:getActiveAimStat("aimedfirerate") then
								weaponObject._nextShot = weaponObject._nextShot + 60 / weaponObject:getActiveAimStat("aimedfirerate")
							else
								weaponObject._nextShot = weaponObject._nextShot + 60 / weaponObject:getFirerate()
							end
			]]
							networkCache.lastTime = shotTime

							-- OnShot Loop
							if flags.rapidfire_type == "onshot" and tickbase_manip.active and burst_exploit.active then
								repeat
									library:shift_tickbase()
									task.wait()
								until gameClock.getTime() >= weapon._nextShot or library:get_tickbase() <= 0
							end
						end

						-- Teleport Queue Execution
						if originPos then
							local teleports = {}
							local path = services.pathfindingService:CreatePath({
								AgentRadius = 2.5,
								AgentHeight = 3,
								AgentCanJump = true,
								WaypointSpacing = 5
							})

							local success, _ = pcall(function()
								path:ComputeAsync(origin, originPos)
							end)

							local tpDistance = (originPos - origin).Magnitude
							local direction = (originPos - origin).Unit
							for i = 1, math.floor(tpDistance / maxTeleportStuds) do
								table.insert(teleports, origin + (direction * i * maxTeleportStuds))
							end

							table.insert(teleports, originPos)
							table.insert(teleports, originPos)

							networkCache.teleporting = true
							networkCache.rage.finished = false
							networkCache.rage.queue = table.clone(teleports)
							networkCache.rage.teleports = teleports
							networkCache.rage.callback = callback
						else
							callback()
						end
						return
					end
					networkCache.rage.scans += 1
				end
			end
		end

		local orb = Instance.new("Part")
		orb.Size = Vector3.new(1,1,1)
		orb.Anchored = true
		orb.CanCollide = false
		orb.CanQuery = false
		orb.Anchored = true
		orb.Transparency = 1
		local heartbeatConnection = runService.Heartbeat:Connect(function(delta)
			thread(updateProjectiles, delta)
			thread(tryScan)
			thread(setupPathpoints)

			if flags.auto_move and flags.auto_rotate then
				local nodes = library.networkCache.pathfinding and library.networkCache.pathfinding.nodes or {}
				if nodes[1] and #nodes > 1 then
					local angles = camInterface.getActiveCamera("MainCamera"):getAngles()
					local lookVectorX, lookVectorY = cf(workspace.CurrentCamera.CFrame.p, nodes[1]):ToOrientation()
					lookVector = vec3(angles.x, lookVectorY, 0)
					local delta = (lookVector - angles) * 0.25
					camInterface.getActiveCamera("MainCamera"):_applyLookDelta(delta)
				end
			end

			orb.Parent = workspace
			orb.Transparency = math.lerp(orb.Transparency, (networkCache and networkCache.instantTeleport and 0 or 1), delta * 5)
			if networkCache.instantTeleport and library.char then
				local diff = (library.char.HumanoidRootPart.Position - networkCache.lastUpdate).Magnitude
				orb.CFrame = cf(library.char and library.char.HumanoidRootPart.Position, networkCache.lastUpdate) * cf(0,0,-diff/2)
				orb.Size = Vector3.new(0.1,0.1,diff)
			end
		end)

		for _,v in workspace.Players:GetChildren() do
			v.ChildAdded:Connect(tryScan)
		end

		library.networking = {
			["newspawn"] = function(player, pos)
				if flags.detailedScanning then
					local old = getidentity()
					setidentity(8)
					scanPlayer(replicationInterface.getEntry(player), pos)
					setidentity(old)
				end
			end
		}
		
		local function muteVelocity()
			if not networkCache then return end
			if charInterface.isAlive() and camInterface.getCameraType() ~= "SpectateCamera" and not networkCache.isBusy then
				local rootPart = charInterface:getCharacterObject():getRealRootPart()
				local hum = rootPart.Parent:FindFirstChildOfClass("Humanoid")
				if (tick() - networkCache.spawn) < 1 then return end
				if rootPart and hum.MoveDirection.Magnitude <= 0.1 then
					rootPart.Velocity = vec3(0, rootPart.Velocity.Y, 0)
				elseif rootPart and (flags.speed_control) then
					rootPart.Velocity = hum.MoveDirection * (flags.speedvalue or 50) + vec3(0, rootPart.Velocity.Y, 0)
				end
			end
		end

		local function jumpVelocity()
			if not networkCache then return end
			if charInterface.isAlive() and camInterface.getCameraType() ~= "SpectateCamera" and not networkCache.isBusy then
				local rootPart = charInterface:getCharacterObject():getRealRootPart()
				local hum = rootPart.Parent:FindFirstChildOfClass("Humanoid")
				if (tick() - networkCache.spawn) < 1 then return end
				if hum.FloorMaterial ~= Enum.Material.Air and uis:IsKeyDown(Enum.KeyCode.Space) and not uis:GetFocusedTextBox() then
					rootPart.Velocity = vec3(rootPart.Velocity.X, (flags.jump_strength or 50), rootPart.Velocity.Z)
				end
				if rootPart.Velocity.Y > flags.jump_strength * 1.5 then
					rootPart.Velocity = vec3(rootPart.Velocity.X, flags.jump_strength * 1, rootPart.Velocity.Z)
				end
			end
		end
		
		--local idleRate = 60--45 -- client updates/second
		--local moveRate = 120 -- client updates/second 
		local renderConnection = runService.RenderStepped:Connect(function(delta)
			if not networkCache then return end
			if ((flags.force_speed and flags.speedkey.active) or networkCache.teleporting) and charInterface.isAlive() and ((tick() - networkCache.spawn) > 0.1) and camInterface.getCameraType() ~= "SpectateCamera" and not networkCache.isBusy then -- in renderstepped because it runs more
				--local seconds = math.clamp(((networkCache.velocity or 0) / 180 ) * 120, idleRate, 120)
				--local seconds = ((networkCache.velocity and (networkCache.velocity > 1) and moveRate) or idleRate)
				local rate = 120 --(((networkCache.teleporting or (networkCache.velocity and (networkCache.velocity > 0.1))) and 120) or 60) 
				local updates = math.floor((delta / (1 / rate)) + 0.49)
				local startTime = lastTime
				for index = 1, updates do
					local anglesXYZ = camInterface.getActiveCamera("MainCamera"):getAngles()
					local lookVector = nil
					local weaponController = weaponInterface.getActiveWeaponController()

					if weaponController then
						local weapon = weaponController:getActiveWeapon()
						if weapon and weapon:getWeaponType() == "Firearm" then
							lookVector = weapon:getBarrelCFrame().LookVector
						end
					end

					local position = charInterface:getCharacterObject():getRootPart().Position
					local yAngle = anglesXYZ.x
					local xAngle = anglesXYZ.y
					local angles = Vector3.new(yAngle, xAngle, 0)

					local gunAngles
					if lookVector then
						gunAngles = Vector3.new(vector.toLookAnglesYX(lookVector)) or angles
					else
						gunAngles = angles
					end

					local time = network.getTime()
					if startTime then
						local netDelta = time - startTime
						time = startTime + (netDelta )--* (index / updates))
					end

					xpcall(function() network:send("repupdate", position, angles, gunAngles, time) end, function()  end) -- send repupdate at custom rate
				end
			else
				if (networkCache.lastTime and (network.getTime() - networkCache.lastTime) >= (1 / 2)) then
					pcall(function() library.char.HumanoidRootPart.CFrame = networkCache.lastUpdate end)
				end
			end

			if (flags.force_speed and flags.speedkey.active) then thread(muteVelocity) end
			if (flags.force_jump and flags.jumpkey.active) then thread(jumpVelocity) end
		end)
	end
	setidentity(8)
-- [[ COMBAT MULTISECTION ]]
local combat_multi = column:multisection({
    name = "combat", 
    sections = {"aimbot", "weaponry"}, 
    auto_fill = false, 
    size = 0.3
})

-- Aimbot Tab
local aimbot = combat_multi:get_tab("aimbot")
local aimbotToggle = aimbot:keybind({name = "enabled", flag = "pf_aimbot", display = "aimbot", tip = "Bind for the aimbot"})

aimbot:dropdown({
    name = "mode",
    flag = "pf_aimbotmode",
    items = {"normal", "silent"},
    multi = false,
    scrolling = true
})

aimbot:toggle({name = "only rmb", flag = "pf_onlyrmb", tip = "Only aim when right mouse button is held."})
aimbot:toggle({name = "automatic fire", flag = "pf_autofire", tip = "Automatically fires, it requires the menu to be closed for it to work."})
aimbot:slider({name = "sim delay", min = 0, max = 150, default = 90, interval = 1, suffix = " ms", flag = "pf_simrate"})

-- Magnet Popout
local magnet_parent = aimbot:toggle({name = "magnet", flag = "pf_magnet", tip = "Uses a 'strength' modifier to attract mouse to target.", popout = true})
depend(magnet_parent, function() return flags.pf_aimbotmode == "normal" end)

magnet_parent:add(aimbot:slider({name = "strength", min = 1, max = 3, default = 1.3, interval = 0.01, flag = "pf_magnet_strength"}))
magnet_parent:add(aimbot:slider({name = "distance", min = 1, max = 300, default = 45, interval = 1, flag = "pf_magnet_distance"}))

-- Smoothing Popout
local smooth_parent = aimbot:toggle({name = "smoothing", flag = "pf_smoothing_enabled", tip = "Humanizes mouse movement", popout = true, default = true})
depend(smooth_parent, function() return flags.pf_aimbotmode == "normal" end)

smooth_parent:add(aimbot:slider({name = "amount", min = 1, max = 100, default = 60, interval = 1, flag = "pf_sensitivity"}))
smooth_parent:add(aimbot:toggle({name = "use game sens", flag = "pf_mousesens", tip = "Uses your roblox mouse sensitivity instead."}))

-- Weaponry Tab (RCS & Accuracy)
local weaponry = combat_multi:get_tab("weaponry")

local rcs_parent = weaponry:toggle({name = "recoil control", flag = "recoil", tip = "Changes how much recoil you get.", popout = true})
rcs_parent:add(weaponry:slider({name = "scale", min = 0, max = 100, default = 100, interval = 1, suffix = '%', flag = "recoilscale"}))

weaponry:toggle({name = "no-spread", flag = "pf_nospread", tip = "Uses a bug to remove all spread from guns."})

depend(weaponry:toggle({name = "accuracy booster", flag = "accuracyboost", tip = "Modifies gun to be as accurate as possible."}), function() return flags.pf_aimbotmode == "silent" end)
depend(weaponry:toggle({name = "muzzle redirection", flag = "pf_muzzleredirect", tip = "Redirects bullets from muzzle to camera"}), function() return flags.pf_aimbotmode == "silent" end)

-- [[ TARGETING MULTISECTION ]]
local targeting_multi = column2:multisection({
    name = "targeting", 
    sections = {"fov", "hitboxes"}, 
    auto_fill = false, 
    size = 0.3
})

-- FOV & Humanization Tab
local fov_tab = targeting_multi:get_tab("fov")
fov_tab:slider({name = "fov", min = 0, max = 360, default = 60, interval = 1, suffix = string.char(194,176), flag = "pf_fov"})

local fov_settings = fov_tab:toggle({name = "fov settings", flag = "pf_fov_extra", popout = true})
fov_settings:add(fov_tab:toggle({name = "ignore fov", flag = "pf_infinitefov"}))
fov_settings:add(fov_tab:toggle({name = "ignore screen checks", flag = "pf_fullfov"}))
fov_settings:add(fov_tab:colorpicker({name = "fov color", flag = "pf_fovcolor", color = themes.preset.button, alpha = 0}))

-- Popout Deadzone Group
local deadzone_parent = fov_tab:toggle({name = "deadzone", flag = "pf_deadzone", popout = true})
depend(deadzone_parent, function() return flags.pf_aimbotmode == "normal" end)
deadzone_parent:add(fov_tab:slider({name = "deadzone fov", min = 0, max = 360, default = 60, flag = "pf_deadzone_fov"}))
deadzone_parent:add(fov_tab:toggle({name = "dynamic deadzone", flag = "pf_dynamic_deadzone"}))

-- Popout Overshoot Group
local overshoot_parent = fov_tab:toggle({name = "overshoot", flag = "pf_overshoot", popout = true})
depend(overshoot_parent, function() return flags.pf_aimbotmode == "normal" end)
overshoot_parent:add(fov_tab:slider({name = "amount", min = 0, max = 3, default = 2, interval = 0.1, flag = "pf_overshoot_amount"}))
overshoot_parent:add(fov_tab:slider({name = "overshoot fov", min = 0, max = 360, default = 100, flag = "pf_overshoot_fov"}))
	local weightBase = {Head = 45, Torso = 30, ["Right Arm"] = 15, ["Left Arm"] = 15, ["Right Leg"] = 10, ["Left Leg"] = 10}
	local function buildCumulative()
		local hitboxWeights = {
			Torso = flags.pf_hitbox_torso_scale or weightBase.Torso,
			Head = flags.pf_hitbox_head_scale or weightBase.Head,
			["Right Arm"] = flags.pf_hitbox_right_arm_scale or weightBase["Right Arm"],
			["Left Arm"] = flags.pf_hitbox_left_arm_scale or weightBase["Left Arm"],
			["Right Leg"] = flags.pf_hitbox_right_leg_scale or weightBase["Right Leg"],
			["Left Leg"] = flags.pf_hitbox_left_leg_scale or weightBase["Left Leg"],
		}
		local cumulativeHitboxes = {}
		local total = 0
		for _, weight in hitboxWeights do
			total += weight
		end

		local sumSoFar = 0
		for name, weight in pairs(hitboxWeights) do
			sumSoFar += weight
			table.insert(cumulativeHitboxes, {Name = name, Cumulative = sumSoFar / total})
		end
		return cumulativeHitboxes
	end
	local function pickCumulativeHitbox()
		local roll = math.random()
		for _, data in buildCumulative() do
			if roll <= data.Cumulative then
				return data.Name
			end
		end
		return "Torso"
	end
-- Hitboxes Tab
local hitboxes = targeting_multi:get_tab("hitboxes")
local hitbox_pool = {"Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}

hitboxes:dropdown({
    name = "static hitbox",
    flag = "pf_hitbox",
    items = hitbox_pool,
    multi = true,
    scrolling = true
})

local cum_toggle = hitboxes:toggle({name = "cumulative hitbox", flag = "pf_cumhitbox"})

-- Scale Sliders (Appears below when cumulative is enabled)
local weightBase = {Head = 45, Torso = 30, ["Right Arm"] = 15, ["Left Arm"] = 15, ["Right Leg"] = 10, ["Left Leg"] = 10}
for _, name in hitbox_pool do
    depend(hitboxes:slider({name = name:lower() .. " weight", min = 1, max = 100, default = weightBase[name], suffix = '%', flag = "pf_hitbox_" .. name:lower() .. "_scale"}), function() 
        return flags.pf_cumhitbox and table.find(flags.pf_hitbox, name) 
    end)
end

-- [[ UTILITY MULTISECTION ]]
local utility_multi = column2:multisection({
    name = "utility", 
    sections = {"backtrack", "visuals", "sounds"}, 
    auto_fill = false, 
    size = 0.3
})

-- Backtrack Tab
local bt_tab = utility_multi:get_tab("backtrack")
local bt_parent = bt_tab:toggle({name = "enabled", flag = "pf_backtrack", popout = true})
bt_parent:add(bt_tab:slider({name = "ms", min = 1, max = 3000, default = 400, flag = "pf_backtrack_time"}))
bt_parent:add(bt_tab:colorpicker({name = "chams color", flag = "pf_backtrack_color", color = rgb(58, 13, 172), alpha = 0.5}))
bt_parent:add(bt_tab:dropdown({name = "selection", flag = "pf_backtrack_selection", items = {"all records", "last record"}, default = 'last record'}))

-- Visuals / Misc Tab
local visuals = utility_multi:get_tab("visuals")
local chams_parent = visuals:toggle({name = "hit chams", flag = "hit_chams", popout = true})
chams_parent:add(visuals:slider({name = "duration", min = 0.1, max = 10, default = 1, suffix = 's', flag = "hit_chams_delay"}))

visuals:toggle({name = "killsay", flag = "killsay"})
visuals:toggle({name = "damage logs", flag = "chatlogs"})

-- Sounds Tab
local sounds = utility_multi:get_tab("sounds")
local elapsedLoad = tick()
local sound_parent = sounds:dropdown({
    name = "hit sound",
    flag = "killsound_l",
    items = (function() local list = {} for soundName in sfx do table.insert(list, soundName) end return list end)(),
    multi = false,
    popout = true,
	callback = function(name)
		if (tick() - elapsedLoad) < 2 then return end
		local sfxId = sfx[flags.killsound_l]
		if sfxId then
			local sound = Instance.new("Sound")
			sound.SoundId = sfxId
			sound.Name = ""
			sound.Volume = flags.sound_volume or 1
			sound.PlaybackSpeed = flags.pitchrng_l and math.random(95, 105) / 100 or 1
			sound.PlayOnRemove = true
			sound.Parent = coregui
			task.defer(game.Destroy, sound)
		end
	end,
})

sounds:slider({name = "volume", min = 0.5, max = 10, default = 1, flag = "sound_volume"})
sounds:toggle({name = "pitch randomizer", flag = "pitchrng_l"})
sounds:toggle({name = "only on kill", flag = "onlyonkill"})
	--[[
		local scanning = column2:section({name = "scanning", auto_fill = false, size = 0.3})scanning:toggle({name = "origin scan", flag = "pf_originscan", tip = "Scans around your player for positions to shoot from."})

	scanning:toggle({name = "visualize scan", flag = "pf_visualizescan", tip = "Visualizes the origin scanning positions."})
	scanning:slider({name = "origin angles", min = 5, max = 360, default = 25, interval = 5, suffix = string.char(194,176), flag = "pf_originangles", tip = "How many angles to check? Higher angles can be EXTREMELY laggy, I recommend lower ones."})
	scanning:slider({name = "origin steps", min = 5, max = 360, default = 25, interval = 5, suffix = 'i', flag = "pf_originsteps", tip = "How many steps to iterate? Higher steps can be EXTREMELY laggy, I recommend lower ones."})
	scanning:slider({name = "origin radius", min = 5, max = 15.9, default = 6, interval = 1, suffix = 'm', flag = "pf_originscanradius", tip = "How far should the scanning reach?"})]]
	--[[local aipeek = column:section({name = "ai peek", auto_fill = false, size = 0.3})
	aipeek:toggle({name = "ai peek", flag = "aipeek", tip = "Scans around your player for positions to shoot from."})
	aa:dropdown({
		name = "peek mode",
		flag = "peek_mode",
		items = {"instant", "normal"},
		multi = false,
		default = 'normal',
		scrolling = true
	})
	aipeek:slider({name = "search angles", min = 5, max = 360, default = 25, interval = 5, suffix = string.char(194,176), flag = "aipeek_angles", tip = "How many angles to check? Higher angles can be EXTREMELY laggy, I recommend lower ones."})
	aipeek:slider({name = "search steps", min = 5, max = 360, default = 25, interval = 5, suffix = 'i', flag = "aipeek_steps", tip = "How many steps to iterate? Higher steps can be EXTREMELY laggy, I recommend lower ones."})
	aipeek:slider({name = "search radius", min = 5, max = 15.9, default = 6, interval = 1, suffix = 'm', flag = "aipeek_radius", tip = "How far should the scanning reach?"})]]

	function scanRadius(origin, maxDistance, angleCount, scanFunc)
		local workingRays = {}
		for i = 1, 360, floor(360/angleCount) do
			local radians = rad(i)
			local direction = vec3(cos(radians), 0, sin(radians))

			local canActuallyHit = scanFunc(origin, origin + direction * maxDistance, direction * maxDistance)
			if not canActuallyHit then continue end

			insert(workingRays, origin + direction * maxDistance)
		end

		local maxDistance, bestOrigin = math.huge, nil
		for _, pos in workingRays do
			local distance = (origin - pos).Magnitude
			if distance < maxDistance then
				maxDistance = distance
				bestOrigin = pos
			end
		end

		return bestOrigin
	end

	local Replication      = modules.ReplicationInterface
	local BulletObject    = modules.BulletObject

	function hasModule(moduleName)
		return moduleCache[moduleName] ~= nil
	end

	hasModule("FirearmObject")
	hasModule("WeaponUtils")

	local pf_dump = {}

	local params = RaycastParams.new()


	library.gameClock = gameClock

	local oldFuncs = {
		computeGunSway = modules.FirearmObject.computeGunSway,
		computeWalkSway = modules.FirearmObject.computeWalkSway,
		cameraStep = modules.MainCameraObject.step,
		getBobCFrame = modules.Sway.getBobCFrame,
		getSwayCFrame = modules.Sway.getSwayCFrame,
		getBreathCFrame = modules.Sway.getBreathCFrame,
		equip = modules.ThirdPersonObject.equip,
		isAiming = modules.FirearmObject.isAiming,
		impulseSprings = modules.FirearmObject.impulseSprings,
		getRootPart = modules.CharacterObject.getRootPart,
		updateScope = modules.FirearmObject.updateScope,
	}
	modules.FirearmObject.computeGunSway = newcclosure(function(self, ...)
		if flags.pf_nosway then
			return CFrame.identity
		end
		return oldFuncs.computeGunSway(self, ...)
	end)
	modules.FirearmObject.isAiming = newcclosure(function(self, ...)
		if flags.accuracyboost then
			return true
		end
		return oldFuncs.isAiming(self, ...)
	end)
	modules.FirearmObject.impulseSprings = newcclosure(function(self, ...)
		if flags.accuracyboost then
			debug.setupvalue(oldFuncs.impulseSprings, 1, 1)
			debug.setupvalue(oldFuncs.impulseSprings, 2, 1)
		end
		return oldFuncs.impulseSprings(self, ...)
	end)
	modules.FirearmObject.computeWalkSway = newcclosure(function(self, ...)
		if flags.pf_nosway then
			return CFrame.identity
		end
		return oldFuncs.computeWalkSway(self, ...)
	end)
	modules.ThirdPersonObject.equip = newcclosure(function(self, ...)
		local args = {...}
		if args[1] == nil then
			args[1] = 1
		end
		--print(self, table.unpack(args))
		return oldFuncs.equip(self, table.unpack(args))
	end)
	modules.Sway.getSwayCFrame = newcclosure(function(self, ...)
		if flags.pf_nosway then
			return CFrame.identity
		end
		return oldFuncs.getSwayCFrame(self, ...)
	end)
	modules.Sway.getBobCFrame = newcclosure(function(self, ...)
		if flags.pf_nosway then
			return CFrame.identity
		end
		return oldFuncs.getBobCFrame(self, ...)
	end)
	local sleeves = {}
	modules.FirearmObject.updateScope = newcclosure(function(self, ...)
		local scope = {oldFuncs.updateScope(self, ...)}
		local firearmObject = self
		pcall(function()
			if library.thirdPerson then 
				firearmObject._weaponModel.Parent = workspace.CurrentCamera
				task.defer(function() firearmObject._weaponModel.Parent = services.soundService end)
				if charInterface.getCharacterObject()._currentArmState then
					charInterface.getCharacterObject():toggleArms()
				end
			else
				firearmObject._weaponModel.Parent = workspace.CurrentCamera
				if not charInterface.getCharacterObject()._currentArmState then
					charInterface.getCharacterObject():toggleArms()
				end
			end
		end)
		return table.unpack(scope)
	end)
	modules.MainCameraObject.step = newcclosure(function(self, dt)
		local char = charInterface.getCharacterObject();

		if char then
			char:setBaseWalkSpeed(16)
		end		

		if flags.pf_nocamerasway and char then
			local speed = char._speed;

			char._speed = 0;
			oldFuncs.cameraStep(self, dt);
			char._speed = speed;
			return
		end

		return oldFuncs.cameraStep(self, dt)
	end)
	local ReplicationSmoother_receive = modules.ReplicationSmoother.receive
	local callReplication = repObject.updateReplication
	modules.Tips = {"seraph is pasted"}
	table.clear(modules.Tips)

	
	local backtrack = {} do
		backtrack.frames = {}
		backtrack.renders = {}

		function backtrack:tickFrames()
			local curTime = gameClock.getTime()
			local maxLatency = ((flags.pf_rage_backtrack and flags.pf_rage_backtrack_time or flags.pf_backtrack_time) or 1) / 1000

			for _, frameContainer in backtrack.frames do
				for i = #frameContainer, 1, -1 do
					local frame = frameContainer[i]
					if (curTime - frame.time) > maxLatency then
						if frame.linked then
							for _, v in frame.linked do
								if v and v.Parent then
									v:Destroy()
								end
							end
						end
						table.clear(frame)
						table.remove(frameContainer, i)
					end
				end
			end
		end

		local HITBOX_RADII = {
			head = 1.1,
			torso = 2.0,
			larm = 1.0,
			rarm = 1.0,
			lleg = 1.0,
			rleg = 1.0
		}

		local HITBOX_CONFIG = {
			{name = "head", rSq = 1.21},
			{name = "torso", rSq = 4.0},
			{name = "larm", rSq = 1.0},
			{name = "rarm", rSq = 1.0},
			{name = "lleg", rSq = 1.0},
			{name = "rleg", rSq = 1.0}
		}

		function backtrack:checkOldestRecord(player, shootOrigin, shootVelocity)
			local container = self.frames[player]
			if not container or #container == 0 then return nil end

			local oldestFrame = container[1]
			local tracked = oldestFrame.tracked
			
			local dir = shootVelocity.Unit
			local shootLen = shootVelocity.Magnitude

			for _, data in HITBOX_CONFIG do
				local partCFrame = tracked[data.name]
				if not partCFrame then continue end
				
				local targetPos = partCFrame.Position
				local relX = targetPos.X - shootOrigin.X
				local relY = targetPos.Y - shootOrigin.Y
				local relZ = targetPos.Z - shootOrigin.Z
				local t = (relX * dir.X) + (relY * dir.Y) + (relZ * dir.Z)
				if t > 0 and t < (shootLen + 2) then
					local cpX = shootOrigin.X + (dir.X * t)
					local cpY = shootOrigin.Y + (dir.Y * t)
					local cpZ = shootOrigin.Z + (dir.Z * t)
					local distSq = (cpX - targetPos.X)^2 + (cpY - targetPos.Y)^2 + (cpZ - targetPos.Z)^2
					
					if distSq <= data.rSq then
						return oldestFrame, t / shootLen
					end
				end
			end
			
			return nil
		end

		function backtrack:findIntersectingRecord(player, shootOrigin, shootVelocity)
			local container = self.frames[player]
			if not container or #container == 0 then return nil end

			local dir = shootVelocity.Unit
			local shootLen = shootVelocity.Magnitude

			for i = #container, 1, -1 do
				local frame = container[i]
				local tracked = frame.tracked
				
				for hitBoxName, radius in HITBOX_RADII do
					local targetPos = tracked[hitBoxName].Position
					local toTarget = targetPos - shootOrigin
					
					local t = toTarget.X * dir.X + toTarget.Y * dir.Y + toTarget.Z * dir.Z
					
					if t > 0 and t < shootLen + 5 then
						local closestPointX = shootOrigin.X + dir.X * t
						local closestPointY = shootOrigin.Y + dir.Y * t
						local closestPointZ = shootOrigin.Z * dir.Z * t
						local dx = closestPointX - targetPos.X
						local dy = closestPointY - targetPos.Y
						local dz = closestPointZ - targetPos.Z
						local distSq = (dx * dx) + (dy * dy) + (dz * dz)
						
						if distSq <= (radius * radius) then
							return frame, t / shootLen
						end
					end
				end
			end
			
			return nil
		end

		function backtrack:multiRender(player)
			if not backtrack.frames[player] then return end
			local oldestFrame = backtrack.frames[player][1]

			if oldestFrame then

				local entry = Replication.getEntry(player)
				if not entry then return end

				local totalFrames = backtrack.frames[player]
				for i, frame in totalFrames do
					if not frame.linked then
						frame.linked = {
								torso = library:create("BoxHandleAdornment", {
									Adornee = nil,
									Size = vec3(2, 2, 1),
									Color3 = rgb(255, 0, 255),
									Transparency = 0.5,
									AlwaysOnTop = true,
								}),
								rarm = library:create("BoxHandleAdornment", {
									Adornee = nil,
									Size = vec3(1, 2, 1),
									Color3 = rgb(255, 0, 255),
									Transparency = 0.5,
									AlwaysOnTop = true,
								}),
								larm = library:create("BoxHandleAdornment", {
									Adornee = nil,
									Size = vec3(1, 2, 1),
									Color3 = rgb(255, 0, 255),
									Transparency = 0.5,
									AlwaysOnTop = true,
								}),
								rleg = library:create("BoxHandleAdornment", {
									Adornee = nil,
									Size = vec3(1, 2, 1),
									Color3 = rgb(255, 0, 255),
									Transparency = 0.5,
									AlwaysOnTop = true,
								}),
								head = library:create("BoxHandleAdornment", {
									Adornee = nil,
									Size = vec3(1.2, 1.2, 1.2),
									Color3 = rgb(255, 0, 255),
									Transparency = 0.5,
									AlwaysOnTop = true,
								}),
								lleg = library:create("BoxHandleAdornment", {
								Adornee = nil,
								Size = vec3(1, 2, 1),
								Color3 = rgb(255, 0, 255),
								Transparency = 0.5,
								AlwaysOnTop = true,
							}),
						}
					end
					for name, v in frame.linked do
						if not oldestFrame.tracked[name] then continue end
						v.Adornee = workspace.Terrain
						v.Parent = workspace.Terrain
						v.Name = "\0"
						v.Color3 = flags.pf_backtrack_color.Color
						v.Transparency = math.lerp(1, 1 - flags.pf_backtrack_color.Transparency, i / #totalFrames)
						v.CFrame = frame.tracked[name]
					end
				end
			else
				if #backtrack.frames[player] > 0 then
					for name, v in backtrack.frames[player] do
						if not v.linked then continue end
						for _, part in v.linked do
							if part and part.Parent then
								part:Destroy()
							end
						end
					end
					backtrack.frames[player] = {}
				end
			end
		end

		function backtrack:renderBacktrack(player)
			if not backtrack.frames[player] then return end
			local oldestFrame = backtrack.frames[player][1]

			if flags.pf_backtrack_multi then
				return self:multiRender(player)
			end
			if oldestFrame then
				if not backtrack.renders[player] then
					backtrack.renders[player] = {
						torso = library:create("BoxHandleAdornment", {
							Adornee = nil,
							Size = vec3(2, 2, 1),
							Color3 = rgb(255, 0, 255),
							Transparency = 0.5,
							AlwaysOnTop = true,
						}),
						rarm = library:create("BoxHandleAdornment", {
							Adornee = nil,
							Size = vec3(1, 2, 1),
							Color3 = rgb(255, 0, 255),
							Transparency = 0.5,
							AlwaysOnTop = true,
						}),
						larm = library:create("BoxHandleAdornment", {
							Adornee = nil,
							Size = vec3(1, 2, 1),
							Color3 = rgb(255, 0, 255),
							Transparency = 0.5,
							AlwaysOnTop = true,
						}),
						rleg = library:create("BoxHandleAdornment", {
							Adornee = nil,
							Size = vec3(1, 2, 1),
							Color3 = rgb(255, 0, 255),
							Transparency = 0.5,
							AlwaysOnTop = true,
						}),
						head = library:create("BoxHandleAdornment", {
							Adornee = nil,
							Size = vec3(1.2, 1.2, 1.2),
							Color3 = rgb(255, 0, 255),
							Transparency = 0.5,
							AlwaysOnTop = true,
						}),
						lleg = library:create("BoxHandleAdornment", {
							Adornee = nil,
							Size = vec3(1, 2, 1),
							Color3 = rgb(255, 0, 255),
							Transparency = 0.5,
							AlwaysOnTop = true,
						}),
					}
				end

				local render_objects = backtrack.renders[player]
				local entry = Replication.getEntry(player)
				if not entry then return end

				for name, v in render_objects do
					if not oldestFrame.tracked[name] then continue end
					v.Adornee = workspace.Terrain
					v.Parent = workspace.Terrain
					v.Name = "\0"
					v.Color3 = flags.pf_backtrack_color.Color
					v.Transparency = 1 - flags.pf_backtrack_color.Transparency
					v.CFrame = oldestFrame.tracked[name]
				end
			else
				local render_objects = backtrack.renders[player]
				if not render_objects then return end
				for name, v in render_objects do v.Transparency = 1 end
			end
		end

		local elapsed = 0
		run.RenderStepped:Connect(function(dt)
			elapsed += dt
			backtrack:tickFrames()
			if flags.pf_backtrack or flags.pf_rage_backtrack then
				for player, _ in backtrack.frames do
					backtrack:renderBacktrack(player)
				end
			else
				for _, render_objects in backtrack.renders do
					for _, v in render_objects do
						v.Parent = nil
					end
				end
			end
		end)
	end

	modules.ReplicationObject.updateReplication = newcclosure(function(self, time, pos, ...)
		--print(self._player)
		if not self:isEnemy() or not self:isAlive() then
			return callReplication(self, time, pos, ...)
		end
		local frameData = backtrack.frames[self._player]
		if not frameData then backtrack.frames[self._player] = {} frameData = backtrack.frames[self._player] end
		if flags.pf_backtrack or flags.pf_rage_backtrack then
			if frameData then
				local entry = Replication.getEntry(self._player)
				if not entry then return callReplication(self, time, pos, ...) end
				local hash = entry:getThirdPersonObject():getCharacterHash()
				frameData[#frameData + 1] = { 
					time = gameClock.getTime(), 
					position = pos, 
					tracked = {
						torso = hash.Torso.CFrame,
						head = hash.Head.CFrame,
						rarm = hash["Right Arm"].CFrame,
						larm = hash["Left Arm"].CFrame,
						rleg = hash["Right Leg"].CFrame,
						lleg = hash["Left Leg"].CFrame,
					}
				}
			end
		end
		return callReplication(self, time + library:get_tickbase(), pos, ...)
	end)
	--[[modules.ReplicationSmoother.receive = newcclosure(function(self, ...)
		local args = {...}
		if flags.pf_backtrack then
			local a,b = 0
			repeat
				a += task.wait()
			until a >= flags.pf_backtrack_time / 1000
			return ReplicationSmoother_receive(self, table.unpack(args))
		end
		return ReplicationSmoother_receive(self, table.unpack(args))
	end)]]

	local function replaceclosure(closureOriginal, newClosure)
		return newcclosure(function(...)
			return newClosure(closureOriginal, ...)
		end)
	end
	local function replaceclosurehook(closureOriginal, newClosure)
		local old; old = hookfunction(closureOriginal, newcclosure(function(...)
			return newClosure(old, ...)
		end))
	end

	local cameraAngle, scannedOrigin = nil, nil

	local __cameraStackOrigin = {}
	local __getBaseCFrame
	--[[modules.MainCameraObject.getBaseCFrame = replaceclosure(modules.MainCameraObject.getBaseCFrame, function(old, ...)
		local args = { ... }
		local stack = { old(table.unpack(args)) }


		if scannedOrigin then
			stack[1] = CFrame.new(scannedOrigin) * stack[1].Rotation
			print("getBaseCFrame modified", scannedOrigin)
		end

		return table.unpack( stack )
	end)

	replaceclosurehook(modules.FirearmObject.getBarrelCFrame, function(old, ...)
		local args = { ... }

		if checkcaller() then
			return old(table.unpack(args))
		end

		local original =  old(table.unpack(args))

		if scannedOrigin then
			original = CFrame.new(scannedOrigin) * original.Rotation
		end

		return original
	end)]]


	local newReplicator = repObject.new
	local fakePlayer
	local playerData = {}
	local weapon = modules.WeaponControllerInterface.getActiveWeaponController()
	
	library.safe = task.spawn
	library.network = {}
	library.safe (function()
		do
			local networkClient = modules.NetworkClient
			library.modules = modules or {}

			--[[for i, upvalue in debug.getupvalues(networkClient.fireReady) do
				print(i, upvalue, typeof(upvalue))
			end]]

			function library.network:receive(functionName, func, hook)
				local receive_parent = debug.getupvalue(networkClient.fireReady, 6)
				local event_container = debug.getupvalue(networkClient.fireReady, 5)
				--setreadonly(receive_parent, false)
				if event_container[functionName] then
					local old = event_container[functionName]
					event_container[functionName] = function(...)
						if not hook then old(...) end
						func(...)
					end
					return old
				end
				event_container[functionName] = func
				if receive_parent[functionName] then
					for i = 1, #receive_parent[functionName] do
						func(unpack(receive_parent[functionName][i]))
					end
					receive_parent[arg2] = nil
				end
				--setreadonly(receive_parent, true)
			end

			library.network.send = function(base, ...) return networkClient:send(...) end

			function library.network:override(functionName, func, hook)
				return library.network:receive(functionName, func, true)
			end

			for name, hook in library.networking or {} do
				library.network:receive(name, hook)
			end

			library.ammoTracking = {}
			library.network:receive("newbullets", function(data)
				if data.player and data.player ~= lp then
					local entry = library.modules.ReplicationInterface.getEntry(data.player)
					local weapon = entry:getWeaponObject()

					if not entry.ammo then
						entry.ammo = weapon.weaponData.magsize
					end

					if (entry.ammo == 0) and weapon then
						entry.ammo = weapon.weaponData.magsize
					end
					entry.ammo -= 1
				end
			end)

			library.network:receive("correctposition", function()
				local diff = tick() - (library.lastRubberBand or tick())
				totalSpeed, library.lastRubberBand = 0, tick()
				if library.networkCache.pathfinding then
					library.networkCache.pathfinding.nodes  = {}
					library.networkCache.pathfinding.reversed = {}
					library.networkCache.pathfinding.finished = false
					library.networkCache.forcePosition = nil
				end

				library.networkCache.lastTick = library.modules.GameClock.getTime()
				if diff >= 1 then
					local identity = getidentity()
					setidentity(8)
					createNotification({ text = "Server corrected position!", duration = 5 })
					setidentity(identity)
				end
			end)

			local ping; ping = library.network:override("ping", function(...)
				local timeSync = debug.getupvalue(ping, 2)
				task.delay(library:get_tickbase() / 1000, function(...)
					--print("hi", ping, ...)
					networkClient:send("ping", timeSync:step(...))
				end, ...)
			end)

			local function deepServerHop()
				local CACHE_FILE = `seraph/cache/server-history-{lp.UserId}.json`
				local CACHE_TTL = 60 * 60 * 24

				local teleportService = services.teleportService
				local httpService = services.httpService

				local placeId = game.PlaceId
				local now = os.time()

				local MAX_PAGES = 5
				local MAX_ACCEPTABLE_PING = 120

				local visited = {}

				if isfile(CACHE_FILE) then
					local ok, decoded = pcall(httpService.JSONDecode, httpService, readfile(CACHE_FILE))
					if ok and type(decoded) == "table" then
						for jobId, timestamp in pairs(decoded) do
							if now - timestamp < CACHE_TTL then
								visited[jobId] = timestamp
							end
						end
					end
				end

				local cursor
				local baseUrl =
					"https://games.roblox.com/v1/games/" ..
					placeId ..
					"/servers/Public?limit=100&sortOrder=Asc"

				local bestServer
				local bestPing = math.huge
				local pagesScanned = 0

				while pagesScanned < MAX_PAGES do
					pagesScanned += 1

					local url = cursor and (baseUrl .. "&cursor=" .. cursor) or baseUrl
					local response = request({ Url = url, Method = "GET" })
					if not response or not response.Body then break end

					local data = httpService:JSONDecode(response.Body)
					local servers = data.data

					if typeof(servers) ~= "table" then wait(1) pagesScanned -= 1 continue end

					for i = 1, #servers do
						local srv = servers[i]
						local jobId = srv.id

						if not visited[jobId]
							and srv.playing < srv.maxPlayers - 1
							and srv.playing > 7
							and srv.ping
						then
							if srv.ping <= MAX_ACCEPTABLE_PING then
								if srv.ping < bestPing then
									bestPing = srv.ping
									bestServer = jobId
								end
							end
						end
					end

					cursor = data.nextPageCursor
					if not cursor then break end
				end

				if bestServer then
					visited[bestServer] = now
					writefile(CACHE_FILE, httpService:JSONEncode(visited))

					while true do
						teleportService:TeleportToPlaceInstance(
							placeId,
							bestServer,
							lp
						)
						task.wait(5)
					end

					return true
				end

				writefile(CACHE_FILE, httpService:JSONEncode(visited))
				teleportService:Teleport(placeId, lp)
				return false
			end



			library.network:receive("startvotekick", function(playerName, reason)
				if playerName == lp.Name then
					lp:Kick("Random chud votekicked you, finding another server for you king ðŸ‘‘")
					task.delay(1, deepServerHop)
				end
			end)

			local oldReceive = debug.getupvalue(networkClient._init, 2)
			debug.setupvalue(networkClient._init, 2, function(self, ...)
				if self == 'ping' then
					local elapsed
					repeat
						elapsed = task.wait()
					until elapsed >= library:get_tickbase()
				end
				return oldReceive(self, ...)
			end)

			task.spawn(function()
				for _, message in services.logService:GetLogHistory() do
					print(message.Message)
					if message.Message:find("Server Kick Message: You have been votekicked") then
						deepServerHop()
					end
				end
			end)

			task.spawn(function()
				task.wait(5)
				local interface = modules.CharacterInterface
				local menuGui = modules.MenuScreenGui
				local deploy = modules.PageMainMenuButtonDeploy

				local trySpawn_upvr = debug.getupvalue(deploy.init, 9)
				for index, upvalue in debug.getupvalues(deploy.init) do
					print(index, upvalue, typeof(upvalue))
				end
				print(typeof(trySpawn_upvr))
				if flags.autospawn then
					menuGui.enable()
					networkClient:send("forcereset")
				end

				local firstSpawn = true
				local deadWaitingForMenu = 0
				local timeAlive = tick()
				while wait(2) do
					if not flags.autospawn then continue end
					if disableGui and menuGui.isEnabled() then
						menuGui.disable()
						disableGui = false
					end
					if 0 < interface.getTimeTillSpawn(false) then continue end
					if interface.isAlive() then
						timeAlive = tick()
						continue
					end

					if tick() - timeAlive < 5 then continue end
					if menuGui.getTimeEnabled() < 0.1 then continue end
					disableGui = true
					trySpawn_upvr()
				end
			end)
				

		end
	end)

	task.spawn(function()
		local maskPlayer = {
			GetPropertyChangedSignal = function(self, __indexName)
				return lp:GetPropertyChangedSignal(__indexName)
			end
		}
		for k, v in debug.getupvalues(newReplicator) do
			local v = (v.Name == lp.Name and maskPlayer) or v
			debug.setupvalue(newReplicator, k, v)
		end

		fakePlayer = newReplicator(cloneref(lp))
		--debug.setupvalue(newReplicator, 3, value)
		--print(fakePlayer, fakePlayer._activeWeaponRegistry)

		repeat
			task.wait()
			weapon = modules.WeaponControllerInterface.getActiveWeaponController()
		until weapon

		local weaponData = weapon:getWeapons()
		local weaponData_ = {}
		--[[local weaponIndex_ = {
			[1] = "Primary",
			[2] = "Secondary",
			[3] = "Melee",
			[4] = "Grenade"
		}
		for k, v in weaponData do
			for e, a in v do
				print(e, a)
			end
			local o = weaponIndex_[k]
			weaponData_[o] = table.clone(v)
		end

		for k,v in weapon._activeWeaponRegistry do
			print(k, v)
		end]]

		local weaponData = weapon._activeWeaponRegistry


		fakePlayer._activeWeaponRegistry = weaponData

		repObject.spawn(fakePlayer, vec3(0, 1, 0), {
			Primary = {loadoutUnchanged = true},
			Secondary = {loadoutUnchanged = true},
			Knife = {loadoutUnchanged = true},
			Grenade = {loadoutUnchanged = true},
			activeWeaponIndex = 1,
		})

		local object = fakePlayer._thirdPersonObject
		local physicalChar = object._characterModel
		physicalChar:GetAttributeChangedSignal("transparency"):Connect(function()
			local transparency = physicalChar:GetAttribute("transparency")
			for _, part in physicalChar:GetDescendants() do
				if part:IsA("BasePart") and part.Transparency ~= 1 then
					part.LocalTransparencyModifier = transparency
				elseif (part:IsA("Texture") or part:IsA("Decal")) and part.Transparency ~= 1 then
					part.Transparency = transparency
				end
			end
		end)
		local fake = {Team = nil}
		local selfChams = false
		local last = 0

		local prevStep = object.step
		--[[
		local lerpedPos = cf()
		object.step = newcclosure(function(self, visible, pos, vel, ...)
			local pos = playerData.pos and CFrame.new(playerData.pos) * pos.Rotation or pos
			lerpedPos = lerpedPos:Lerp(pos, 0.5)
			return prevStep(self, visible, pos, vel, ...)
		end)
		]]

		local weaponIndex = 1

		object:buildWeapon(weaponIndex)

		local thirdPersonAnimations = {
			["aim"] = function(args)
				if not fakePlayer._thirdPersonObject then
					return
				end
				fakePlayer._thirdPersonObject:setAim(args[1])
			end,
			["sprint"] = function(args)
				if not fakePlayer._thirdPersonObject then
					return
				end
				fakePlayer._thirdPersonObject:setSprint(args[1])
			end,
			["stance"] = function(args)
				if not fakePlayer._thirdPersonObject then
					return
				end
				fakePlayer._thirdPersonObject:setStance(args[1])
			end,
			["stab"] = function(args)
				if not fakePlayer._thirdPersonObject then
					return
				end
				fakePlayer._thirdPersonObject:stab()
			end,
			["newbullets"] = function(args)
				if not fakePlayer._thirdPersonObject then
					return
				end
				fakePlayer._thirdPersonObject:kickWeapon(false, nil, nil, 0)
			end,
			["equip"] = function(args)
				do
					-- inventory update
					local current_loadout = modules.ActiveLoadoutUtils.getActiveLoadoutData(modules.PlayerDataClientInterface.getPlayerData())

					for i, v in next, current_loadout do
						fakePlayer._thirdPersonObject._replicationObject:swapWeapon(i, v)
					end
				end

				if args[1] > 2 then
					fakePlayer._thirdPersonObject:equipMelee()
				else
					fakePlayer._thirdPersonObject:equip(args[1])    
				end
			end,
		}

		library.thirdPersonAnimations = thirdPersonAnimations

		local function createChinaHat(params)
			local origin       = params.origin or CFrame.new()
			local height       = params.height or 2
			local radius       = params.radius or 4
			local segments     = params.segments or 32
			local transparency = params.transparency or 0.5
			local parent       = params.parent or workspace
			local rainbow      = params.rainbow or false
			local baseColor    = params.color or Color3.fromRGB(0, 255, 255)

			local apex = (origin * CFrame.new(0, height, 0)).p
			local step = (math.pi * 2) / segments
			local folder = Instance.new("Model")
			folder.Name = "ChinaHat"
			folder.Parent = parent

			local gradient = Instance.new("Highlight", folder)
			gradient.Name = ""
			gradient.OutlineTransparency = 0.1
			gradient.FillTransparency = 1.0
			gradient.OutlineColor = baseColor

			local drawChinaHatBottom = flags.chinahat_bottom

			for i = 0, segments - 1 do
				local theta0 = i * step
				local theta1 = (i + 1) * step

				local p0 = (origin * CFrame.new(math.cos(theta0) * radius, 0, math.sin(theta0) * radius)).p
				local p1 = (origin * CFrame.new(math.cos(theta1) * radius, 0, math.sin(theta1) * radius)).p
				local color = baseColor
				if rainbow then
					color = Color3.fromHSV((tick() * 0.5 + (i / segments)) % 1, 1, 1):Lerp(baseColor,0.7)
				end

				local function draw3DTriangle(a, b, c, col)
					local ab, ac, bc = (b - a).Magnitude, (c - a).Magnitude, (c - b).Magnitude
					local ed0, ed1, ed2 = (b - a).Unit, (c - a).Unit, (c - b).Unit

					local w1 = Instance.new("WedgePart")
					local w2 = Instance.new("WedgePart")
					w1.Anchored, w2.Anchored = true, true
					w1.CanCollide, w2.CanCollide = false, false
					w1.Material, w2.Material = Enum.Material.ForceField, Enum.Material.ForceField
					w1.Transparency, w2.Transparency = transparency, transparency
					w1.Color, w2.Color = col, col

					local x = (c - a):Dot(ed0)
					local y = (c - (a + ed0 * x)).Magnitude
					local z1 = x
					local z2 = ab - x

					w1.Size = Vector3.new(0, y, z1)
					w2.Size = Vector3.new(0, y, z2)
					
					local ang = CFrame.Angles(0,math.rad(90),0)
					w1.CFrame = CFrame.fromMatrix(a + ed0 * (z1/2) + (c - (a + ed0 * x)).Unit * (y/2), ed0, (c - (a + ed0 * x)).Unit, ed0:Cross((c - (a + ed0 * x)).Unit)) * ang
					w2.CFrame = CFrame.fromMatrix(b - ed0 * (z2/2) + (c - (a + ed0 * x)).Unit * (y/2), -ed0, (c - (a + ed0 * x)).Unit, -ed0:Cross((c - (a + ed0 * x)).Unit)) * ang

					w1.Parent = folder
					w2.Parent = folder
				end

				draw3DTriangle(p0, p1, apex, color)
				if drawChinaHatBottom then
					draw3DTriangle(p0, p1, (origin * CFrame.new(0, 0, 0)).p, color) -- bottom color stuff
				end
			end

			return folder
		end

		local china = createChinaHat({
			origin = CFrame.new(0, 0.5, 0),
			height = 1.0,
			radius = 1.9,
			segments = 35,
			rainbow = flags.chinahat_rainbow,
			color = flags.chinahat_color.Color,
			transparency = math.lerp(1, -15.0, flags.chinahat_color.Transparency)
		})
		
		library.gradientChanged:Connect(function()
			pcall(function()
				if china and china.Parent then
					china:Destroy()
				end
			end)
			china = createChinaHat({
				origin = CFrame.new(0, 0.5, 0),
				height = 1.0,
				radius = 1.9,
				segments = 35,
				rainbow = flags.chinahat_rainbow,
				color = flags.chinahat_color.Color,
				transparency = math.lerp(1, -15.0, flags.chinahat_color.Transparency)
			})
		end)

		local charConfig = modules.CharacterConfig
		local stances = {
			proneCFrame = CFrame.new(0, -2.5, 0),
			standCFrame = CFrame.identity,
			crouchCFrame = CFrame.new(0, -1.5, 0)
		}
		local interpolatedState = cf()
		local fakeTorso, realRoot

		function setupStance()

			local computeTorsoCFrame = fakePlayer._thirdPersonObject.computeTorsoCFrame
			local computeBaseCFrame = fakePlayer._thirdPersonObject.computeBaseCFrame
			local getStanceCF_upvr = debug.getupvalue(computeBaseCFrame, 5)

			fakePlayer._thirdPersonObject.computeTorsoCFrame = function(self, baseCFrame, ...)
				if flags.instantupdate then
					realRoot = baseCFrame
					fakeTorso = computeTorsoCFrame(self, cf(fakePlayer._rootCF.Position) * baseCFrame.Rotation, ...)
				end
				library.localPos = fakePlayer._thirdPersonObject._torso.Position
				return computeTorsoCFrame(self, baseCFrame, ...)
			end
			fakePlayer._thirdPersonObject._torso:GetPropertyChangedSignal("CFrame"):Connect(function()
				if not flags.instantupdate then return end
				local fakeTorso = cf(fakeTorso.x, fakeTorso.y + interpolatedState.y, fakeTorso.z) * fakeTorso.Rotation
				if fakePlayer._thirdPersonObject._torso.CFrame == fakeTorso then return end
				fakePlayer._thirdPersonObject._torso.CFrame = fakeTorso
			end)
		end
		task.delay(0.1, setupStance)

		local lerpedVelocity = vec3()
		local oldPos = cf()
		local where = vec3()
		local rootTween

		local hash = fakePlayer._thirdPersonObject._characterModelHash
		
		for name, part in hash do
			part.Name = name
		end

		local baseCharacter = fakePlayer._thirdPersonObject._characterModel:Clone()
		

		local elapse = 0
		run.RenderStepped:Connect(function(dt)
			if not playerData.pos then return end
			if not library.char then return end
			if not flags.smoothinterp then
				elapse += dt
				if elapse <= 1/59 then return end
				elapse = 0
			end
			local lpPos = library.char.HumanoidRootPart.CFrame
			listAdd = 0
			--[[if not position_desync.active then drawBar("desync", 0, false, rgb(255,0,0), rgb(255,0,0)) end
			peakAsset.Size = peakAsset.Size:Lerp(position_desync.active and vec3(4, 0, 4) or vec3(0, 0, 0), correctAlpha(0.275, dt))
			peakAsset.Parent = workspace.CurrentCamera

			visualization.CFrame *= angles(0,rad(dt * 25),0)
			visualization.Size = visualization.Size:Lerp(flags.pf_originscan and vec3(flags.pf_originscanradius,0,flags.pf_originscanradius) * ((math.pi / 2 * 20) + 0.1) or vec3(0,0,0), correctAlpha(0.275, dt))
			visualization.Parent = workspace.CurrentCamera]]

			peakAsset.Size = peakAsset.Size:Lerp((library.networkCache and flags.jitter_move) and vec3(4, 0, 4) or vec3(0, 0, 0), correctAlpha(0.275, dt))
			peakAsset.Parent = workspace.CurrentCamera
			peakAsset.CFrame = cf((library.networkCache and flags.jitter_move) and library.networkCache.lastUpdate or vec3()) * cf(0,-3,0)
			
			--[[local difference = (lpPos.Position - ((library.networkCache and flags.jitter_move) and library.networkCache.lastUpdate or vec3())).Magnitude >= 1.5
			if difference and fakePlayer._rootCF then
				baseCharacter.Parent = workspace.Terrain
				local baseRoot = fakePlayer._thirdPersonObject._rootPart.CFrame
				local delta = (baseRoot.Position - fakePlayer._rootCF.Position)
				for name, part in hash do
					baseCharacter[name].CFrame = cf(((library.networkCache and flags.jitter_move) and library.networkCache.lastUpdate or vec3()) - delta) * baseRoot.Rotation * (hash.Torso.CFrame:Inverse() * part.CFrame)
				end
			else
				baseCharacter.Parent = nil
			end]]

			fakePlayer._activeWeaponIndex = weapon._activeWeaponIndex or 1


			local renders = true
			if not library.thirdPerson or not library.char then
				renders = false
				selfChams = false
			end
			pcall(function() china.Parent = (renders and flags.chinahat) and workspace.Terrain or nil end)
			local charObject = charInterface.getCharacterObject()
			if not charObject then return end
			if not playerData.ran and not flags.smoothinterp then return end
			local weaponController = charObject._weaponController
			local weapon = weaponController:getActiveWeapon()
			weapon._forceHidden = not renders
			if weapon._isHidden ~= not renders then
				weapon._isHidden = not renders
				if weapon._isHidden then
					weapon:hideModel()
				else
					weapon:showModel()
				end
			end
			--print(weapon._aiming, weapon.aiming, weapon._blackScoped)
			local object = fakePlayer._thirdPersonObject
			if not renders then
				if not object then return end
				local physicalChar = object._characterModel
				if not physicalChar then return end
				physicalChar.Parent = nil
			end
			local replicator = fakePlayer._smoothReplication
			--[[
				setmetatable_result1._sampleSecondsAtLimit = arg1
				setmetatable_result1._extrapolationLimit = arg2
				setmetatable_result1._interpolationFunc = arg4
				setmetatable_result1._maxDelay = arg3
			]]			
			--[[
				10, 0.15, 0.3333333333333333, func() end
			]]
			--replicator._sampleSecondsAtLimit = 1
			--replicator._maxDelay = 0.03
			--[[replicator:receive(gameClock.getTime(), gameClock.getTime(), {
					t = gameClock.getTime(),
					position = playerData.pos,
					velocity = vec3(),
					angles = playerData.ang,
					breakcount = 0,
				}, false)]]
			--[[if islclosure(replicator._interpolationFunc) then
				local oldCall = replicator._interpolationFunc
				replicator._interpolationFunc = newcclosure(function(...)
					local result = { oldCall(...) }
					local args = { ... }
					--print(...)
					--warn("RESULT:", table.unpack(result))
					return args[2]
				end)
			end]]
			oldPos = where
			where = where:Lerp(library.networkCache.forcePosition or library.networkCache.forceClientPosition or lpPos.p, correctAlpha(flags.smoothinterp and 1 or 0.5, dt))
			local where = (fakePlayer._rootCF and (not flags.smoothinterp and where + (where - oldPos) * 0.5 or where) or where)
			
			if library.char and library.networkCache.forcePosition and flags.auto_move_client then
				local hum = library.char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					--[[local distance = (hum.RootPart.Position - library.networkCache.forcePosition).Magnitude
					if distance >= 9.9 then
						hum.RootPart.CFrame = cf(hum.RootPart.Position:lerp(library.networkCache.forcePosition, .35)) * hum.RootPart.CFrame.Rotation
					end
					hum.RootPart.AssemblyLinearVelocity = (library.networkCache.forcePosition - hum.RootPart.Position) / dt]]

					if rootTween then rootTween:Cancel() end
					rootTween = tween_service:Create(hum.RootPart, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
						CFrame = cf(library.networkCache.forcePosition) * hum.RootPart.CFrame.Rotation
					})
					rootTween:Play()
					--hum:MoveTo(library.networkCache.forcePosition)
				end
			end
			fakePlayer._rootCF = cf(where) * lpPos.Rotation
			-- arg2, arg3, arg4, arg5, arg6, arg7, arg8)
			repObject.updateReplication(fakePlayer, nil, gameClock.getTime(), where, playerData.ang, playerData.bulletAng)
			repObject.step(fakePlayer, true, where)
			interpolatedState = interpolatedState:lerp(cf((stances[`{object._stanceValue or "stand"}CFrame`] or cf()).Position), 0.008)
			object._leftFoot.makesound = false
			if not renders then fakePlayer._thirdPersonObject._characterModel.Parent = nil return end
			library.localChar = fakePlayer._thirdPersonObject._characterModel
			object.canRenderWeapon = true
			local weaponIndexBase = weaponController:getActiveWeaponIndex() or 1
			if weaponIndex ~= weaponIndexBase then
				object.canRenderWeapon = false
				weaponIndex = weaponIndexBase
				local model = object._weaponModel
				thirdPersonAnimations["equip"]({weaponIndex})
				weaponData = weaponController._activeWeaponRegistry
				fakePlayer._activeWeaponRegistry = weaponData
				selfChams = false
			end
			local object = fakePlayer._thirdPersonObject
			local physicalChar = object._characterModel
			if weapon and weapon.isAiming then
				object:setAim(weapon:isAiming())
			end
			object:setSprint(library.fakeSprint or charObject._sprinting)
			object:setStance(library.fakeMoveMode or charObject:getMovementMode())
			object._stanceValue = library.fakeMoveMode or charObject:getMovementMode()
			if physicalChar:IsDescendantOf(workspace) then physicalChar.Parent = workspace.Terrain end
			physicalChar:SetAttribute("transparency", (weapon._aiming or weapon._blackScoped) and 0.9 or 0)
			task.defer(function()
				local head = object and object._characterModelHash.Head
				if head and not head:GetAttribute("markOfTheBeast") then
					head:SetAttribute("markOfTheBeast", true)
					object._characterModelHash.Head.Changed:Connect(function()
						if head and china:IsDescendantOf(workspace) then
							china:PivotTo(head.CFrame * cf(0, 0.5, 0) * angles(0,rad(-90),rad(90-25)))
						end
					end)
				end
			end)
			if flags.self_character_chams and not selfChams then
				physicalChar:SetAttribute("wow", 0)
				task.delay(0.5, characterChamsSelf, fake, nil, physicalChar)
				task.delay(0.1, characterChamsSelf, fake, nil, physicalChar)
				selfChams = true
			elseif not flags.self_character_chams and selfChams then
				selfChams = false
				local tp = fakePlayer._thirdPersonObject and fakePlayer._thirdPersonObject._characterModel
				if tp then
					task.delay(0.1, game.Destroy, tp)
				end
				repObject.despawn(fakePlayer)
				fakePlayer._activeWeaponRegistry = weaponData

				repObject.spawn(fakePlayer, vec3(0, 1, 0), {
					Primary = {loadoutUnchanged = true},
					Secondary = {loadoutUnchanged = true},
					Knife = {loadoutUnchanged = true},
					Grenade = {loadoutUnchanged = true},
					activeWeaponIndex = 1,
				})
				if flags.self_character_chams then
					task.delay(0.5, characterChamsSelf, fake, nil, physicalChar)
				end
				setupStance()
			end
		end)

	end)

	for k, v in getconnections(game:GetService("LogService").MessageOut) do
		v:Disable()
	end

	local function wireframeRender(wireframe, object)
		local sx, sy, sz = object.Size.X / 2, object.Size.Y / 2, object.Size.Z / 2
		local baseCF = object.CFrame

		local function p(x, y, z)
			return (baseCF * cf(x, y, z)).Position
		end

		wireframe:AddPath({
			p( sx, -sy,  sz),
			p(-sx, -sy,  sz),

			p(-sx, -sy,  sz),
			p(-sx, -sy, -sz),

			p( sx, -sy, -sz),
			p( sx, -sy,  sz),

			p( sx,  sy,  sz),
			p( sx,  sy, -sz),

			p( sx, -sy, -sz),
			p( sx,  sy, -sz),

			p(-sx,  sy, -sz),
			p(-sx, -sy, -sz),

			p(-sx,  sy, -sz),
			p(-sx,  sy,  sz),

			p(-sx, -sy,  sz),
			p(-sx,  sy,  sz),

			p( sx,  sy,  sz),
		}, true)
	end

	local lastKillSay = 0
	local old; old = hookfunction(BulletObject.new, newcclosure(function(self, ...)
		local yummy = self
		if self.dt and self.visualorigin then
			local pos = self.position
			local life = self.life
			local final = self.position + (self.velocity * globals.frametime * (60 / life))


			params.FilterDescendantsInstances = {localChar, workspace.CurrentCamera, workspace:FindFirstChild("Ignore"), workspace.Terrain}
			local visibleRay = workspace:Raycast(
				self.position,
				(self.velocity * globals.frametime * (60 / life)),
				params
			)

			if visibleRay then
				final = visibleRay.Position
			end

			if visibleRay and visibleRay.Instance and visibleRay.Instance:IsDescendantOf(workspace:FindFirstChild("Players")) then

			end

			local isRealPlayer = false
			if visibleRay and visibleRay.Instance and visibleRay.Instance:IsDescendantOf(workspace:FindFirstChild("Players")) then
				local charPart = visibleRay.Instance
				local plr = Replication.getPlayerFromBodyPart(charPart)
				if plr then isRealPlayer = true end
			end


			if flags.onlyonkill then isRealPlayer = false end

			draw_bullet(pos, final, isRealPlayer)
		end
		return old(self, ...)
	end))


	local function onKillSuccess()
		local messages = {"seraph is pasted"}
		if (tick() - lastKillSay) > 5 and flags.killsay then
			lastKillSay = tick()
			local message = messages[math.random(1, #messages)]
			services.textChatService:WaitForChild("TextChannels"):WaitForChild("Global"):SendAsync(message)
		end
		if flags.onlyonkill then
			local sfxId = sfx[flags.killsound_l]
			if sfxId then
				local sound = Instance.new("Sound")
				sound.SoundId = sfxId
				sound.Name = ""
				sound.Volume = flags.sound_volume or 1
				sound.PlaybackSpeed = flags.pitchrng_l and math.random(95, 105) / 100 or 1
				sound.PlayOnRemove = true
				sound.Parent = services.soundService
				task.defer(game.Destroy, sound)
			end
		end
	end
	local bigAward = modules.HudNotificationInterface.bigAward
	modules.HudNotificationInterface.bigAward = newcclosure(function(...)
		local args = { ... }

		if args[2] == "kill" then
			onKillSuccess()
		end
		return bigAward(...)
	end)
	local smallAward = modules.HudNotificationInterface.smallAward
	modules.HudNotificationInterface.smallAward = newcclosure(function(...)
		local args = { ... }

		if args[2] == "head" then
			onKillSuccess()
		end
		return smallAward(...)
	end)

	local chatInterface = modules.ChatInterface
	modules.PlayerStatusEvents.onPlayerDied:connect(newcclosure(function(...)
		local args = { ... }

		if args[1].attacker == lp then
			onKillSuccess()
		end
		return
	end))

	if modules.MainCameraObject then
		local applyImpulse = modules.MainCameraObject.applyImpulse
		modules.MainCameraObject.applyImpulse = newcclosure(function(self, ...)
			local args = {...}

			if flags.recoil == true then
				args[1] = args[1] * (1 - (flags.recoilscale / 100))
			end

			return applyImpulse(self, unpack(args))
		end)
	end

	local spinYaw, inverter, pitchInverter, flip = 0, 1, 1, false

	function doPitch(mode, pitch)
		if mode == 'none' then
			return pitch
		elseif mode == 'zero' then
			return 0
		elseif mode == 'up' then
			return math.rad(89)
		elseif mode == 'down' then
			return math.rad(-89)
		elseif mode == 'sine' then
			return rad(-89 * cos(elapsed_ticks / 32))
		elseif mode == 'bob' then
			if flip then
				inverter = inverter - 5
				if (inverter <= -89) then
					flip = false
				end
			else
				inverter = inverter + 5
				if (inverter >= 89) then
					flip = true
				end
			end
			return rad(clamp(inverter, -89, 89))
		elseif mode == 'random' then

			return math.rad(math.random(-89, 89))
		elseif mode == 'inversion' then
			if floor(elapsed_ticks) % 5 == 0 then
				pitchInverter = pitchInverter * -1
			end
			return math.rad(-89) * pitchInverter
		end
		return pitch
	end

	function doYaw(mode, yaw)
		if mode == 'none' then
			return yaw
		elseif mode == 'spin' then
			spinYaw = (spinYaw + 0.5)
			return math.rad(spinYaw)
		elseif mode == 'fast spin' then
			spinYaw = (spinYaw + 3.5)
			return math.rad(spinYaw)
		elseif mode == 'sine spin' then
			spinYaw = (spinYaw + 5 - 2 * math.sin(elapsed_ticks / 32))
			return math.rad(spinYaw)
		elseif mode == 'random' then
			return math.rad(math.random(0, 360))
		elseif mode == 'backwards' then
			return yaw + math.rad(180)
		elseif mode == 'jitter' then
			return rng() > .5 and 2147483647 or floor(elapsed_ticks) % 10 >= 5 and math.rad(9e9) or math.rad(-9e9)
		end
		return yaw
	end

	setreadonly(debug,false)
	debug.hideupvalue = function(Function)
		return function(...)
			return Function(...)
		end
	end
	setreadonly(debug,true)

	if modules.PlayerSettingsInterface then
		local interface = modules.PlayerSettingsInterface
		local hook; hook = hookfunction(interface.getValue, debug.hideupvalue(function(...) 
			if debug.info(3, "s") and string.find(debug.info(3, "s"), "Firearm") then
				if not cameraAngle then return hook(...) end
				--print('[Phantom Forces] overriding camera angle for aimbot')
				for Index, Value in debug.getstack(3) do 
					if (typeof(Value) ~= "CFrame") then continue end
					debug.setstack(3, Index, CFrame.new(playerData.forcePos or scannedOrigin or Value.Position, cameraAngle))
				end
			end
			return hook(...)
		end))
	end

	local Event = game:GetService("ReplicatedStorage").RemoteEvent

	if modules.NetworkClient then
		local fakeLagElapsed, cancelledRepUpdates = 0, {}
		local oldSend = modules.NetworkClient.send
		local selfData
		sendData = function(...)
			if selfData then
				oldSend(selfData, ...)
			end
		end
		library.send_network_packet = sendData
		local delayPos = vec3()
		local lastTime = 0
		modules.NetworkClient.send = newcclosure(function(self, ...)

						local args = {...}
			--[[if library:is_shifting() and args[1] ~= "ping" then
				return
			end]]
			--print(args[1])
			if not selfData then selfData = self end
			playerData.ran = false
			--[[if args[1] == "repupdate" and velocity_desync.active and floor(elapsed_ticks) % 4 == 0 then
				task.delay(1/60,function()
					if not playerData.pos then return end
					local args = table.clone(args)
					args[2] = args[2] - (args[2] - playerData.pos) * 2
					args[5] = gameClock.getTime()
					oldSend(self, table.unpack(args))
				end)
			end]]
			--[[if args[1] == "repupdate" and velocity_desync.active and floor(elapsed_ticks) % 2 == 0 then
				if playerData.pos then args[2] = args[2] - (args[2] - playerData.pos) end
			end]]
			if args[1] == "newbullets" then
				library.thirdPersonAnimations["newbullets"]()

				local data = args[3]
				--[[
				-- This code was generated by Cobalt
-- https://github.com/notpoiu/cobalt

				local Event = game:GetService("ReplicatedStorage").RemoteEvent
				Event:FireServer(
					24525424,
					"newbullets",
					13,
					{
						firepos = Vector3.new(-100.90082550049, 3.6548271179199, -40.216243743896),
						bullets = {
							{
								Vector3.new(-0.50766134262085, -0.33275619149208, 0.79470318555832),
								31
							}
						},
						camerapos = Vector3.new(-102.10359191895, 4.3999996185303, -39.946228027344)
					},
					1037.4633995182
				)
	]]
				local old = args[3].firepos
				local realOrigin, firearmMuzzle = args[3].camerapos, args[3].firepos
				args[3].firepos = scannedOrigin or args[3].firepos
				args[3].camerapos = scannedOrigin and scannedOrigin + (args[3].camerapos - args[3].firepos) or args[3].camerapos
				local bulletDir = args[3].bullets[1][1]
				local baseFrame
				if flags.pf_backtrack_mode == "all records" then
					for player in backtrack.frames do
						if baseFrame then break end
						task.spawn(function()
							baseFrame = backtrack:findIntersectingRecord(player, args[3].firepos, bulletDir)
						end)
					end
				elseif flags.pf_backtrack_mode == "last record" then
					for player in backtrack.frames do
						if baseFrame then break end
						task.spawn(function()
							baseFrame = backtrack:checkOldestRecord(player, args[3].firepos, bulletDir)
						end)
					end
				end
				if baseFrame then
					local t = baseFrame.time
					args[4] = baseFrame.time
				end
				if scannedOrigin then workspace.CurrentCamera.CFrame = cf(args[3].camerapos) * workspace.CurrentCamera.CFrame.Rotation end
				if args[3].firepos ~= old then
					local line = Instance.new("Part")
					line.Anchored = true
					line.CanCollide = false
					line.Transparency = 1
					line.Material = Enum.Material.Neon
					line.CanQuery = false
					line.CanTouch = false
					local realOrigin, firearmMuzzle = old, args[3].firepos
					line.CFrame = cf(realOrigin, firearmMuzzle) * cf(0, 0, - (realOrigin - firearmMuzzle).Magnitude / 2)
					line.Size = vec3(0.05, 0.05, (realOrigin - firearmMuzzle).Magnitude)
					line.Parent = workspace.Terrain
					line.Transparency = 0.1
					line.Color = rgb(255,0,0)
					--print("pawjob")
					--print("hooking", old, 'to', args[3].firepos)
					--print("difference", (old - args[3].firepos).Magnitude)
				end
				local old = args[3].firepos
				--[[local line = Instance.new("Part")
				line.Anchored = true
				line.CanCollide = false
				line.Transparency = 1
				line.Material = Enum.Material.Neon
				line.CanQuery = false
				line.CanTouch = false
				local realOrigin, firearmMuzzle = args[3].firepos, args[3].firepos + args[3].bullets[1][1] * 5
				line.CFrame = cf(realOrigin, firearmMuzzle) * cf(0, 0, - (realOrigin - firearmMuzzle).Magnitude / 2)
				line.Size = vec3(0.05, 0.05, (realOrigin - firearmMuzzle).Magnitude)
				line.Parent = workspace.Terrain
				line.Transparency = 0.1
				line.Color = themes.preset.button:Lerp(rgb(255,255,255),.5)]]
				--print(http_service:JSONEncode(data))
			elseif args[1] == "repupdate" and flags.aa then
				fakeLagElapsed += 1
				local realPos = args[2]
				local pos = savedPos or args[2]
				--if not savedPos then savedPos = args[2] end
				--if pos ~= savedPos then savedPos = pos end
				local ang = args[3]
				--ang = Vector3.new(math.random() * math.random(-1,1) * math.pi, math.random() * math.random(-1,1) * math.pi, 0)
				--print('pos', `({tostring(pos)})`, typeof(pos))
				--warn('ang', `({tostring(ang)})`, typeof(ang))

				local pitch = ang.x
				pitch = doPitch(flags.pitch, pitch)
				local yaw = ang.y
				yaw = doYaw(flags.yaw, yaw)
				ang = Vector3.new(pitch, yaw, 0)


				--[[if position_desync.active then
					peakAsset.CFrame = cf(pos.x, pos.y - 2.95, pos.z)
					if realPos and (realPos - pos).Magnitude >= flags.posdesyncdistance then
						savedPos = nil
						for i, pos in cancelledRepUpdates do
							local args = table.clone(args)
							args[2] = pos
							args[3] = Vector3.new(
								ang.x,
								ang.y,
								0
							)
							tdf(i, oldSend, self, args)
						end
						args[2] = realPos
						playerData.pos = realPos
						table.clear(cancelledRepUpdates)
						fakeLagElapsed = 0
						drawBar("desync", 0, false, rgb(), themes.preset.button)
					else
						insert(cancelledRepUpdates, realPos)
						savedPos = pos
						if floor(elapsed_ticks) % 4 == 0 then
							local args = table.clone(args)
							args[2] = realPos
							tdf(10, oldSend, self, args)
							local args = table.clone(args)
							args[2] = pos
							tdf(20, oldSend, self, args)
						end
						drawBar("desync", #cancelledRepUpdates / 33, true, rgb(), themes.preset.button)
						if #cancelledRepUpdates >= 32 then
							for i = 1, 32 do
								table.remove(cancelledRepUpdates, 1)
							end
							args[2] = pos
						else
							return
						end
					end
				end]]

				args[2], args[3] = pos, ang

				--[[
				if fakelag.active and fakeLagElapsed < flags.ticks then
					insert(cancelledRepUpdates, {self = self, args = args})
					repeat task.wait() until fakeLagElapsed >= flags.ticks
				elseif fakelag.active and fakeLagElapsed >= flags.ticks then
					for _,v in cancelledRepUpdates do
						oldSend(v.self, table.unpack(v.args))
					end
					fakeLagElapsed = 0
				end
				]]

				--[[if fakelag.active then
					if fakeLagElapsed >= flags.ticks then
						savedPos = nil
						for i, pos in cancelledRepUpdates do
							local args = table.clone(args)
							args[2] = pos
							args[3] = Vector3.new(
								ang.x,
								ang.y,
								0
							)
							tdf(i, oldSend, self, args)
						end
						args[2] = realPos
						table.clear(cancelledRepUpdates)
						fakeLagElapsed = 0
					else
						insert(cancelledRepUpdates, realPos)
						savedPos = pos
						return
					end
				elseif #cancelledRepUpdates > 0 then
					savedPos = nil
					for i, pos in cancelledRepUpdates do
						local args = table.clone(args)
						args[2] = pos
						args[3] = Vector3.new(
							doPitch(flags.pitch, ang.x),
							doYaw(flags.yaw, ang.y),
							0
						)
						tdf(i, oldSend, self, args)
					end
					args[2] = realPos
					table.clear(cancelledRepUpdates)
					fakeLagElapsed = 0
				end]]
			end
			if playerData.forcePos and args[1] == "repupdate" then
				args[2] = playerData.forcePos
			end
			if cameraAngle and args[1] == "repupdate" then
				args[4] = cf(args[2], cameraAngle).lookVector
			end
			if args[1] == "repupdate" then
				playerData.ran = true
				playerData.pos, playerData.ang, playerData.bulletAng = args[2], args[3], args[4]
				--[[
				if scannedOrigin then
					args[2] = delayPos
				else
					delayPos = args[2]
				end
				]]
				
				--[[if anti_resolver.active then
					if not library.prev then library.prev = args[2] end
					local new = args[2] + vec3(random(-flags.max_distance,flags.max_distance), 0, random(-flags.max_distance,flags.max_distance)) * (elapsed_ticks % 2 == 0 and 1 or -1)
					if (library.prev - new).Magnitude > flags.stepsize then
						new = library.prev + (new - library.prev).Unit * flags.stepsize
					end
					if (library.prev - new).Magnitude > 40 then
						library.prev = new
					end
					local canWalkTo = workspace:Raycast(
						library.prev,
						(new - library.prev).Unit * (library.prev - new).Magnitude,
						raycastParamsWalkable
					)
					if canWalkTo then new = args[2] end
					args[2] = new
					library.prev = args[2]
				else
					library.prev = args[2]
				end
				if library.ignorePosEvents then return end]]
			elseif args[1] ~= "newbullets" then
				--[[if flags.delaypacket then
					local delayMs = flags.delaypacketms / 1000
					local clockData = gameClock.getTime()
					task.delay(delayMs, function()
						for index, value in args do
							if typeof(value) == "number" and value > clockData - 5 and value <= clockData then
								args[index] = gameClock.getTime()
							end
						end
						oldSend(self, table.unpack(args))
					end)
					return
				end]]
			end
			--args[4] = vec3()

			

			return oldSend(self, table.unpack(args))
		end)
	end

	local priority = {
		Head = 1,
		Torso = 2,
		["Right Arm"] = 3,
		["Left Arm"] = 4,
		["Right Leg"] = 5,
		["Left Leg"] = 6
	}

	local basePriority = table.clone(priority)

	function setUpWeight()
		local priority_list = { }
		local currentWeight = math.random(1,6)
		for priorityName in priority_list do

		end
	end

	local circle = Drawing.new("Circle")
	circle.Filled = false
	circle.NumSides = 64
	circle.Transparency = 0.7
	local dead_circle = Drawing.new("Circle")
	dead_circle.Filled = true
	dead_circle.NumSides = 32
	dead_circle.Transparency = 0.7
	local dbgT = Drawing.new("Text")
	dbgT.Position = workspace.CurrentCamera.ViewportSize / 2 + vec2(0, 100)
	dbgT.Visible = true
	dbgT.Size = 24
	dbgT.Color = themes.preset.button:lerp(rgb(255,255,255),0.5)
	dbgT.Center = true
	dbgT.Text = ""
	local liner = Drawing.new("Line")
	liner.Visible = true
	liner.Visible = true
	liner.Thickness = 2

	function tdf(c, f, ...)
		if c == 0 then
			return f(...)
		end

		return task.defer(tdf, c-1,f,...)
	end

	function tdf2(c, f, ...)
		if c == 0 then
			return f(...)
		end

		task.spawn(f, ...)

		return task.defer(tdf2, c-1,f,...)
	end

	local oldData = nil

	cons[#cons + 1] = services.runService.Heartbeat:Connect(function()
		local camera = workspace.CurrentCamera
		if oldData then
			local campos = camera.Focus.Position
			--draw_bullet(campos, mouse.Hit.Position)
			tdf(80, function()
				camera.CFrame = oldData
				oldData = nil
			end)
		end
	end)


	local function getRemainingPenetrationDepth(
		origin: Vector3,
		unitDir: Vector3,
		maxDistance: number,
		penetrationDepth: number,
		hitPart: BasePart,
		baseParams: RaycastParams
	)

		local entryPos = origin
		local exitParams = baseParams

		local exitResult = workspace:Raycast(
			entryPos,
			unitDir * maxDistance,
			exitParams
		)

		if not exitResult then
			return "FAILED CAST"
		end

		local exitPos = exitResult.Position
		local traveledInside = (exitPos - entryPos):Dot(unitDir)

		if traveledInside <= 0 then
			print('low travelDistance', traveledInside, penetrationDepth)
			return nil
		end

		if traveledInside >= penetrationDepth then
			print('travelInside too far', traveledInside, penetrationDepth)
			return nil
		end

		return {penetrationDepth - traveledInside, exitPos, exitResult.Instance}
	end


	local mouseClicked = 0
	local line = Instance.new("Part")
	line.Anchored = true
	line.CanCollide = false
	line.Transparency = 1
	line.Material = Enum.Material.Neon
	line.CanQuery = false
	line.CanTouch = false
	--[[local function simulateButtonFire(shotFrom, shotAt)
		local oldpos = line.Position
		data.shotFrom = newpos
		local dist = (oldpos - newpos).Magnitude
		networking.send("repupdate", data.shotFrom, rage.baseAngles, Vector3.zero, tickbase:getTickBase())

		local trajectory, bulletTime = mathematics.trajectory(newpos, pfModules.PublicSettings.bulletAcceleration, shotAt, weaponStat.bulletspeed)
		if trajectory and bulletTime then
			local canHit = pfModules.BulletCheck(newpos, shotAt, trajectory, pfModules.PublicSettings.bulletAcceleration, weaponStat.penetrationdepth, bulletTime)
			if canHit then
				pfModules.NetworkClient:send("newbullets", uniqueId, bulletData, tickbase:getTickBase())
				task.wait()
				networking.send("repupdate", newpos, rage.baseAngles, Vector3.zero, tickbase:getTickBase())
			else
				data.shotFrom = oldpos
				pfModules.NetworkClient:send("newbullets", uniqueId, bulletData, tickbase:getTickBase())
			end
		else
			data.shotFrom = oldpos
			pfModules.NetworkClient:send("newbullets", uniqueId, bulletData, tickbase:getTickBase())
		end
	end]]

	function traceTrajectory(origin, acceleration, target, speed, extra)
		local invertedAcc = -acceleration
		local targetOriginDiff = target - origin
		local a = invertedAcc:Dot(invertedAcc)
		local b = 4 * targetOriginDiff:Dot(targetOriginDiff)
		local c = 4 * (invertedAcc:Dot(targetOriginDiff) + speed * speed)
		local cam = c / (2 * a)
		local sqrtPart = math.sqrt(cam * (cam) - b / a)
		local time = math.sqrt((cam - sqrtPart < 0) and cam + sqrtPart or cam - sqrtPart)

		return invertedAcc * time / 2 + (extra or vec3()) + targetOriginDiff / time, time
	end


	local function hasproperty(object, property)
		return object[property] ~= nil
	end

	local chatScreenGui = modules.ChatScreenGui:getScreenGui().Main.ContainerChat
	chatScreenGui.DescendantAdded:Connect(function(descendant)
		if pcall(hasproperty, descendant, "Text") then
			local selfChanged; selfChanged = descendant.Changed:Connect(function()
				if descendant.Text:find("[Console]:") then
					descendant.Text = descendant.Text:gsub("[Console]:", " ")
					selfChanged:Disconnect()
				end
			end)
			task.delay(1, function()
				if selfChanged.Connected then
					selfChanged:Disconnect()
				end
			end)
		end
	end)
	local function asyncDamage(arg1, dmg)
		print(dmg, 'hi')
		arg1._healthstate.health0 = arg1._healthstate.health0 - dmg
	end
	local addDamage = modules.ReplicationObject.addDamage
	modules.ReplicationObject.addDamage = newcclosure(function(...)
		asyncDamage(...)
		return addDamage(...)
	end)
	local function handlePlayerHit(damageDealer, hitPlayer, hitPart, damageAmount, damageType, attacker)
		-- upvalues: (copy) v_u_7
		local playersHit = damageDealer.extra.playersHit
		if not playersHit[hitPlayer] then
			playersHit[hitPlayer] = true
			if flags.chatlogs then
				if not Replication.getEntry(hitPlayer) then
					chatInterface.addMessage({
						isTeamChat = false;
						message = `<font color="{rgbstr(themes.preset.button)}">[seraph.wtf]</font> Invalid or unavalible ReplicationObject for {hitPlayer.DisplayName}`;
						senderData = {
							senderType = "Console";
						};
					})
				end
				local entry = Replication.getEntry(hitPlayer)
				local ogHealth = entry._thirdPersonObject._replicationObject:getHealth()
				task.spawn(function()
					if flags.hit_chams then
						local char = entry._thirdPersonObject._characterModel
						local wireframe = library:create("WireframeHandleAdornment", {
							Thickness = 1,
							Color3 = themes.preset.button,
							Adornee = workspace.Terrain,
							Transparency = 0,
							AlwaysOnTop = true,
							CFrame = cf(),
							AdornCullingMode = Enum.AdornCullingMode.Never,
							ZIndex = 1,
							Parent = workspace
						})
						local partData = {}
						for _, basePart in char:GetDescendants() do
							if not basePart:IsA("BasePart") then continue end
							wireframeRender(wireframe, basePart)
							table.insert(partData, {Part = basePart, Size = basePart.Size, CFrame = basePart.CFrame})
						end
						local con = wireframe:GetPropertyChangedSignal("Transparency"):Connect(function()
							wireframe:Clear()
							for _, partData in partData do
								wireframeRender(wireframe, partData)
							end
						end)
						tween_service:Create(wireframe, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, flags.hit_chams_delay), {Transparency = 1}):Play()
						task.delay(flags.hit_chams_delay + 1, game.Destroy, wireframe)
						task.delay(flags.hit_chams_delay + 1, function()
							if con.Connected then
								con:Disconnect()
							end
						end)
					end
					--[[xpcall(function()
						local obj = entry._thirdPersonObject._replicationObject
						local didTimeout, timeWaiting = false, 0
						repeat
							timeWaiting += task.wait()
							if timeWaiting >= 0.8 then didTimeout = true break end
						until timeWaiting >= 0.85 or obj:getHealth() < ogHealth
						if didTimeout then return end
						local damageAmount = string.lower(damageAmount)
						local charObject = charInterface.getCharacterObject()
						local weaponController = charObject._weaponController
						local weaponObject = weaponController:getActiveWeapon()
						local damageTaken = ogHealth - entry._thirdPersonObject._replicationObject:getHealth()
						local remainingHealth = "???"
						local why, reason = pcall(function()
							remainingHealth = max(floor(ogHealth or 100) - floor(damageTaken), 0)
						end)
						if not why then
							chatInterface.addMessage({
								isTeamChat = false;
								message = `<font color="{rgbstr(themes.preset.button)}">[seraph.wtf]</font> Error calculating remaining health for {hitPlayer.DisplayName}. Reason: {reason}`;
								senderData = {
									senderType = "Console";
								};
							})
							return
						end
						chatInterface.addMessage({
							isTeamChat = false;
							message = `<font color="{rgbstr(themes.preset.button)}">[seraph.wtf]</font> hit {hitPlayer.DisplayName} for {floor(damageTaken)} hp ({remainingHealth} remaining) in their {string.lower(damageAmount)}.`;
							senderData = {
								senderType = "Console";
							};
						})
					end, function()
						chatInterface.addMessage({
							isTeamChat = false;
							message = `<font color="{rgbstr(themes.preset.button)}">[seraph.wtf]</font> hit {hitPlayer.DisplayName} for {floor(ogHealth)} hp (0 remaining) in their {string.lower(damageAmount)}.`;
							senderData = {
								senderType = "Console";
							};
						})
					end)]]
				end)
			end
			modules.HitDetectionInterface.playerHitDection(damageDealer, hitPlayer, hitPart, damageAmount, damageType, attacker)
		end
	end

	local id = 0
	library.network:receive("bulletHitConfirm", function(hitPlayer, hitGroup, hitPos, damageAmount)
		id += 1
		library.networkCache.bulletHits = (library.networkCache.bulletHits or 0) + 1
		library:spawnLog(`Hit <font color="{rgbstr(themes.preset.button)}">{hitPlayer.DisplayName}</font> for <font color="{rgbstr(themes.preset.button)}">{floor(damageAmount)}</font> damage in their <font color="{rgbstr(themes.preset.button)}">{string.lower(hitGroup)}</font>. [id={id}]`)
		chatInterface.addMessage({
			isTeamChat = false;
			message = `<font color="{rgbstr(themes.preset.button)}">[seraph.wtf]</font> hit {hitPlayer.DisplayName} for {floor(damageAmount)} in their {string.lower(hitGroup)}. [id={id}]`;
			senderData = {
				senderType = "Console";
			};
		})
	end)
	local counter = 0
	local forceHitQueue = {}
	function fireRound(weaponObject, unknownValue, tickExploit)
		-- upvalues: (copy) v_u_18, (copy) v_u_38, (copy) v_u_35, (copy) v_u_11, (copy) v_u_42, (copy) v_u_5, (copy) v_u_41, (copy) v_u_34, (copy) v_u_46, (copy) v_u_4, (ref) v_u_49, (copy) v_u_16, (copy) v_u_22, (copy) v_u_48, (copy) v_u_58, (copy) v_u_7, (copy) v_u_24, (copy) v_u_30, (copy) v_u_9, (copy) v_u_12
		local mainCamera = modules.CameraInterface.getActiveCamera("MainCamera")
		local characterObject = weaponObject._characterObject
		local animationThread = characterObject.thread
		local fireDelay = (weaponObject._singleactionready or weaponObject:getFiremode() == "DOUBLE" and weaponObject:getWeaponStat("doubleactiondelay") or (weaponObject:getActiveAimStat("firedelay") or 0))
		local recoilDelay = weaponObject:getActiveAimStat("recoildelay") or fireDelay
		local firePosition = nil
		local isFiring = false
		local rapidFireMultiplier = 1
		local ent = 0
		while weaponObject._magCount > 0 and weaponObject:canFire() do
			ent += 1
			if (ent > 100) then break end
			local oldTickTime = gameClock.getTime()
			if tickbase_manip.active and burst_exploit.active and not tickExploit then
				if flags.bullets_fullshift then
					task.spawn(function()
						repeat
							library:shift_tickbase()
							fireRound(weaponObject, unknownValue, true)
							task.wait()
						until (library:get_tickbase() <= 0)
					end)
				else
					task.spawn(function()
						library:shift_tickbase()
						task.delay(fireDelay / 2, fireRound, weaponObject, unknownValue, true)
					end)
				end
			end
			local tickDifference = gameClock.getTime() - oldTickTime
			local currentTime = oldTickTime + tickDifference
			if weaponObject._inspecting then
				weaponObject._inspecting = false
				weaponObject:cancelAnimation(weaponObject._reloadCancelTime)
			end
			weaponObject.threadWeapon:clear()
			if (characterObject.reloading or not weaponObject:getWeaponStat("forceonfire")) and (weaponObject._magCount <= 1 or not (weaponObject:getWeaponStat("onfireanim") or weaponObject:getWeaponStat("animations").onfire) or weaponObject:isAiming() and (not weaponObject:isAiming() or weaponObject:getActiveAimStat("pullout") and not weaponObject:getWeaponStat("straightpull"))) then
				if weaponObject:getWeaponStat("shelloffset") then
					if not weaponObject:getWeaponStat("caselessammo") then
						modules.Effects.ejectshell(weaponObject._mainPart.CFrame, weaponObject:getWeaponStat("casetype") or weaponObject:getWeaponStat("ammotype"), weaponObject:getWeaponStat("shelloffset"), weaponObject:getWeaponStat("shelldirection"))
					end
					if weaponObject._magCount > 0 then
						weaponObject.threadWeapon:add(function(boltStopValue)
							-- upvalues: (copy) p_u_351
							if weaponObject._magCount <= 0 and weaponObject:getWeaponStat("boltlock") then
								return weaponObject:boltStop(boltStopValue)
							else
								return weaponObject:boltKick(boltStopValue)
							end
						end)
					end
				end
			else
				animationThread:clear()
				animationThread:delay(weaponObject:getFiremode() == "DOUBLE" and 0 or (weaponObject:getWeaponStat("onfiredelay") or 0))
				animationThread:add(function()
					-- upvalues: (copy) p_u_351, (copy) v_u_354
					weaponObject:getActiveAimStat("zoom")
					local singlePullout = weaponObject:getActiveAimStat("zoompullout")
					if not singlePullout then
						if weaponObject:getFiremode() == "SINGLE" then
							singlePullout = weaponObject:getWeaponStat("singlepullout")
						else
							singlePullout = false	
						end
					end
					if singlePullout then
						weaponObject._aimArmSpring.t = weaponObject:getWeaponStat("aimarmblend") or (weaponObject:getWeaponStat("straightpull") and 1 or 0)
						characterObject:getSpring("zoommodspring").t = weaponObject:isAiming() and not (weaponObject:getWeaponStat("aimspringcancel") or weaponObject:getWeaponStat("straightpull")) and 0.5 or 1
						weaponObject:updateAimStats()
					end
					if not weaponObject:getWeaponStat("ignorestanceanim") then
						weaponObject._reloadSpring.t = 1
					end
					characterObject.animating = true
					weaponObject._yieldToAnimation = true
					weaponObject._bolting = true
				end)
				local onFireAnimationName
				if weaponObject:isAiming() and weaponObject:getActiveAimStat("onfireaimedanim") then
					onFireAnimationName = "onfire" .. weaponObject:getActiveAimStat("onfireaimedanim")
				else
					onFireAnimationName = weaponObject:getFiremode() == "DOUBLE" and "onfiredouble" or (weaponObject:getFiremode() == "SINGLE" and "onfiresingle" or (not weaponObject:getActiveAimStat("onfireanim") and "onfire" or "onfire" .. weaponObject:getActiveAimStat("onfireanim")))
				end
				local onFireAnimation = weaponObject:getWeaponStat("animations")[onFireAnimationName]
				if weaponObject:getFiremode() ~= "SINGLE" or weaponObject._magCount > 1 then
					animationThread:add(modules.Animation.player(weaponObject._animData, onFireAnimation, weaponObject, onFireAnimationName))
				end
				animationThread:delay(fireDelay)
				animationThread:add(function()
					-- upvalues: (copy) p_u_351, (copy) v_u_354, (copy) v_u_355, (ref) v_u_35, (copy) v_u_364, (ref) v_u_11
					if not weaponObject:isStateReloading() then
						if weaponObject:isAiming() then
							characterObject:getSpring("zoommodspring").t = 1
							weaponObject._aimArmSpring.t = 1
							weaponObject:updateAimStats()
						end
						if weaponObject:getFiremode() == "SINGLE" then
							weaponObject._singleactionready = true
						else
							animationThread:add(modules.Animation.reset(weaponObject._animData, onFireAnimation.resettime, weaponObject:getWeaponStat("keepanimvisibility") or weaponObject:isAiming()))
						end
						weaponObject._bolting = false
						characterObject.animating = false
						weaponObject._yieldToAnimation = false
						weaponObject._reloadSpring.t = 0
						local actionBindInterface = modules.ActionBindInterface
						if actionBindInterface.isInputActionDown("Aim Weapon Hold") then
							weaponObject:setAim(true)
						elseif not (weaponObject._auto or weaponObject._wasBlackScoped) then
							characterObject:setSprint(actionBindInterface.isInputActionDown("Sprint Hold") or (actionBindInterface.isInputActionDown("Move Forward") and characterObject.doubletap or weaponObject._wasSprinting))
						end
						if characterObject:isSprinting() then
							characterObject:getSpring("sprintspring").s = weaponObject:getWeaponStat("sprintspeed")
							characterObject:getSpring("sprintspring").d = weaponObject:getWeaponStat("sprintdamping") or 0.9
							characterObject:getSpring("sprintspring").t = 1
						end
						if weaponObject:getWeaponStat("forcereload") and (weaponObject._magCount <= 0 and not weaponObject:isAiming()) then
							weaponObject:reload()
						end
					end
				end)
			end
			if weaponObject._burst ~= 0 then
				weaponObject._burst = weaponObject._burst - 1
			end
			isFiring = true
			weaponObject:fireInput("shoot", currentTime)
			task.delay(recoilDelay, function()
				-- upvalues: (copy) p_u_351, (copy) p_u_352
				if weaponObject._destructor then
					weaponObject:impulseSprings(unknownValue)
				end
			end)
			if weaponObject:isAiming() then
				if weaponObject:getWeaponStat("animations").onfire and weaponObject:getActiveAimStat("pullout") then
					weaponObject._needRechambering = "onfire"
				end
			else
				modules.HudCrosshairsInterface.fireImpulse(weaponObject:getWeaponStat("crossexpansion") * (1 - unknownValue))
			end
			local fireCount = weaponObject._fireCount
			task.delay(fireDelay, function()
				-- upvalues: (copy) v_u_354, (copy) v_u_353, (copy) p_u_351, (ref) v_u_358, (ref) v_u_41, (ref) v_u_34, (ref) v_u_46, (copy) v_u_365, (ref) v_u_4, (ref) v_u_49, (ref) v_u_16, (ref) v_u_22, (ref) v_u_48, (copy) v_u_360, (ref) v_u_58, (ref) v_u_7, (ref) v_u_24, (ref) v_u_38
				local rootCF = characterObject:getRootPart().CFrame
				local rootCFrame = scannedOrigin and cf(scannedOrigin)*rootCF.Rotation or rootCF
				local cameraPosition = scannedOrigin or mainCamera:getBaseCFrame().p
				local barrelCFrame = rootCFrame * weaponObject._mainC0 * (weaponObject:isAiming() and weaponObject._activeAimOffsets[weaponObject:getActiveAimStat("sightpart")] or weaponObject._barrelOffset)
				if cameraAngle then
					barrelCFrame = CFrame.lookAt((flags.pf_nospread and cameraPosition or barrelCFrame.p), cameraAngle)
				end
				if not firePosition then
					local raycastResult = modules.Raycast.raycast(cameraPosition, barrelCFrame.p - cameraPosition, {
						modules.TeamConfig.getTeamFolder(lp.TeamColor),
						workspace.Terrain,
						workspace.Ignore,
						workspace.CurrentCamera
					})
					if raycastResult then
						firePosition = raycastResult.Position + 0.01 * raycastResult.Normal
					else
						firePosition = barrelCFrame.p
					end
				end
				local bulletHitDataList = {}
				local bulletList = {}
				local bulletData = {
					["camerapos"] = cameraPosition,
					["firepos"] = firePosition,
					["bullets"] = bulletList
				}
				local samplePointX, samplePointY = weaponObject._samplePointGenerator:getPoint(fireCount)
				local pelletCount = weaponObject:getWeaponStat("pelletcount") or 1
				pelletCount *= rapidFireMultiplier
				local isApertureVisible = modules.PlayerSettingsInterface.getValue("toggleglasshacktracers") and weaponObject:isAiming() and (not weaponObject:isBlackScoped() and weaponObject:getActiveAimStat("sightObject"))
				if isApertureVisible then
					isApertureVisible = weaponObject:getActiveAimStat("sightObject"):isApertureVisible()
				end
				for pelletIndex = 1, pelletCount do
					counter = counter + 1
					local bulletTicket = counter
					local bulletDirection
					if weaponObject:getWeaponStat("variablechoke") or (weaponObject:getWeaponStat("spread") or weaponObject:getWeaponStat("crosssize") and weaponObject:getWeaponStat("aimchoke")) then
						local spreadValue = weaponObject:getWeaponStat("variablechoke") and weaponObject._chokeSpring.p or (weaponObject:getWeaponStat("spread") or 0.6666666666666666 * weaponObject:getWeaponStat("crosssize") * weaponObject:getWeaponStat("aimchoke") / weaponObject:getWeaponStat("bulletspeed"))
						local sqrtInputX = (pelletIndex - samplePointY) / pelletCount
						local sqrtResultX = math.sqrt(sqrtInputX)
						local angleX = (pelletIndex - samplePointX) * 2.399963229728653
						local cosAngleX = sqrtResultX * math.cos(angleX)
						local angleY = (pelletIndex - samplePointX) * 2.399963229728653
						local yOffset = sqrtResultX * math.sin(angleY)
						local intermediateValue = cosAngleX * cosAngleX + yOffset * yOffset
						repeat
							sqrtInputX = (pelletIndex - samplePointY) / pelletCount
							sqrtResultX = math.sqrt(sqrtInputX)
							angleX = (pelletIndex - samplePointX) * 2.399963229728653
							cosAngleX = sqrtResultX * math.cos(angleX)
							angleY = (pelletIndex - samplePointX) * 2.399963229728653
							yOffset = sqrtResultX * math.sin(angleY)
							intermediateValue = cosAngleX * cosAngleX + yOffset * yOffset
						until intermediateValue <= 1.00001
						local logValue = -math.log(intermediateValue) / intermediateValue
						local spreadOffset = spreadValue * math.sqrt(logValue)
						local xOffset = spreadOffset * (weaponObject:getWeaponStat("choke") and weaponObject:getWeaponStat("xbias") or 1) * cosAngleX
						local biasedYOffset = spreadOffset * (weaponObject:getWeaponStat("choke") and weaponObject:getWeaponStat("ybias") or 1) * yOffset
						if flags.pf_nospread then
							xOffset = 1e-4
							biasedYOffset = 1e-4
						end
						bulletDirection = barrelCFrame:VectorToWorldSpace((Vector3.new(xOffset, biasedYOffset, -1))).unit
					else
						bulletDirection = barrelCFrame.lookVector
					end
					modules.BulletInterface.newBullet({
						["position"] = firePosition,
						["velocity"] = weaponObject:getWeaponStat("bulletspeed") * bulletDirection,
						["acceleration"] = (weaponObject:getWeaponStat("bulletaccel") or 0) * bulletDirection + modules.PublicSettings.bulletAcceleration,
						["color"] = weaponObject:getWeaponStat("bulletcolor") or Color3.fromRGB(255, 94, 94),
						["size"] = 0.2,
						["bloom"] = 0.005,
						["brightness"] = weaponObject:getWeaponStat("bulletbrightness") or 400,
						["life"] = modules.PublicSettings.bulletLifeTime,
						["visualorigin"] = barrelCFrame.Position,
						["physicsignore"] = {
							workspace.Players,
							workspace.Terrain,
							workspace.Ignore,
							workspace.CurrentCamera
						},
						["dt"] = currentTime - weaponObject._nextShot,
						["penetrationdepth"] = weaponObject:getWeaponStat("penetrationdepth"),
						["tracerless"] = weaponObject:getWeaponStat("tracerless"),
						["onplayerhit"] = handlePlayerHit,
						["usingGlassHack"] = isApertureVisible,
						["extra"] = {
							["playersHit"] = {},
							["bulletTicket"] = bulletTicket,
							["firstHits"] = bulletHitDataList,
							["firearmObject"] = weaponObject,
							["uniqueId"] = weaponObject.uniqueId
						},
						["ontouch"] = modules.HitDetectionInterface.hitDetection
					})
					bulletList[#bulletList + 1] = { bulletDirection, bulletTicket }
				end
				modules.NetworkClient:send("newbullets", weaponObject.uniqueId, bulletData, gameClock.getTime())
				local networkHandler = modules.NetworkClient
				for bulletIndex = 1, #bulletHitDataList do
					local weaponId = weaponObject.uniqueId
					local bulletHitData = bulletHitDataList[bulletIndex]
					networkHandler:send("bullethit", weaponId, unpack(bulletHitData))
				end
				local forceHit = forceHitQueue[1]
				if forceHit then
					local healthMultiplier = modules.WeaponUtils.interpolateDamageGraph(weaponObject:getWeaponStat("damageGraph"), (firePosition - forceHit.pos).Magnitude)
					healthMultiplier *= weaponObject:getWeaponStat("multhead")
					if tickbase_manip.active then
						for i = 1, 2 do
							library:shift_tickbase()
							networkHandler:send("bullethit", weaponObject.uniqueId, forceHit.player, forceHit.pos, forceHit.hitboxName, bulletTicket, gameClock.getTime())
						end
					else
						networkHandler:send("bullethit", weaponObject.uniqueId, forceHit.player, forceHit.pos, forceHit.hitboxName, bulletTicket, gameClock.getTime())
					end
					table.remove(forceHitQueue, 1)
				end
				--[[for i, v in next, bulletData.bullets do
					networkHandler:send("bullethit", weaponObject.uniqueId, plrData.plr, shotAt, shotPart, v[2], tickbase:getTickBase())
				end	]]	
			end)
			weaponObject._fireCount = weaponObject._fireCount + 1
			weaponObject._magCount = weaponObject._magCount - 1
			weaponObject._nShots = weaponObject._nShots + 1
			weaponObject._singleactionready = nil
			if weaponObject._burst <= 0 and (weaponObject:getWeaponStat("firecap") and (weaponObject:getFiremode() ~= true and weaponObject:getFiremode() ~= 1)) then
				weaponObject._nextShot = currentTime + 60 / weaponObject:getWeaponStat("firecap")
			elseif weaponObject:isAiming() and weaponObject:getActiveAimStat("aimedfirerate") then
				weaponObject._nextShot = weaponObject._nextShot + 60 / weaponObject:getActiveAimStat("aimedfirerate")
			else
				weaponObject._nextShot = weaponObject._nextShot + 60 / weaponObject:getFirerate()
			end
			if weaponObject._magCount <= 0 then
				weaponObject._burst = 0
				weaponObject._auto = false
				task.delay(fireDelay, function()
					-- upvalues: (copy) p_u_351
					if weaponObject:getWeaponStat("magdisappear") then
						weaponObject:getWeaponPart(weaponObject:getWeaponStat("mag")).Transparency = 1
					end
					if not ((weaponObject:getActiveAimStat("pullout") or weaponObject:getActiveAimStat("blackscope")) and weaponObject:isAiming()) and (weaponObject:getWeaponStat("firemodes")[1] == true or not weaponObject:isAiming()) then
						weaponObject:reload()
					end
				end)
			end
		end
		local audioSystem = modules.AudioSystem
		if isFiring then
			task.delay(fireDelay, function()
				-- upvalues: (copy) p_u_351, (ref) v_u_30, (ref) v_u_4, (ref) v_u_42, (copy) v_u_354, (ref) v_u_9, (ref) v_u_12
				task.delay(0.4, function()
					-- upvalues: (ref) p_u_351, (ref) v_u_30
					if weaponObject:getWeaponStat("type") == "SNIPER" then
						audioSystem.play("metalshell", 12, 0.15, 0.8)
						return
					elseif weaponObject:getWeaponStat("type") == "SHOTGUN" then
						task.wait(0.3)
						audioSystem.play("shotgunshell", 12, 0.2)
					elseif weaponObject:getWeaponStat("type") ~= "REVOLVER" and not weaponObject:getWeaponStat("caselessammo") then
						audioSystem.play("metalshell", 12, 0.1)
					end
				end)
				if weaponObject:getWeaponStat("sniperbass") then
					audioSystem.play("1PsniperBass", 1, 0.75)
					audioSystem.play("1PsniperEcho", 1, 1)
				end
				if not weaponObject:getWeaponStat("nomuzzleeffects") then
					if modules.PlayerSettingsInterface.getValue("firstpersonmuzzleffectsenabled") then
						modules.Effects.muzzleflash(weaponObject._barrelPart, weaponObject:getWeaponStat("hideflash"), 0.9)
					end
					if not weaponObject:getWeaponStat("hideflash") then
						characterObject:fireMuzzleLight()
					end
				end
				if not weaponObject:getWeaponStat("hideminimap") then
					modules.HudSpottingInterface.goingLoud()
				end
				audioSystem.playSoundId(weaponObject:getWeaponStat("firesoundid"), 2, weaponObject:getWeaponStat("firevolume"), weaponObject:getWeaponStat("firepitch"), weaponObject._barrelPart, nil, 0, 0.05)
				modules.HudStatusInterface.updateAmmo(weaponObject)
			end)
		end
	end
	modules.FirearmObject.fireRound = newcclosure(function(...)
		return task.spawn(fireRound, ...)
	end)

	local function getDropOffset(
		origin: Vector3,
		target: Vector3,
		bulletSpeed: number,
		acceleration: Vector3
	): Vector3
		--[[local delta = target - origin
		local horizontalDistance = Vector3.new(delta.X, 0, delta.Z).Magnitude
		local t = horizontalDistance / bulletSpeed
		return 0.5 * acceleration * t * t]]
		local totalDistance = (target - origin).Magnitude
		local timeToArrive = totalDistance / bulletSpeed
		return (acceleration * globals.frametime) * timeToArrive
	end

	local lastScan, lastSim = tick(), tick()

	local lastMoveTime = tick()
	local currentVelocity = vec2(0, 0)
	local reactionTime = 0
	function updateAimbot()
		-- ===== character / weapon validation =====
		local charObject = charInterface.getCharacterObject()
		if not charObject then return end

		local weaponController = charObject._weaponController
		if not weaponController then return end

		local weapon = weaponController:getActiveWeapon()
		if not weapon or weapon:getWeaponType() ~= "Firearm" then return end

		-- ===== burst exploit =====
		if burst_exploit.active and weapon:getWeaponStat("firemodes")
			and #weapon:getWeaponStat("firemodes") >= 1 then

			local index = (weapon._firemodeIndex % #weapon:getWeaponStat("firemodes")) + 1
			setreadonly(weapon._weaponData, false)
			weapon._weaponData.burstfirerate = 5
			weapon._firemodeIndex = index

			if not table.find(weapon:getWeaponStat("firemodes"), "SWITCH") then
				setreadonly(weapon:getWeaponStat("firemodes"), false)
				table.insert(weapon:getWeaponStat("firemodes"), "SWITCH")
				setreadonly(weapon:getWeaponStat("firemodes"), true)
			end

			setreadonly(weapon._weaponData, true)
			
			drawBar("rapidfire", weapon._burst / 30, true, rgb(), themes.preset.button_alt)

			if (weapon._burst > 0) then
				weapon._needRechambering = false
				weapon._bolting = false
				weapon._singleactionready = false
				--weapon._firemodeIndex = table.find(weapon:getWeaponStat("firemodes"), "SWITCH") or table.find(weapon:getWeaponStat("firemodes"), "BURST") or 1
			end
		else
			if weapon._burst and weapon._burst > 5 then
				weapon._burst = 0
			end
			drawBar("rapidfire", 0, false, rgb(), themes.preset.button_alt)
		end

		if mouseClicked > 0 then
			mouseClicked -= globals.frametime
			if mouseClicked <= 0 then
				mouseClicked = 0
				weapon:shoot(false)
			end
		end

		-- ===== simrate gate =====
		if tick() - lastSim < flags.pf_simrate / 1000 then return end
		lastSim = tick()

		-- ===== muzzle position (FIXED ray direction) =====
		local camPos = workspace.CurrentCamera.CFrame.Position
		local firearmMuzzle = weapon:getBarrelCFrame().Position

		local muzzleRay = workspace:Raycast(
			firearmMuzzle,
			(camPos - firearmMuzzle),
			params
		)

		if muzzleRay then
			firearmMuzzle = muzzleRay.Position
				- (camPos - firearmMuzzle).Unit * 0.5
		end

		if flags.pf_muzzleredirect then
			firearmMuzzle = library.char and library.char.Head.Position or firearmMuzzle
		end

		-- ===== reload cancel =====
		if weapon._activeReloadSequence and not weapon._oldReloadSequence and flags.instantreload then
			weapon._oldReloadSequence = weapon._activeReloadSequence
			weapon._activeReloadSequence = setmetatable({}, {
				__index = function(_, i)
					return print("Blocked reload index", i)
				end
			})
		end

		if burst_exploit.active and (weapon._nextShot - gameClock.getTime()) > 0 then
			return
		end

		-- ===== origin scan visual =====
		if flags.pf_originscan then
			if (visualization.Position - firearmMuzzle).Magnitude >= 25 then
				visualization.Position = firearmMuzzle
			end

			local alpha = correctAlpha(
				math.clamp(0.5 - (firearmMuzzle - visualization.Position).Magnitude / 35, 0.45, 0.8),
				globals.frametime
			)

			visualization.Position =
				visualization.Position:Lerp(firearmMuzzle - vec3(0, 1.5, 0), alpha)
		end

		-- ===== targeting =====
		local targetPart, targetPos, targetEntry
		local closestDistance = math.huge
		local foundTarget = false
		local isAlive = library.char and library.char:IsDescendantOf(workspace)

		local mouse = uis:GetMouseLocation()
		local mx, my = mouse.X, mouse.Y

		Replication.operateOnAllEntries(function(player, entry)
			if foundTarget then entry.oldPos = nil return end
			if not entry:isAlive() or not entry:isEnemy() then entry.oldPos = nil return end

			entry.oldPos = entry.pos or entry:getThirdPersonObject()
					and entry:getThirdPersonObject():getCharacterHash().Torso.Position
			entry.pos = entry:getThirdPersonObject()
					and entry:getThirdPersonObject():getCharacterHash().Torso.Position

			local char = entry:getThirdPersonObject()
				and entry:getThirdPersonObject():getCharacterHash()
			if not char or not char.Torso then return end

			if player_list[player.Name]
				and player_list[player.Name].ignore_player then
				return
			end

			if (tickbase_manip.active and not library:is_shifting()
				and originscan.active and not library.is_moving) and tick() - lastScan > 1 then
				library.is_moving = true
				library:moveto(
					library.char.HumanoidRootPart.Position,
					char.Torso.Position
				)
				library.is_moving = false
				lastScan = tick()
			end

			-- ===== BACKTRACK RESOLVE =====
			local btFrame
			if flags.pf_backtrack and isAlive then
				btFrame =
					backtrack:findIntersectingRecord(
						player,
						firearmMuzzle,
						(camPos - firearmMuzzle)
					) or backtrack:checkOldestRecord(
						player,
						firearmMuzzle,
						(camPos - firearmMuzzle)
					)
			end

			params.FilterDescendantsInstances = {
				localChar,
				workspace.CurrentCamera,
				workspace.Terrain,
				workspace:FindFirstChild("Ignores")
			}

			-- ===== hitbox loop =====
			for _, hitboxName in (flags.pf_cumhitbox and { pickCumulativeHitbox() }
				or flags.pf_hitbox or {}) do

				local part = char[hitboxName]
				if not part then continue end

				local btCF = btFrame and btFrame.tracked[hitboxName]
				local pos = btCF and btCF.Position or part.Position

				-- visibility / autowall
				if flags.pf_autowall then
					local traj, time = traceTrajectory(
						firearmMuzzle,
						modules.PublicSettings.bulletAcceleration,
						pos,
						weapon:getWeaponStat("bulletspeed")
					)

					if not traj then continue end
					local ok = modules.BulletCheck(
						firearmMuzzle,
						pos,
						traj,
						modules.PublicSettings.bulletAcceleration,
						weapon:getWeaponStat("penetrationdepth"),
						time
					)

					if not ok then continue end
				else
					local vis = workspace:Raycast(
						firearmMuzzle,
						(pos - firearmMuzzle),
						params
					)

					if not vis or vis.Instance ~= part then
						continue
					end
				end

				-- screen FOV
				local screenPos, onScreen = worldToScreenPoint(pos)
				if not onScreen and not flags.pf_fullfov then continue end

				local dist = (vec2(mx, my) - screenPos).Magnitude
				local distSelf = (workspace.CurrentCamera.CFrame.Position - pos).Magnitude
				local dynDeadzone = flags.pf_dynamic_deadzone and (distSelf >= 100 and -3 or clamp(10 - distSelf / 50, 0, 10)) or 0
				if dist < (flags.pf_deadzone_fov + dynDeadzone) and flags.pf_deadzone and flags.pf_aimbot == "normal" then continue end
				if not flags.pf_infinitefov and dist > flags.pf_fov then continue end
				if dist >= closestDistance then continue end

				targetPart = part
				targetPos = pos
				closestDistance = dist
				targetEntry = entry
				foundTarget = true
			end
		end)

		-- ===== aim execution =====
		if not foundTarget then
			if mouseClicked <= 0 then cameraAngle = nil end
			weapon._burst = 0
			return
		end

		if flags.pf_onlyrmb and not uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			return
		end

		if flags.pf_aimbotmode == "normal" then

			local sens = flags.pf_mousesens 
				and (uis.MouseDeltaSensitivity / 10) 
				or (flags.pf_sensitivity / 100)

			local screenPos = worldToScreenPoint(targetPos)
			local mousePos = vec2(mx, my)
			local delta = screenPos - mousePos
			local distance = delta.Magnitude


			local smoothingFactor = math.clamp(sens * (1 / (distance * 0.05)), 0.01, sens)

			local strength = flags.pf_magnet 
				and math.clamp(flags.pf_magnet_distance / math.max(closestDistance, 5), 1, flags.pf_magnet_strength) 
				or 1


			local tremorX = math.noise(tick() * 5, 0) * (flags.pf_randomization_amount or 0)
			local tremorY = math.noise(0, tick() * 5) * (flags.pf_randomization_amount or 0)

			local finalMove = delta * (smoothingFactor * strength)

			if flags.pf_overshoot and distance > flags.pf_overshoot_fov then
				finalMove = finalMove * flags.pf_overshoot_amount
			end

			mousemoverel(finalMove.X + tremorX, finalMove.Y + tremorY)

			if flags.pf_autofire then
				if distance < (flags.pf_fov * 1.2) then 
					if tick() - lastMoveTime > reactionTime then
						weapon:shoot(true)
						mouseClicked = globals.frametime
						
						reactionTime = math.random(70, 150) / 10000
						lastMoveTime = tick()
					end

					local bulletSpeed = weapon:getWeaponStat("bulletspeed")
					local accel = modules.PublicSettings.bulletAcceleration

					local drop = getDropOffset(
						firearmMuzzle,
						targetPos,
						bulletSpeed,
						accel
					)

					cameraAngle = targetPos - drop
					local difference = (cameraAngle - firearmMuzzle).Magnitude / bulletSpeed
					if flags.extrapolate then
						cameraAngle += ((targetEntry.pos - targetEntry.oldPos)) * difference
					end
					--print((entry._thirdPersonObject._smoothReplication:getFrame(gameClock.getTime() - library.tickTime).velocity * globals.frametime) * difference

					forceHitQueue[1] = {
						player = nil,
						pos = cameraAngle,
						hitboxName = targetPart.Name
					}
				end
			else
				-- Reset reaction time when not firing
				reactionTime = 0
			end
		else -- silent
			local bulletSpeed = weapon:getWeaponStat("bulletspeed")
			local accel = modules.PublicSettings.bulletAcceleration

			local drop = getDropOffset(
				firearmMuzzle,
				targetPos,
				bulletSpeed,
				accel
			)

			cameraAngle = targetPos - drop
			local difference = (cameraAngle - firearmMuzzle).Magnitude / bulletSpeed
			if flags.extrapolate then
				cameraAngle += ((targetEntry.pos - targetEntry.oldPos)) * difference
			end
			--print((entry._thirdPersonObject._smoothReplication:getFrame(gameClock.getTime() - library.tickTime).velocity * globals.frametime) * difference

			forceHitQueue[1] = {
				player = nil,
				pos = cameraAngle,
				hitboxName = targetPart.Name
			}

			if burst_exploit.active and weapon:getWeaponStat("firemodes")
			and #weapon:getWeaponStat("firemodes") <= 1 then
				weapon._burst = 2
			end

			if flags.pf_autofire then
				weapon:shoot(true)
				mouseClicked = globals.frametime
			end
		end
	end



	--for k,v in moduleCache do print(k) end
	local elapsedDuck = 0
	local tickbase = {
		charge = 0,
		max_shift = 5.0,
		last_time = gameClock.getTime(),
		is_charging = false,
		tickTime = 0,
		is_releasing = false,
	}

	function library:is_shifting()
		return tickbase.is_charging
	end

	local oldGetTime = modules.GameClock.getTime
	local lastFrame = oldGetTime()
	--[[modules.GameClock.getTime = newcclosure(function()
		if tickbase.charge == 0 then
			return oldGetTime()
		end
		local timeShift = (tickbase.is_charging and tickbase.charge or 0)
		local curTime = oldGetTime() + timeShift + (library.tickTime or 0)
		if lastFrame > curTime then
			curTime = lastFrame
		end
		return clamp(curTime, 0, oldGetTime())
	end)

	print'ok']]

	function library:moveto(current, target)
		playerData.forcePos = current
		local isDone = false
		local dist = 2
		local path = services.pathfindingService:CreatePath({
			AgentRadius = 3, 
			AgentHeight = 3,
			WaypointSpacing = dist,
			AgentCanJump = false,
			Costs = {
				Water = math.huge
			}
		})
		local success = pcall(path.ComputeAsync, path, current, target)
		if success then
			local result = path.Status

			if result == Enum.PathStatus.Success  then
				local path = path:GetWaypoints()
				local pathPoints = {}

				for _, waypoint in path do
					local part = Instance.new("Part")
					part.Position = waypoint.Position + vec3(0, 3.0, 0)
					part.Size = Vector3.new()
					part.Color = Color3.new(1, 0, 1)
					part.Anchored = true
					part.CanCollide = false
					part.Shape = Enum.PartType.Ball
					part.Parent = workspace

					tween_service:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						Size = vec3(1, 1, 1)
					}):Play()

					table.insert(pathPoints, part)
				end

				library.ignorePosEvents = true
				repeat
					local success = pcall(function()
						library:shift_tickbase()	
						local currentTarget = path[1]
						local old = current
						if currentTarget ~= nil then
							local targetPos = currentTarget.Position + vec3(0, 3.0, 0)
							local diff = (targetPos - current)
							local totalDistance = diff.Magnitude

							if totalDistance > dist then
								local steps = math.ceil(totalDistance / dist)
								local unitDirection = diff.Unit

								for i = 1, steps do
									local remainingDist = (targetPos - current).Magnitude
									local stepDistance = math.min(dist, remainingDist)
									current = current + (unitDirection * stepDistance)
									library.char.HumanoidRootPart.CFrame = CFrame.new(current) * library.char.HumanoidRootPart.CFrame.Rotation
									--if i > 1 then 
									--	library:shift_tickbase() 
									--end
									library.send_network_packet("repupdate", current, Vector3.zero, Vector3.zero, modules.GameClock.getTime())
									if tickbase.charge <= 0 then break end
									library:shift_tickbase()
								end
							else
								current = targetPos
								library.char.HumanoidRootPart.CFrame = CFrame.new(current) * library.char.HumanoidRootPart.CFrame.Rotation
								library.send_network_packet("repupdate", current, Vector3.zero, Vector3.zero, modules.GameClock.getTime())
							end
							table.remove(path, 1)
							task.wait()
						end
						task.wait()
					end)
					if not success then break end
				until tickbase.charge <= 0 or (current - target).Magnitude <= 1 or #path == 0
				playerData.forcePos = nil
				library.ignorePosEvents = false
				tickbase.charge_delay = 5.0
				isDone = true

				for _, path in pathPoints do
					tween_service:Create(path, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						Size = Vector3.zero
					}):Play()
					task.wait()
				end

				task.delay(1.0, function()
					for _, path in pathPoints do
						path:Destroy()
					end
				end)
			else
				createNotification({ text = "Failed to find a valid path!", time = 1 / 2 })
				isDone = true
			end
		else
			createNotification({ text = "Error while pathfinding!", time = 1 / 2 })
			isDone = true
		end
		repeat task.wait() until isDone
	end

	function library:shift_full()
		tickbase.is_releasing = true
		tickbase.is_charging = false
		tickbase.charge = 0
		tickbase.charge_delay = clamp(tickbase.max_shift * 2, 0, 0.5)
	end
	function library:get_tickbase()
		return tickbase.charge or 0
	end
	function library:shift_tickbase()
		tickbase.charge_delay = clamp(tickbase.max_shift * 2, 0, 0.5)
		if tickbase.charge >= 0 then
			tickbase.charge -= library.tickTime
		end
		tickbase.charge = clamp(tickbase.charge, 0, 5)
	end

	local stances = {"prone", "crouch", "stand"}
	library.desyncs = {
		["stiff"] = function()
			local perc = floor(elapsedDuck) % 14
			local stance = perc % 6 <= 4 and "stand" or "prone"
			stance = perc >= 10 and (perc > 12 and "prone" or "crouch") or "stand"
			sendData('stance', stance)
			sendData('sprint', perc % 11 == 0)
			local charObject = charInterface.getCharacterObject()
			if not charObject then return end
			library.fakeMoveMode = (stance)
			library.fakeSprint = perc % 11 == 0
		end,
		["full"] = function()
			local perc = floor(elapsedDuck) % 14
			local stance = perc % 6 <= 4 and "stand" or "prone"
			--stance = perc >= 10 and (perc > 12 and "prone" or "crouch") or "stand"
			sendData('stance', stance)
			sendData('sprint', perc % 3 == 0)
			local charObject = charInterface.getCharacterObject()
			if not charObject then return end
			library.fakeMoveMode = (stance)
			library.fakeSprint = perc % 3 == 0
		end,
		["jitter"] = function()
			local stance = stances[math.random(1,#stances)]
			local sprint = math.random() > .5
			sendData('stance', stance)
			sendData('sprint', sprint)
			local charObject = charInterface.getCharacterObject()
			if not charObject then return end
			library.fakeMoveMode = (stance)
			library.fakeSprint = sprint
		end,
	}
	cons[#cons + 1] = run.Heartbeat:Connect(function(dt)

		
		library.char = workspace:FindFirstChild("Ignore"):FindFirstChildOfClass("Model")
		local canShift = library.char ~= nil
		if tickbase.charge_delay and tickbase.charge_delay > 0 then
			tickbase.charge_delay -= dt
			tickbase.is_shifting = false
			tickbase.is_charging = false
			canShift = false
		end
		library.tickTime = oldGetTime() - tickbase.last_time
		if tickbase.is_charging and tickbase.charge <= tickbase.max_shift and canShift then
			tickbase.charge = tickbase.max_shift
			--if library.char then library.char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero library.char.HumanoidRootPart.CFrame = tickbase.old_cf end
		elseif tickbase.is_charging then
			tickbase.is_charging = false
		elseif tickbase.is_releasing then
			tickbase.is_releasing = false
			tickbase.charge = 0
		end
		tickbase.old_cf = (library.char and library.char:FindFirstChild("HumanoidRootPart")) and library.char.HumanoidRootPart.CFrame or cf()

		if tickbase.charge > 0 and not tickbase_manip.active then
			library:shift_tickbase()
			tickbase.charge_delay = 0
		elseif (not tickbase.is_charging) and tickbase.charge <= 0 and tickbase_manip.active and canShift then
			tickbase.is_charging = true
		end
		tickbase.last_time = oldGetTime()
		drawBar("tickbase", tickbase.charge / tickbase.max_shift, tickbase.is_charging or tickbase.is_releasing or tickbase.charge > 0, rgb(), themes.preset.button_alt)
		if statedesync.active and sendData then
			elapsedDuck += 1
			library.desyncs[flags.statedesync_mode or "stand"]()
		elseif fakeduck.active and sendData then
			elapsedDuck += 1
			sendData('stance', "stand")
			sendData('stance', "prone")
			sendData('sprint', true)
			local charObject = charInterface.getCharacterObject()
			if not charObject then return end
			library.fakeMoveMode = ('prone')
			library.fakeSprint = true
		else
			library.fakeSprint = nil
			library.fakeMoveMode = nil
		end
		local active = aimbotToggle.active
		circle.Position = uis:GetMouseLocation()
		circle.Radius = math.lerp(circle.Radius, active and flags.pf_fov or 0, correctAlpha(0.75, dt))
		circle.Color = (flags.pf_fovcolor or {Color = rgb(255,255,255)}).Color
		circle.Transparency = math.lerp(circle.Transparency, flags.pf_infinitefov and 0 or 0.7 * (flags.pf_fovcolor and flags.pf_fovcolor.Transparency or 1), correctAlpha(0.25, dt))
		circle.Visible = not flags.ignorefov
		if flags.pf_aimbotmode == "normal" and flags.pf_deadzone then
			dead_circle.Position = uis:GetMouseLocation()
			dead_circle.Radius = math.lerp(dead_circle.Radius, active and flags.pf_deadzone_fov or 0, correctAlpha(0.75, dt))
			dead_circle.Color = flags.pf_fovcolor.Color
			dead_circle.Transparency = math.lerp(dead_circle.Transparency, flags.pf_infinitefov and 0 or 0.7 * (flags.pf_fovcolor.Transparency), correctAlpha(0.25, dt))
			dead_circle.Visible = not flags.ignorefov
		else
			dead_circle.Visible = false
		end
		liner.Color, liner.Transparency = circle.Color, circle.Transparency
		dbgT.Text = ""
		dbgT.Color = themes.preset.button:lerp(rgb(255,255,255),0.5-0.25*cos(elapsed_ticks/20))
		if not active then return end

		table.sort(flags.pf_hitbox, function(a, b)
			return priority[a] < priority[b]
		end)
		updateAimbot()


		if not targetPart then return end
	end)
end
end)
task.wait()
--[[
section:toggle({name = "enabled", flag = "toggle_flag"})
section:keybind({name = "aim key"})
section:toggle({name = "silent", flag = "toggle_flag"})
section:slider({name = "smooth", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})

section2:slider({name = "fov", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})
section2:slider({name = "max distance", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})
section2:toggle({name = "target npcs", flag = "toggle_flag"})
section2:dropdown({name = "hitbox", flag = "distance_priority", items = {"head","chest","legs"}, default = "head"})
section2:slider({name = "hs after x shots", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})

local column = rage:column({})
local section = column:section({name = "weapon modifications"})
local section2 = column:section({name = "other"})
section:toggle({name = "no-spread", flag = "toggle_flag"})
section:slider({name = "recoil multiplier", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})
section:slider({name = "bullet thickness", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})
section:slider({name = "bullet speed", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})

local column = rage:column({})
local section = column:section({name = "weapon modifications"})
local section2 = column:section({name = "other"})
section:toggle({name = "no-spread", flag = "toggle_flag"})
section:slider({name = "recoil multiplier", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})
section:slider({name = "bullet thickness", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})
section:slider({name = "bullet speed", min = 0, max = 10, default = 10, interval = 0.1, suffix = "", flag = "abc"})
]]
local visuals = window:tab({name = "visuals"})
local column = visuals:column({})
local column2 = visuals:column({})

local editor = column:section({name = "selection", autofill = true}):list({
	name = "view",
	flag = "editor_list",
	size = 80,
	items = {
		"players",
		"self",
		"world",
		"misc"
	},
})
local left_column = column
column = column2
local section = column:section({name = "chams", size = 0.3})
depend(section, function()
	return flags.editor_list == "players"
end)
local self_secondary
section:toggle({name = "enabled", flag = "enemy_chams", tip = "Toggles the enemy chams"})
section:toggle({name = "animation", flag = "enemy_animated", callback = function()
	if not self_secondary then return end
	self_secondary.show_element(flags.enemy_animated)
end,})
section:toggle({name = "enemy only", flag = "enemy_only"})
section:dropdown({
	name = "style",
	flag = "chams_enemy_material",
	items = {"breathe", "normal", "inverted", "occluded"},
	multi = false,
	scrolling = true,
	callback = function()
		chamsContainer:ClearAllChildren()
		holder:ClearAllChildren()
		viewport:ClearAllChildren()
	end
})
section:colorpicker({name = "primary color", flag = "enemy_primary_color", color = themes.preset.button, alpha = 0})
self_secondary = section:colorpicker({name = "secondary color", flag = "enemy_secondary_color", color = themes.preset.button_alt, alpha = 0})
self_secondary.show_element(flags.enemy_animated)
local section = column:section({name = "bullet tracers", size = 0.3})
depend(section, function()
	return flags.editor_list == "world"
end)
section:toggle({name = "enabled", flag = "bullet_tracers"})
section:toggle({name = "impacts", flag = "impacts"})
section:colorpicker({name = "color", flag = "bullet_tracer_color", color = color(1,0,0), alpha = 0})
section:slider({name = "thickness", min = 0.01, max = 1, default = 0.03, interval = 0.01, suffix = "", flag = "bullet_tracer_thickness"})
section:dropdown({
	name = "style",
	flag = "bullet_tracer_style",
	items = {"line", "smooth", "spiral", "lightning", "lightning2"},
	multi = false,
	scrolling = true
})
task.spawn(function()
	local fog = column:section({name = "fog", size = 0.3})
	depend(fog, function()
		return flags.editor_list == "world"
	end)
	local saved = {FogColor = lighting.FogColor, FogEnd = lighting.FogEnd, FogStart = lighting.FogStart, ColorShift_Top = lighting.ColorShift_Top, ColorShift_Bottom = lighting.ColorShift_Bottom}
	local baseSignals = {}
	local atmosphere = Instance.new("Atmosphere")
	fog:dropdown({
		name = "type",
		flag = "fog_tab",
		items = {"fog", "atmosphere"},
		multi = false,
		scrolling = true,
		default = "atmosphere"
	})
	local collected_atmospheres = {}
	fog:toggle({name = "enabled", flag = "atmosphere_enabled", callback = function(t)
		task.spawn(function()
			if not t then
				for _, signal in baseSignals do signal:Disconnect() end
				for _, atmosphere in collected_atmospheres do
					pcall(function() atmosphere.Parent = lighting end)
				end
				table.clear(baseSignals)
				atmosphere.Parent = nil
				for i, v in saved do
					lighting[i] = v
				end
			else
				saved = {FogColor = lighting.FogColor, FogEnd = lighting.FogEnd, FogStart = lighting.FogStart, ColorShift_Top = lighting.ColorShift_Top, ColorShift_Bottom = lighting.ColorShift_Bottom}
				baseSignals[#baseSignals + 1] = run.Heartbeat:Connect(function()
					if flags.fog_tab == "atmosphere" then 
						atmosphere.Parent = nil
						atmosphere.Parent = lighting
					else
						atmosphere.Parent = nil
						for _, atmosphere in lighting:GetChildren() do
							if atmosphere:IsA("Atmosphere") then
								table.insert(collected_atmospheres, atmosphere)
								atmosphere.Parent = nil
							end
						end
						local newList = {}
						for name in saved do
							newList[name] = flags["fog_" .. name:lower()]
							if typeof(newList[name]) == "table" then newList[name] = newList[name].Color end
						end
						for entryName, property in newList do
							lighting[entryName] = property
						end
					end
				end)
			end
		end)
	end})
	for entryName, property in saved do
		local entry
		if typeof(property) == "Color3" then
			entry = fog:colorpicker({name = entryName:lower():gsub("_", " "), flag = "fog_" .. entryName:lower(), color = property, alpha = 0, callback = function()
				lighting[entryName] = flags["fog_" .. entryName:lower()].Color
			end})
		else
			entry = fog:slider({name = entryName:lower():gsub("_", " "), min = 0, max = 10000, default = property, interval = 1, suffix = "", flag = "fog_" .. entryName:lower(), callback = function()
				lighting[entryName] = flags["fog_" .. entryName:lower()]
			end})
		end
		if entry ~= nil then
			depend(entry, function()
				return flags.fog_tab == "fog"
			end)
		end
	end
	depend(fog:slider({name = "offset", min = 0, max = 1, default = 0, interval = 1e-2, suffix = "", flag = "fog_offset", callback = function()
		atmosphere.Offset = flags.fog_offset
	end}), function()
		return flags.fog_tab == "atmosphere"
	end)
	depend(fog:slider({name = "density", min = 0, max = 1, default = 0.395, interval = 1e-2, suffix = "", flag = "fog_density", callback = function()
		atmosphere.Density = flags.fog_density
	end}), function()
		return flags.fog_tab == "atmosphere"
	end)
	depend(fog:colorpicker({name = "color", flag = "fog_color", color = rgb(199, 170, 107), alpha = 0, callback = function()
		atmosphere.Color = flags.fog_color.Color
	end}), function()
		return flags.fog_tab == "atmosphere"
	end)
	depend(fog:colorpicker({name = "decay", flag = "fog_decay", color = rgb(92, 60, 13), alpha = 0, callback = function()
		atmosphere.Decay = flags.fog_decay.Color	
	end}), function()
		return flags.fog_tab == "atmosphere"
	end)
	depend(fog:slider({name = "glare", min = 0, max = 1, default = 0, interval = 1e-2, suffix = "", flag = "fog_glare", callback = function()
		atmosphere.Glare = flags.fog_glare
	end}), function()
		return flags.fog_tab == "atmosphere"
	end)
	depend(fog:slider({name = "haze", min = 0, max = 1, default = 0, interval = 1e-2, suffix = "", flag = "fog_haze", callback = function()
		atmosphere.Haze = flags.fog_haze
	end}), function()
		return flags.fog_tab == "atmosphere"
	end)
end)
local section = left_column:section({name = "environment", size = 0.3})
section:toggle({name = "color grading", flag = "colorgrading"})
local time_of_day = section:toggle({name = "time of day", flag = "time_of_day_enabled", popout = true})
time_of_day:add(section:slider({name = "time", min = 0, max = 24, default = 12, interval = 0.01, suffix = "", flag = "time_of_day_time"}))

depend(section, function()
	return flags.editor_list == "world"
end)
library.camera = section:label({name = "camera", popout = true})
library.camera:add(section:toggle({name = "no sway", flag = "pf_nosway"}))
library.camera:add(section:toggle({name = "no camera sway", flag = "pf_nocamerasway"}))
do
	library.camera:add(section:slider({name = "aspect ratio", min = 70, max = 120, default = 100, interval = 1, suffix = "%", flag = "stretch", wip = game.GameId == 113491250}))
	globalStretch = {R00 = 1, R01 = 0, R02 = 0, R10 = 0, R11 = 1, R12 = 0, R20 = 0, R21 = 0, R22 = 1}
	if game.GameId ~= 113491250 then
		run.RenderStepped:Connect(function()
			local stretch = flags.stretch / 100
			if stretch ~= 1 then return end
			local c = camera.CFrame

			local x, y, z,
			R00, R01, R02,
			R10, R11, R12,
			R20, R21, R22 = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

			if flags.awesomestuff then
				stretch = 1 + .1 * math.cos(elapsed_ticks / 10)
			end

			R00 = stretch
			R11 = 1 - (stretch - 1) / 2
			R22 = 1

			globalStretch.R00, globalStretch.R11 = R00, R11

			camera.CFrame *= CFrame.new(
				x, y, z,
				R00, R01, R02,
				R10, R11, R12,
				R20, R21, R22
			)

		end)
	else
		--[[local active
		function connectCamera()
			camera:GetPropertyChangedSignal("CFrame"):Connect(function()
				if active then return end
				active = true
				local stretch = flags.stretch / 100
				local c = camera.CFrame

				local x, y, z,
				R00, R01, R02,
				R10, R11, R12,
				R20, R21, R22 = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

				if flags.awesomestuff then
					stretch = 1 + .1 * math.cos(elapsed_ticks / 10)
				end

				R00 = stretch
				R11 = 1 - (stretch - 1) / 2
				R22 = 1

				globalStretch.R00, globalStretch.R11 = 1, 1

				camera.CFrame *= CFrame.new(
					x, y, z,
					R00, R01, R02,
					R10, R11, R12,
					R20, R21, R22
				)

				warn("hii")

				active = false
			end)
		end

		--connectCamera()
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			camera = workspace.CurrentCamera
			--connectCamera()
		end)

		for i = -15, 15, 1 do
			run:BindToRenderStep("camera_____00000", Enum.RenderPriority.Camera.Value + i, (function()
				local stretch = flags.stretch / 100
				local c = camera.CFrame

				local x, y, z,
				R00, R01, R02,
				R10, R11, R12,
				R20, R21, R22 = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

				if flags.awesomestuff then
					stretch = 1 + .1 * math.cos(elapsed_ticks / 10)
				end

				R00 = stretch
				R11 = 1 - (stretch - 1) / 2
				R22 = 1

				globalStretch.R00, globalStretch.R11 = 1, 1

				camera.CFrame *= CFrame.new(
					x, y, z,
					R00, R01, R02,
					R10, R11, R12,
					R20, R21, R22
				)

			end))
		end]]
		local function applyAspectRatio(v)
			local ratioy = 1
			local ratiox = flags.stretch / 100

			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()

			r01, r11, r21 = r01 * ratioy, r11 * ratioy, r21 * ratioy
			r00, r10, r20 = r00 * ratiox, r10 * ratiox, r20 * ratiox

			return CFrame.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22) * (library.thirdPerson and CFrame.new(0,flags.thirdpersonDistance/32,flags.thirdpersonDistance) or cf())
		end
		local function isCameraCFrame(self, k)
			return self == camera and k == "CFrame"
		end
		local oldNewindex; oldNewindex = hookfunction(getrawmetatable(camera).__newindex, newcclosure(function(self, k, v)
			if isCameraCFrame(self, k) then
				v = applyAspectRatio(v)
			end
			return oldNewindex(self, k, v)
		end))
	end
	local applying = false



end
section:dropdown({
	name = "skybox",
	flag = "world_skybox",
	items = (function()
		local items = {"off"}
		for name in skyboxes do
			items[#items + 1] = name
		end
		return items
	end)(),
	default = 'off',
	multi = false,
	scrolling = true,
})
--[[
section:toggle({name = "disable effects", flag = "world_noeffects"})
]]

local cache = {}
section:dropdown({
	name = "nightmode",
	flag = "world_nightmode",
	items = {"off", "fullbright", "nightmode"},
	multi = false,
	scrolling = true,
	callback = function()
		if flags.world_nightmode == 'nightmode' then
			for _,v in workspace:GetDescendants() do
				if v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
					if not v:GetAttribute("seraphBrightness") then
						v:SetAttribute("seraphBrightness", v.Brightness)
					end
					v.Brightness = v:GetAttribute("seraphBrightness") * .1
				end
			end
		elseif flags.world_nightmode == 'fullbright' then
			for _,v in workspace:GetDescendants() do
				if v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
					if not v:GetAttribute("seraphBrightness") then
						v:SetAttribute("seraphBrightness", v.Brightness)
					end
					v.Brightness = v:GetAttribute("seraphBrightness") * .6
				end
			end
		else
			for _,v in workspace:GetDescendants() do
				if v:IsA("PointLight") or v:IsA("SurfaceLight") or v:IsA("SpotLight") then
					if not v:GetAttribute("seraphBrightness") then
						v:SetAttribute("seraphBrightness", v.Brightness)
					end
					v.Brightness = v:GetAttribute("seraphBrightness")
				end
			end
		end
	end,
})
workspace.DescendantAdded:Connect(function(v)
	if flags.world_nightmode == "off" then return end
	if not v:IsA("PointLight") or not v:IsA("SurfaceLight") or not v:IsA("SpotLight") then return end
	if not v:GetAttribute("seraphBrightness") then
		v:SetAttribute("seraphBrightness", v.Brightness)
	end
	v.Brightness = v:GetAttribute("seraphBrightness") * .3
end)
--[[
section:dropdown({
	name = "particles",
	flag = "world_particles",
	items = {"off", "ash", "snow"},
	multi = false,
	scrolling = true
})
]]
section:colorpicker({name = "color correction", flag = "world_color_correction", color = color(1,1,1), alpha = 0})
local bloom = Instance.new("BloomEffect")
bloom.Parent = lighting
section:slider({name = "bloom scale", min = 1, max = 1000, default = 1, interval = 1, suffix = "", flag = "bloomscale", callback = function()
	local t = flags.bloomscale / 1000
	local curve = t ^ 2.2
	bloom.Intensity = curve * 2.5
	bloom.Size      = 12 + curve * 48 
	bloom.Threshold = 1.2 - curve * 0.8
	bloom.Enabled = curve > 0.01
end})
local elements = column2:section({name = "elements", size = 0.3})
depend(elements, function()
	return flags.editor_list == "misc"
end)
elements:toggle({name = "autosave notification", flag = "autosave_notification", default = true})
elements:toggle({name = "notification sound", flag = "notifSound", default = true})
elements:toggle({name = "linked discord profile", flag = "linked_discord_profile", default = true})
elements:toggle({name = "watermark", flag = "watermark", default = true})
elements:dropdown({
	name = "watermark style",
	flag = "watermark_style",
	items = {"corner", "classic"},
	multi = false,
	scrolling = true
})
elements:dropdown({
	name = "options",
	flag = "watermark_options",
	items = {"ping", "fps", "time", "username", "uid"},
	multi = true,
	scrolling = true
})
elements:toggle({name = "spinning logo", flag = "spinning_logo"})
elements:slider({name = "spinning logo size", min = 1, max = 1000, default = 100, interval = 1, suffix = "", flag = "logosize"})
elements:dropdown({
	name = "keybinds",
	flag = "keybinds_type",
	items = {"off", "crosshair", "widget"},
	multi = false,
	scrolling = true
})
local section = left_column:section({name = "viewmodel", size = 0.3})
depend(section, function()
	return flags.editor_list == "self"
end)
local self_secondary
section:toggle({name = "enabled", flag = "viewmodel"})
local isHand = function(v)
		return v:FindFirstChild("SkinTone") or v:FindFirstChild("Hand")
	end
section:toggle({name = "ignore hands", flag = "viewmodel_ignore_hands", tip = "This might not work in alot of games!"})
section:toggle({name = "enable color", flag = "viewmodel_color_enabled"})
section:colorpicker({name = "color", flag = "viewmodel_color", color = themes.preset.button, alpha = 0})
section:toggle({name = "glow", flag = "highlight_viewmodel"})
section:toggle({name = "no sleeves", flag = "viewmodel_nosleeves"})
section:toggle({name = "disable scope", flag = "viewmodel_noscope", tip = "Disables the scope overlay on sniper rifles"})
local forcefieldanimations = {
	["off"] = "",
	["honeycomb"] = "rbxassetid://6044275872",
	["cubes"] = "rbxassetid://6048826473",
	["4d"] = "rbxassetid://4504367541",
	["antimatter"] = "rbxassetid://4494641460",
	["fractal"] = "rbxassetid://1478668577",
	["mayhem"] = "rbxassetid://459487304",
	["lightning"] = "rbxassetid://123111500",
	["square"] = "rbxassetid://15414656170",
	["padding"] = "rbxassetid://15414630817",
	["fading cubed"] = "rbxassetid://15414630817",
	["circut"] = "rbxassetid://9292587287",
	["boolean"] = 'rbxassetid://15414274468',
	["striped"] = "rbxassetid://6020569806",
	["fizzle"] = "rbxassetid://5118353630",
	["glow stripes"] = "rbxassetid://159836520",
	["akari"] = "rbxassetid://72309889",
	["hexagon"] = "rbxassetid://5819736338",
	["concentric"] = "rbxassetid://3898585495",
	["plasma"] = "rbxassetid://269282404",
	["matrix"] = "rbxassetid://10713189068",
	["swirl"] = "rbxassetid://3147585701",
	["scanning"] = "rbxassetid://5843010904",
	["smudge"] = "rbxassetid://6096634060",
	--[[["web"] = "rbxassetid://301464986",
	["webbed"] = "rbxassetid://2179243880",
	["scanning"] = "rbxassetid://5843010904",
	["pixelated"] = "rbxassetid://140652787",
	["swirl"] = "rbxassetid://8133639623",
	["checkerboard"] = "rbxassetid://5790215150",
	["christmas"] = "rbxassetid://6853532738",
	["player"] = "rbxassetid://4494641460",
	["shield"] = "rbxassetid://361073795",
	["dots"] = "rbxassetid://5830615971",
	["bubbles"] = "rbxassetid://1461576423",
	["matrix"] = "rbxassetid://10713189068",
	["honeycomb"] = "rbxassetid://179898251",
	["groove"] = "rbxassetid://10785404176",
	["cloud"] = "rbxassetid://5176277457",
	["sky"] = "rbxassetid://1494603972",
	["smudge"] = "rbxassetid://6096634060",
	["scrapes"] = "rbxassetid://6248583558",
	["galaxy"] = "rbxassetid://1120738433",
	["galaxies"] = "rbxassetid://5101923607",
	["stars"] = "rbxassetid://598201818",
	["rainbow"] = "rbxassetid://10037165803",
	["wires"] = "rbxassetid://14127933",
	["camo"] = "rbxassetid://3280937154",
	["hexagon"] = "rbxassetid://6175083785",
	["particles"] = "rbxassetid://1133822388",
	["triangular"] = "rbxassetid://4504368932",
	["wall"] = "rbxassetid://4271279"]]
}
section:dropdown({
	name = "forcefield animation",
	flag = "viewmodel_neon_animation",
	items = (function()
		local animationList = {}

		for animation, _ in forcefieldanimations do
			insert(animationList, animation)
		end

		return animationList
	end)(),
	default = "off",
	multi = false,
	scrolling = true
})
section:dropdown({
	name = "material",
	flag = "viewmodel_material",
	items = (function()
		local materialList = {}

		for _, material in Enum.Material:GetEnumItems() do
			insert(materialList, material.Name)
		end

		return materialList
	end)(),
	default = "Glass",
	multi = false,
	scrolling = true
})
section:dropdown({
	name = "mode",
	flag = "viewmodel_mode",
	items = {"normal", "pulse"},
	default = "normal",
	multi = false,
	scrolling = true
})
function handle_viewmodel_transparency(transparency, mode, dt)
	if mode == "pulse" then
		transparency = math.clamp(math.sin(elapsed_ticks / 10) * transparency, 0, 1)
	end
	return transparency
end

local cachedHighlight = {}
for i = 1, 25 do
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0.5
	highlight.Parent = nil
	cachedHighlight[i] = highlight
end

function getCachedHighlight()
	for i, highlight in cachedHighlight do
		if not highlight.Parent or not highlight:IsDescendantOf(game) or not highlight.Adornee or not highlight.Adornee:IsDescendantOf(game) then
			if not pcall(function() highlight.Parent = coregui end) then
				pcall(game.Destroy, highlight)
				highlight = Instance.new("Highlight")
				cachedHighlight[i] = highlight
			end
			return highlight
		end
	end
	return nil
end

local whitelist = {"SkinTone","Arm"}
function handleViewmodelPart(v, dt)
	if v.Parent:FindFirstChild(whitelist[1]) and not table.find(whitelist, v.Name) then
		v.Transparency = 1
		return
	end
	local vm_mode = flags.viewmodel_mode
	if not v:GetAttribute("Material") then
		v:SetAttribute("Material", v.Material.Name)
		v:SetAttribute("Color", v.Color)
		v:SetAttribute("Transparency", v.Transparency)
		pcall(function()
			v:SetAttribute("TextureID", v.TextureID)
		end)
	end
	v.Material = Enum.Material[upperString(flags.viewmodel_material)] 
	if flags.viewmodel_color_enabled then
		v.Color = flags.viewmodel_color.Color
	else
		v.Color = v:GetAttribute("Color")
	end
	pcall(setproperty, v, "TextureID", "")
	v.Transparency = library.thirdPerson and 0.9999 or handle_viewmodel_transparency(1 - flags.viewmodel_color.Transparency, vm_mode, dt)
	if v.Material == Enum.Material.ForceField and v:IsA("MeshPart") then
		v.TextureID = forcefieldanimations[flags.viewmodel_neon_animation] or "rbxassetid://0"
	end
	--[[if (v.Name:match("Sleeve")) then 
		v.Transparency = 1 
	end]]
	v:SetAttribute("lol", true)
end

function updateToolViewmodel(v, dt)
	if v:IsA("SpecialMesh") then
		if flags.viewmodel then
			if not v:GetAttribute("VertexColor") then
				v:SetAttribute("VertexColor", v.VertexColor)
				v:SetAttribute("TextureId", v.TextureId)
			end
			v.VertexColor = flags.viewmodel_color_enabled and Vector3.new(flags.viewmodel_color.Color.R / 255, flags.viewmodel_color.Color.G / 255, flags.viewmodel_color.Color.B / 255) or v:GetAttribute("VertexColor")
			v.TextureId = ""
		else
			if v:GetAttribute("VertexColor") then
				v.VertexColor = v:GetAttribute("VertexColor")
				v.TextureId = v:GetAttribute("TextureId")
				v:SetAttribute("VertexColor", nil)
				v:SetAttribute("TextureId", nil)
			end
		end
	end
	if not v:IsA("BasePart") then 
		return
	end
	if (v.Transparency == 1 and not v:GetAttribute("lol")) or v.Name == "ChamsInstance" then
		return
	end
	if flags.viewmodel then
		handleViewmodelPart(v, dt)
	else
		if v:GetAttribute("Material") then
			v.Material = Enum.Material[v:GetAttribute("Material")]
			v.Color = v:GetAttribute("Color")
			v.Transparency = v:GetAttribute("Transparency")
			pcall(function() v.TextureID = v:GetAttribute("TextureID") end)
			if v:FindFirstChild("ChamsInstance") then
				v.ChamsInstance:Destroy()
			end
			v:SetAttribute("Material", nil)
			v:SetAttribute("Color", nil)
			v:SetAttribute("Transparency", nil)
			pcall(function()
				v:SetAttribute("TextureID", nil)
			end)
		end
	end
end

local function viewmodelTexture(v)
	if flags.viewmodel_color_enabled then
		if not v:GetAttribute("Color") then
			v:SetAttribute("Color", v.Color3)
		end
		v.Color3 = flags.viewmodel_color.Color
	else
		if v:GetAttribute("Color") then
			v.Color3 = v:GetAttribute("Color")
			v:SetAttribute("Color", nil)
		end
	end
	local tr
	pcall(function() tr = v.Parent.Transparency end)
	if v:IsA("Decal") then
		tr = 1
	end
	v.Transparency = library.thirdPerson and 0.9999 or tr or handle_viewmodel_transparency(1 - flags.viewmodel_color.Transparency, vm_mode, dt)
	v:SetAttribute("lol", true)
end

function viewmodelSetup(v)
	if v:IsA("Texture") or v:IsA("Decal") then
		return viewmodelTexture(v)
	end
	if not v:IsA("BasePart") then 
		return
	end
	if v:IsA("MeshPart") and v:FindFirstChildOfClass("Bone") then return end
	if (v.Transparency == 1 or v.Name == "ChamsInstance") then
		return
	end
	if (flags.viewmodel_ignore_hands and (isHand(v.Parent) or v.Name:match("Hand") or (v:IsA("MeshPart") and (v.MeshId == "rbxasset://fonts/leftarm.mesh" or v.MeshId == "rbxasset://fonts/rightarm.mesh")) or v.Name:match("Arm"))) then
		return
	end
	local model = v:FindFirstAncestorOfClass("Model")
	if model ~= nil and not chamsContainer:FindFirstChild(model.Name) and flags.highlight_viewmodel then
		local highlight = getCachedHighlight()
		highlight.Name = model.Name
		highlight.Parent = chamsContainer
		highlight.Adornee = model
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = flags.viewmodel_color.Color
		highlight.FillTransparency = 10
		highlight.OutlineTransparency = 0.999
		highlight.OutlineColor = Color3.new(1,1,1)
		highlight.FillColor = Color3.new(0,0,0)
	end
	pcall(function()
		v.UsePartColor = true
	end)
	if flags.viewmodel then
		handleViewmodelPart(v, dt)
	else
		if v:GetAttribute("Material") then
			v.Material = Enum.Material[v:GetAttribute("Material")]
			v.Color = v:GetAttribute("Color")
			v.Transparency = v:GetAttribute("Transparency")
			pcall(function() v.TextureID = v:GetAttribute("TextureID") end)
			if v:FindFirstChild("ChamsInstance") then
				v.ChamsInstance:Destroy()
			end
			v:SetAttribute("Material", nil)
			v:SetAttribute("Color", nil)
			v:SetAttribute("Transparency", nil)
			pcall(function()
				v:SetAttribute("TextureID", nil)
			end)
		end
	end
end

if (game.PlaceId == 17516596118) then
	cons[#cons + 1] = run.RenderStepped:Connect(function(dt)
		local ignore = workspace:FindFirstChild("IgnoreThese")
		if not ignore then return end
		local myArms = ignore:FindFirstChild("MyArms")
		if not myArms then return end
		for i, v in myArms:GetDescendants() do
			viewmodelSetup(v)
		end

	end)
else
	run:BindToRenderStep("??", Enum.RenderPriority.Last.Value, function(dt)
		if not flags.viewmodel then return end
		for i, v in camera:GetDescendants() do
			thread(viewmodelSetup, v)
		end

		local char = lp.Character
		if not char then return end
		local tool = char:FindFirstChildOfClass("Tool")

		if flags.viewmodel_tools and tool then
			for _,v in tool:GetDescendants() do
				thread(updateToolViewmodel, v, dt)
			end
		end
	end)
end

local section = column:section({name = "character model", size = 0.3})
depend(section, function()
	return flags.editor_list == "players"
end)
section:toggle({name = "enabled", flag = "character_chams"})
section:toggle({name = "hide attachments", flag = "hide_other_attachments"})
section:toggle({name = "only enemy", flag = "enemy_only_character"})
section:colorpicker({name = "color", flag = "character_chams_color", color = themes.preset.button, alpha = 0})
section:dropdown({
	name = "material",
	flag = "character_chams_material",
	items = {"neon", "flat", "forcefield"},
	multi = false,
	scrolling = true
})
depend(section:dropdown({
	name = "forcefield style",
	flag = "character_chams_forcefield_style",
	items = (function()
		local list = {}
		for style, _ in forcefieldanimations do
			table.insert(list, style)
		end
		return list
	end)(),
	default = "off",
	multi = false,
	scrolling = true
}), function() return flags.character_chams_material == "forcefield"  end)
local section = column:section({name = "character model", size = 0.3})
depend(section, function()
	return flags.editor_list == "self"
end)
section:toggle({name = "enabled", flag = "self_character_chams"})
section:toggle({name = "chinahat", flag = "chinahat", callback = function() library.gradientEvent:Fire() end})
depend(section:toggle({name = "rainbow", flag = "chinahat_rainbow", callback = function() library.gradientEvent:Fire() end}), function()
	return flags.chinahat
end)
depend(section:toggle({name = "render bottom", flag = "chinahat_bottom", callback = function() library.gradientEvent:Fire() end}), function()
	return flags.chinahat
end)
depend(section:colorpicker({name = "color", flag = "chinahat_color", color = themes.preset.button, alpha = 0, callback = function() library.gradientEvent:Fire() end}), function()
	return flags.chinahat
end)
section:toggle({name = "hide attachments", flag = "hide_local_attachments"})
section:toggle({name = "ignore weapon model", flag = "ignoreweapons"})
section:toggle({name = "alternate forcefield", flag = "altforcefield", default = true})
section:colorpicker({name = "color", flag = "self_character_chams_color", color = themes.preset.button, alpha = 0})
section:dropdown({
	name = "material",
	flag = "self_character_chams_material",
	items = {"neon", "flat", "forcefield"},
	multi = false,
	scrolling = true
})
depend(section:toggle({name = "hide body parts", flag = "self_character_chams_hide_body_parts", tip = "Removes your body parts and only shows the outline."}), function()
	return flags.self_character_chams_material == "forcefield"
end)
depend(section:dropdown({
	name = "forcefield style",
	flag = "self_character_chams_forcefield_style",
	items = (function()
		local list = {}
		for style, _ in forcefieldanimations do
			table.insert(list, style)
		end
		return list
	end)(),
	default = "off",
	multi = false,
	scrolling = true
}), function() return flags.self_character_chams_material == "forcefield"  end)
local shoot_effects = column:section({name = "shoot effects", size = 0.3})
shoot_effects:toggle({name = "enabled", flag = "shoot_effects"})
shoot_effects:colorpicker({name = "color", flag = "shoot_effects_color", color = themes.preset.button, alpha = 0})
shoot_effects:slider({name = "lifetime", min = 4, max = 12, default = 4, interval = 0.1, suffix = "s", flag = "shoot_effects_lifetime"})
depend(shoot_effects, function()
	return flags.editor_list == "world"
end)

local column = column2
local section = column:section({name = "chams", size = 0.3})
depend(section, function()
	return flags.editor_list == "self"
end)
local self_secondary


section:toggle({name = "enabled", flag = "self_chams"})
section:toggle({name = "animation", flag = "self_animated", callback = function()
	if not self_secondary then return end
	self_secondary.show_element(flags.self_animated)
end,})
section:dropdown({
	name = "style",
	flag = "chams_self_material",
	items = {"breathe", "normal", "inverted"},
	multi = false,
	scrolling = true
})
section:colorpicker({name = "primary color", flag = "self_primary_color", color = themes.preset.button, alpha = 0})
self_secondary = section:colorpicker({name = "secondary color", flag = "self_secondary_color", color = themes.preset.button_alt, alpha = 0})
self_secondary.show_element(flags.self_animated)


local section = left_column:section({name = "esp", size = 0.3})
depend(section, function()
	return flags.editor_list == "players"
end)
local function force_reset()
	for player, frame in esp_frames do
		frame:Destroy()
		esp_frames[player] = nil
	end
	table.clear(esp_frames)
end
library.esp_masterswitch = section:toggle({name = "enabled", flag = "masterswitch", callback = force_reset, popout = true})
library.esp_masterswitch:add(section:slider({name = "font size", min = 0.1, max = 1.5, default = 1, interval = 0.1, suffix = "", flag = "esp_font_size_multiplier", callback = force_reset}))
library.esp_masterswitch:add(section:toggle({name = "fast render", flag = "fastrender", tip = "THIS MAY CAUSE A LOT OF LAG! Fixes your ESP lagging behind your camera", callback = function()
	force_reset()
	if flags.fastrender then
		local db = false
		cameraEvent = camera:GetPropertyChangedSignal("CFrame"):Connect(function()
			if db then return end
			db = true
			thread(update_esp)
			db = false
		end)
	else
		if cameraEvent then cameraEvent:Disconnect() cameraEvent = nil end
	end
end}))

library.esp_masterswitch:add(section:toggle({name = "enemy only", flag = "onlyenemy", callback = force_reset}))
library.esp_masterswitch:add(section:toggle({name = "on self", flag = "localesp", callback = force_reset}))
--[[
local walkspeed_parent = movement:toggle({
		name = "walkspeed", 
		flag = "force_speed", 
		tip = "Speed exploit",
		popout = true -- This makes it a parent for sub-items
	})

    walkspeed_parent:add(movement:toggle({
		name = "improve control", 
		flag = "speed_control", 
		tip = "Improves player control"
	}))
    walkspeed_parent:add(movement:slider({
        name     = "speed value", 
        flag     = "speedvalue",
        min      = 16, 
        max      = 110, 
        default  = 16, 
        interval = 1, 
        suffix   = 'studs/s', 
        tip      = "Exploit speed value"
    }))
		]]

library.name = section:toggle({name = "username", flag = "esp_username", callback = force_reset, popout = true})
library.name:add(section:toggle({name = "prefer display name", flag = "prefer_display_name", callback = force_reset}))

library.distance = section:toggle({name = "distance", flag = "esp_distance", callback = force_reset, popout = true})
library.distance:add(section:toggle({name = "suffix", flag = "esp_suffix", callback = force_reset}))

library.oof_arrows = section:toggle({name = "oof arrows", flag = "oof_arrows", callback = force_reset, popout = true})
library.oof_arrows:add(section:slider({name = "size", min = 10, max = 100, default = 50, interval = 1, suffix = "px", flag = "oof_arrows_size", callback = force_reset}))
library.oof_arrows:add(section:slider({name = "offset", min = 64, max = 512, default = 128, interval = 1, suffix = "px", flag = "oof_arrows_offset", callback = force_reset}))
library.oof_arrows:add(section:toggle({name = "dynamic offset", flag = "oof_arrows_dynamic_offset", callback = force_reset}))
library.oof_arrows:add(section:colorpicker({name = "color", flag = "oof_arrows_color", color = themes.preset.button, alpha = 0, callback = force_reset}))

library.bounding_box = section:toggle({name = "bounding box", flag = "bounding_box", callback = force_reset, popout = true})
library.bounding_box:add(section:colorpicker({name = "primary", flag = "esp_primary", color = themes.preset.button, alpha = 0, callback = force_reset}))
library.bounding_box:add(section:colorpicker({name = "secondary", flag = "esp_secondary", color = themes.preset.button, alpha = 0, callback = force_reset}))
library.bounding_box:add(section:toggle({name = "filled", flag = "esp_filled", callback = force_reset}))
library.bounding_box:add(section:toggle({name = "gradient", flag = "esp_gradient", callback = force_reset}))
local gradient_rotation = section:slider({name = "gradient rotation", min = 0, max = 360, default = 0, interval = 5, suffix = "Â°", flag = "esp_gradient_rotation", callback = force_reset})
depend(gradient_rotation, function()
	return flags.esp_gradient
end)
library.bounding_box:add(gradient_rotation)
library.bounding_box:add(section:toggle({name = "cat", flag = "esp_cat", callback = force_reset}))

library.ammo_bar = section:toggle({name = "ammo bar", flag = "esp_ammobar", callback = force_reset, popout = true})
library.ammo_bar:add(section:colorpicker({name = "color", flag = "ammo_bar_color", color = themes.preset.button, alpha = 0, callback = force_reset}))

library.health_bar = section:toggle({name = "health bar", flag = "esp_healthbar", callback = force_reset, popout = true})
library.health_bar:add(section:toggle({name = "glow", flag = "health_bar_glow", callback = force_reset}))
library.health_bar:add(section:colorpicker({name = "max health", flag = "maxhealth", color = themes.preset.button_alt, alpha = 0, callback = force_reset}))
library.health_bar:add(section:colorpicker({name = "min health", flag = "minhealth", color = themes.preset.button_alt:Lerp(rgb(), 0.5), alpha = 0, callback = force_reset}))
library.health_bar:add(section:slider({name = "width", min = 15, max = 85, default = 35, interval = 1, suffix = "px", flag = "health_bar_width", callback = force_reset}))
--[[
section:dropdown({
	name = "elements",
	flag = "featureflags",
	items =  {"distance", "health", "heath glow", "health %", "team", "username", "background", "box", "box gradient", "cat"},
	multi = true,
	scrolling = true,
	callback = force_reset
})

local maxhealthcolor = section:colorpicker({name = "max health", flag = "maxhealth", color = themes.preset.button_alt, alpha = 0, callback = force_reset})
local minhealthcolor = section:colorpicker({name = "min health", flag = "minhealth", color = themes.preset.button_alt:Lerp(rgb(), 0.5), alpha = 0, callback = force_reset})
depend(maxhealthcolor, function() return table.find(flags.featureflags, "health") end)
depend(minhealthcolor, function() return table.find(flags.featureflags, "health") end)
section:slider({name = "health bar width", min = 15, max = 85, default = 35, interval = 1, suffix = "px", flag = "health_bar_width", callback = force_reset})]]
--[[section:toggle({name = "master switch", flag = "masterswitch"})
section:toggle({name = "only visible", flag = "onlyvisible"})
section:dropdown({
	name = "include",
	flag = "includeflags",
	items =  game.GameId == 113491250 and {"items", "others"} or {"items", "npcs", "vehicles", "others"},
	multi = true,
	scrolling = true
})
section:colorpicker({name = "enemy color", flag = "enemy_color", color = themes.preset.button, alpha = 0})
section:colorpicker({name = "friend color", flag = "friend_color", color = Color3.fromHex("#00BFFF"), alpha = 0})
section:slider({name = "max distance", min = 1, max = 10000, default = 500, interval = 1, suffix = "u", flag = "maxdistance"})
section:dropdown({
	name = "bounding box",
	flag = "boundingbox",
	items = {"none", "quad", "corners", "3d"},
	multi = false,
	scrolling = true
})
section:toggle({name = "filled box", flag = "filledbox"})
section:toggle({name = "enemy only", flag = "onlyenemy"})
section:toggle({name = "team colors", flag = "teamcolors"})
depend(section:toggle({name = "ignore self", flag = "ignoreself"}), function() return not flags.onlyenemy end)
section:dropdown({
	name = "flags",
	flag = "espflags",
	items = game.GameId == 113491250 and {"name", "ping", "distance", "health", "gun"} or {"name", "ping", "distance", "health", "tool", "team", "velocity"},
	multi = true,
	scrolling = true
})
local maxhealthcolor = section:colorpicker({name = "max health", flag = "maxhealth", color = themes.preset.button_alt, alpha = 0})
local minhealthcolor = section:colorpicker({name = "min health", flag = "minhealth", color = themes.preset.button_alt:Lerp(rgb(), 0.5), alpha = 0})
depend(maxhealthcolor, function() return table.find(flags.espflags, "health") end)
depend(minhealthcolor, function() return table.find(flags.espflags, "health") end)
section:toggle({name = "lines", flag = "lines"})
section:toggle({name = "head dot", flag = "headdot", wip = true})
section:toggle({name = "skeleton", flag = "skeleton", wip = true})
section:toggle({name = "interpolation", flag = "interpolation", wip = true})
section:toggle({name = "king von", flag = "kingvon", wip = true})]]

do
	local players = window:tab({name = "players"})
	local column = players:column({})
	local column2 = players:column({})
	local section = column:section({name = "selection", size = 130})
	local list = section:list({name = "players", size = 130, items = {}, visible = true, flag = "player_list", callback = function()
		task.defer(update_title)
	end})

	refresh_players = function()
		local options = {}


		for idx, player in services.players:GetPlayers() do
			if player == lp then continue end
			if not player_list[player.Name] then
				player_list[player.Name] = {ignore_player = false}
			end
			options[ #options + 1 ] = player.Name
		end

		cfgs = options
		list.refresh_options(options)
	end
	task.defer(refresh_players)

	services.players.PlayerAdded:Connect(function()
		task.defer(refresh_players)
	end)
	services.players.PlayerRemoving:Connect(function()
		task.defer(refresh_players)
	end)
	local section = column2:section({name = "actions - none", size = 0.3})
	local saved_action_list = {}

	section:button({ name = "goto", unsafe = true, callback = function()
		local char = lp.Character
		if not char then return end
		local target = services.players:FindFirstChild(flags.player_list)
		if not target then return end
		local rootpart = char:FindFirstChild("HumanoidRootPart")
		if not rootpart then return end
		if not target.Character then return end
		rootpart.CFrame = target.Character:GetPivot()
	end})
	local ignore_toggle; ignore_toggle = section:toggle({ name = "ignore player", flag = "ignore_player", unsafe = true, callback = function()
		task.delay(0.1, function()
			local t = player_list[flags.player_list]
			if not t then
				pcall(function() ignore_toggle:set_value(false) end)
				return
			end
			t.ignore_player = flags.ignore_player
			createNotification({text = `set ignore for {flags.player_list} to {t.ignore_player}`})
		end)
	end })

	--print(ignore_toggle)
	task.delay(1, function()
		pcall(function() ignore_toggle:set_value(false) end)
	end)


	update_title = function()
		local t = player_list[flags.player_list]
		if not t then
			if flags.ignore_player then
				pcall(function() ignore_toggle:set_value(false) end)
			end
			section:set_title("actions - none")
			return
		end
		if flags.ignore_player ~= t.ignore_player then
			ignore_toggle:set_value(t.ignore_player)
		end
		---section:set_title(`actions - {flags.player_list or "none"}`)
	end

	task.delay(0.1, update_title)

end

local misc = window:tab({name = "misc"})

local lua = window:tab({name = "lua"})
local column = misc:column({})
local column2 = misc:column({})
local section = column:section({name = "other", size = 0.3})
library.thirdPersonContainer = section:label({name = "third person", popout = true})
local thirdPerson = section:keybind({name = "bind", flag = "thirdperson", unsafe = true, display = "thirdperson"})
library.thirdPersonContainer:add(thirdPerson)
library.thirdPersonContainer:add(section:slider({name = "distance", min = 1, max = 50, default = 12, interval = 1, suffix = "u", flag = "thirdpersonDistance"}))
library.thirdPersonContainer:add(section:toggle({name = "smoothing", flag = "smoothinterp"}))
library.thirdPersonContainer:add(section:toggle({name = "instant update", flag = "instantupdate"}))
library.fovContainer = section:label({name = "field of view", popout = true})
local forceFOV = section:keybind({name = "override fov", flag = "overridefov", unsafe = true, display = "override fov"})
library.fovContainer:add(forceFOV)
library.fovContainer:add(section:slider({name = "fov", min = 1, max = 200, default = 70, interval = 1, suffix = string.char(194,176), flag = "real_fov"}))
local zoomKey = section:keybind({name = "zoom", flag = "zoomkey", unsafe = true, display = "zoom"})
library.fovContainer:add(zoomKey)
library.fovContainer:add(section:slider({name = "zoom fov", min = 1, max = 200, default = 40, interval = 1, suffix = string.char(194,176), flag = "zoom_fov"}))
library.theme = section:label({name = "theme editor", popout = true})
local ui_scale = section:slider({name = "ui scale", min = 1, max = 200, default = 100, interval = 1, suffix = "u", flag = "menuscale", callback = function()
	local scale = flags.menuscale / 100
	library.gui_scale = scale
end})
library.theme:add(ui_scale)
library.theme:add(section:dropdown({name = "font", flag = "menufont", items = {"pixel", "alternate"}, multi = false, scrolling = true, callback = function()
	task.delay(1/30,function()
		for _, v in library.gui:GetDescendants() do
			if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
				if not v:GetAttribute("BaseFontSize") then v:SetAttribute("BaseFontSize", v.TextSize) end
				if flags.menufont == "pixel" then
					v.FontFace = fonts.ProggyClean
					v.TextSize = v:GetAttribute("BaseFontSize") * 1
				else
					v.FontFace = fonts.Tahoma
					v.TextSize = v:GetAttribute("BaseFontSize") * 1.2
				end
			end
		end
	end)
end}))
local theme_elements = {}

library.theme:add(section:colorpicker({name = "ui color", flag = "ui_color", color = themes.preset.button, alpha = 0, callback = function()
	themes.preset.button = flags.ui_color.Color
	themes.preset.button_alt = flags.ui_color.Color
	task.delay(1/5, function()
		build_str = (function(targetStr)
			local len, build = string.len(targetStr), ""

			for i = 1, len do
				build ..= `<font color="{rgbstr(themes.preset.button:lerp(themes.preset.button_alt, i/len))}">{targetStr:sub(i, i)}</font>`
			end

			return build
		end)(currentText)
		window:set_title(`seraph<font color="{rgbstr(themes.preset.button_alt)}">.wtf</font> {build_str} | {configName}`)
		for _, v in library.gui:GetDescendants() do
			if v:IsA("Frame") and v:GetAttribute("buttonPrimary") then
				v.BackgroundColor3 = flags.ui_color.Color
			elseif v:IsA("Frame") and v:GetAttribute("buttonAlt") then
				v.BackgroundColor3 = flags.ui_color.Color
			end
		end
		library.gradientEvent:Fire()
	end)
end}))
--113506071094099
local game_supports = table.find({113506071094099, 93853815957083}, game.PlaceId) ~= nil

section:button({ name = "rejoin", callback = function()
	services.teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
	writefile(library.directory .. "/configs/default.cfg", library:get_config())
end })
section:button({ name = "unload", callback = function()
	if getgenv().loaded then 
		getgenv().library:unload_menu() 
		for i,v in next, getgenv().connections do v:Disconnect() end
	end 

	getgenv().loaded = true 

end })

local section = column:section({name = "config", size = 0.3, on_click = function()
	refresh_configs()
end})
local list = section:list({name = "configs", size = 130, items = {}, visible = true, flag = "config_list"})
local cfgs = {}
local linking_api = (function()
    local HttpService = game:GetService("HttpService")
    local Workshop = {}

    -- Internal cache for usernames to avoid redundant requests
    local userCache = { [0] = "System" }

    local function safeToNumber(v)
        if type(v) == "number" then return v end
        if type(v) == "string" then
            local n = tonumber(v)
            if n then return n end
        end
        return nil
    end

    local function normalizeBoolLike(v)
        if v == true then return true end
        if v == false then return false end
        if type(v) == "number" and v ~= 0 then return true end
        if type(v) == "string" then
            local vl = v:lower()
            if vl == "true" or vl == "1" then return true end
            if vl == "false" or vl == "0" then return false end
        end
        return false
    end

    local function claimersContains(claimers, userId)
        if type(claimers) ~= "table" then return false end
        local uidS = tostring(userId)
        for _, v in ipairs(claimers) do
            if tostring(v) == uidS then return true end
        end
        return false
    end

    local function getUsername(baseUrl, userId)
        if not userId then return "System" end
        if userCache[userId] then return userCache[userId] end

        -- Try the username endpoint
        local ok, response = pcall(function()
            return request({
                Url = baseUrl .. "/api/username/" .. tostring(userId),
                Method = "GET"
            })
        end)

        if ok and response and (response.StatusCode == 200 or response.Success == true) and response.Body then
            local success, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if success and data and data.username then
                userCache[userId] = data.username
                return data.username
            end
        end

        return "ID: " .. tostring(userId)
    end

    function Workshop.fetchItems(baseUrl, token)
        local headers = { ["authentication"] = token }
        local allItems = {}

        local function populate(endpoint, category, isWorkshop)
            local ok, response = pcall(function()
                return request({
                    Url = baseUrl .. endpoint,
                    Method = "GET",
                    Headers = headers
                })
            end)

            if not ok or not response then
                warn("Failed HTTP request to " .. tostring(endpoint))
                return
            end

            if not (response.StatusCode == 200 or response.Success == true) then
                warn("Failed to fetch " .. tostring(category) .. " from " .. tostring(endpoint) .. " (status: " .. tostring(response.StatusCode) .. ")")
                return
            end

            local success, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if not success or not data then
                warn("Failed to decode JSON from " .. tostring(endpoint))
                return
            end

            local list = (isWorkshop and data.items) or data
            if type(list) ~= "table" then
                warn("Unexpected list type for " .. tostring(endpoint))
                return
            end

            for _, item in ipairs(list) do
                -- Normalize claim-related info
                local claimers = item.claimers or {}
                if type(claimers) ~= "table" then claimers = {} end

                -- Normalize claimed_by_me: server sets boolean but be tolerant
                local claimed_by_me = normalizeBoolLike(item.claimed_by_me)

                -- Fallback: if claimed_by_me false, double-check claimers array for any truthy match
                -- (this covers some edge cases where the server returns strings or numeric flags)
                if not claimed_by_me and #claimers > 0 then
                    -- We don't always have our own numeric userId in the client, so if the server already
                    -- computed claimed_by_me this is usually sufficient. This fallback checks whether the
                    -- owner_user_id is present among claimers (not ideal, but helps in some cases).
                    -- If you have a local numeric userId, replace `item.owner_user_id` below with it.
                    local found = false
                    for _, v in ipairs(claimers) do
                        if tostring(v) == tostring(item.owner_user_id) then
                            found = true
                            break
                        end
                    end
                    if found then claimed_by_me = true end
                end

                local downloadUrl = item.source_url or item.resolve_url
                local entry = {
                    id = item.id,
                    name = item.name,
                    type = category,
                    is_copy = item.is_copy or (item.copy_of ~= nil),
                    owner_id = item.owner_user_id,
                    owner_name = getUsername(baseUrl, item.owner_user_id),
                    source = nil,
                    claimers = claimers,
                    claimed_by_me = claimed_by_me,
                    is_owner = item.is_owner == true
                }

                -- Only fetch source if we have a valid URL
                if downloadUrl then
                    local ok2, srcRes = pcall(function()
                        return request({ Url = downloadUrl, Method = "GET", Headers = headers })
                    end)
                    if ok2 and srcRes then
                        local srcSuccess = (srcRes.Success == true) or (srcRes.StatusCode == 200)
                        if srcSuccess and srcRes.Body then
                            entry.source = srcRes.Body
                        end
                    end
                end

                table.insert(allItems, entry)
            end
        end
        populate("/api/my-cloud-luas", "lua", false)
        populate("/api/my-cloud-configs", "config", false)
		task.wait()
        return allItems
    end

    return Workshop
end)()

local mapped = { configs = {}, luas = {} }

refresh_configs = function()
	local options = {}

	for name, source in mapped.configs do
		options[ #options + 1 ] = name
	end

	for idx, file in listfiles(library.directory .. "/configs") do
		if not string.match(file :: string, '.cfg') then continue end
		options[ #options + 1 ] = string.gsub(string.gsub(string.gsub(file :: string, ".cfg", ''), 'configs\\', ''), 'seraph\\', '')
	end


	cfgs = options
	list.refresh_options(options)
end

section:textbox {
	name = "config",
	placeholder = "name",
	flag = "rawrconfig",
	visible = true
}

section:button({ name = "create", callback = function()
	writefile(library.directory .. `/configs/{flags.rawrconfig}.cfg`, library:get_config())
	configName = flags.rawrconfig

	task.defer(refresh_configs)
	createNotification({text = `changed config to {flags.rawrconfig}`})

	window:set_title(`seraph<font color="{rgbstr(themes.preset.button_alt)}">.wtf</font> {build_str} | {configName}`)
end })

section:button({ name = "save", callback = function()
	if not find(cfgs, flags.config_list) then
		return
	end
	if mapped.configs[configName] then
		createNotification({text = `cannot save cloud configs`})
		return
	end
	writefile(library.directory .. `/configs/{flags.config_list}.cfg`, library:get_config())
	createNotification({text = `saved config to {flags.config_list}`})

	window:set_title(`seraph<font color="{rgbstr(themes.preset.button_alt)}">.wtf</font> {build_str} | {configName}`)
end })
section:button({ name = "load", callback = function()
	if not find(cfgs, flags.config_list) then
		return
	end
	configName = flags.config_list
	if mapped.configs[configName] then
		library:load_config(mapped.configs[configName])
		return
	end
	pcall(function()
		local cfgdata = readfile(library.directory .. `/configs/{configName}.cfg`)
		if cfgdata and typeof(cfgdata) == 'string' then
			library:load_config(cfgdata)
		end
	end)
	createNotification({text = `loaded config {flags.config_list}`})
	window:set_title(`seraph<font color="{rgbstr(themes.preset.button_alt)}">.wtf</font> {build_str} | {configName}`)
end })

section:button({ name = "set default (universal)", callback = function()
	if not find(cfgs, flags.config_list) then
		return
	end
	writefile("seraph/configs/default.value", flags.config_list)
	createNotification({text = `set {flags.config_list} as universal default`})

	window:set_title(`seraph<font color="{rgbstr(themes.preset.button_alt)}">.wtf</font> {build_str} | {configName}`)
end })

section:button({ name = "set default (game)", callback = function()
	if not find(cfgs, flags.config_list) then
		return
	end
	writefile(`seraph/configs/{tostring(game.PlaceId)}.value`, flags.config_list)
	createNotification({text = `set {flags.config_list} as game default`})

	window:set_title(`seraph<font color="{rgbstr(themes.preset.button_alt)}">.wtf</font> {build_str} | {configName}`)
end })
section:button({ name = "reset to default", callback = function()
	flags = table.clone(library.empty_flags)
end })

section:button({ name = "refresh", callback = function()
	createNotification({text = "refreshing..."})
	refresh_configs()
end })

task.defer(refresh_configs)

local section = column2:section({name = "lua", size = 0.3, on_click = function()
	refresh_luas()
end})
local list = section:list({name = "lua scripts", size = 130, items = {}, visible = true, flag = "lua_scripts"})
local loaded_luas, luas = {}, {}


refresh_luas = function()
	local options = {}

	for name, source in mapped.luas do
		options[ #options + 1 ] = name
	end

	--for idx, file in listfiles(library.directory .. "/lua") do
	--	if not string.match(file :: string, '.lua') then continue end
	--	options[ #options + 1 ] = string.gsub(string.gsub(file :: string, ".lua", ''), 'priv9/', '')
	--end
	for idx, file in listfiles(library.directory .. "/lua") do
		if not string.match(file :: string, '.lua') then continue end
		options[ #options + 1 ] = string.gsub(string.gsub(string.gsub(file :: string, ".lua", ''), 'lua\\', ''), 'seraph\\', '')
	end

	luas = options
	list.refresh_options(options)
end

task.spawn(function()
	local linked_data = linking_api.fetchItems("https://seraph.wtf", _G.Product)

	for name, data in linked_data do
		local parentArray = mapped[data.type.. "s"]
		if parentArray and (data.claimed_by_me or data.owner_user_id == seraphAcc.uid) then
			local fullName = data.name
			if #fullName > 26 then fullName = string.sub(data.name, 1, 26).. "..." end
			mapped[data.type.. "s"][`* {fullName}`] = data.source
		end
	end
	task.defer(refresh_luas)
	task.defer(refresh_configs)
end)

local function start_lua(lua_name, should_load, is_workshop)
	local file = `{library.directory}/lua/{lua_name}.lua`

	if not should_load then
		local lua = loaded_luas[lua_name]
		if not lua then return end

		for _, rbxConnection in lua["connections"] do
			rbxConnection:Disconnect()
		end
		for _,instance in lua["elements"] do
			instance:destroy()
		end

		task.cancel(lua.thread)

		table.clear(lua)
		loaded_luas[lua_name] = nil

		return
	end



	local success, src 
	if not is_workshop then
		success, src = pcall(readfile, file)
	else
		success, src = pcall(function()
			local data = mapped.luas[lua_name]
			if not data then
				return error("FAILED TO FETCH DATA")
			end
			return data
		end)
	end

	if not success then
		createNotification({text = "failed to load lua"})
		return
	end

	local lua_instance = {
		connections = {},
		elements = {},
		thread = nil,
	}

	local lua_api = {
		seraph = {
			get = function() return library end,
		},
		ui = {
			column = function()
				local column = lua:column({})


				insert(lua_instance.elements, column)

				return column
			end,
			section = function(self, column, section)
				local section = column:section(section)

				insert(lua_instance.elements, section)

				return section
			end,
			child = function(self, section, childName, childData)
				local child = section[childName](section, childData)

				insert(lua_instance.elements, child)

				return child
			end,
			get = function(idx)
				return (typeof(idx) == 'string' and flags[idx] or flags[idx.flag])
			end,
		},
		notification = {
			create = function(self, data)
				createNotification(data)
			end,
		}
	}

	local loadfunc = loadstring(src, `[priv9::{lua_name}]`)
	local fenv = getfenv(loadfunc)

	for name, value in lua_api do
		fenv[name] = value
	end

	lua_instance.thread = task.spawn(loadfunc)

	loaded_luas[lua_name] = lua_instance
end

section:button({ name = "refresh", callback = refresh_luas })
section:button({ name = "load", callback = function()
	if not find(luas, flags.lua_scripts) then
		return
	end
	createNotification({text = "loading lua..."})
	start_lua(flags.lua_scripts, true, mapped.luas[flags.lua_scripts] ~= nil)

end })
section:button({ name = "unload", callback = function()
	if not find(luas, flags.lua_scripts) then
		return
	end
	start_lua(flags.lua_scripts, false, mapped.luas[flags.lua_scripts] ~= nil)
end })

if isfile('auto_load.json') and readfile('auto_load.json') then
	local file = http_service:JSONDecode(readfile("auto_load.json"))
	local luas = file.luas
	for _, name in luas do
		task.delay(1, start_lua, name, true, false)
	end
else
	writefile(
		'auto_load.json',
		http_service:JSONEncode({
			luas = {
				
			}
		})
	)
end

refresh_luas()

createNotification({text = "loaded seraph"})

-- inst
pcall(game.Destroy, workspace.CurrentCamera:FindFirstChild("colorcorrectionPriv"))
local colorcorrection = Instance.new("ColorCorrectionEffect")

-- vars


-- api

local antiaim = (function()
	local antiaim = {}

	antiaim.desync = { hitfloor = 0 }

	function antiaim.desync.start_prediction(self)
		local char = lp.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end
		if hum.FloorMaterial == Enum.Material.Air then self.hitfloor = 0 hrp.AssemblyLinearVelocity = vec3(hrp.AssemblyLinearVelocity.X, math.clamp(hrp.AssemblyLinearVelocity.Y, -300, 50), hrp.AssemblyLinearVelocity.Z) return end
		self.hitfloor += 1
		if self.hitfloor <= 5 then return end
		antiaim.true_velocity = hrp.AssemblyLinearVelocity
		local hrpStart = hrp.CFrame.Y
		hrp.AssemblyLinearVelocity = vec3(hrp.AssemblyLinearVelocity.X, 72.323211, hrp.AssemblyLinearVelocity.Z)
		--hrp.AssemblyLinearVelocity = -((hrp.CFrame.Position - target:GetPivot().Position) / client.deltaTime)
		hrp.Anchored = false
	end

	function antiaim.desync.end_prediction(self)
		local char = lp.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end
		if hum.FloorMaterial == Enum.Material.Air then self.hitfloor = 0 return end
		if self.hitfloor <= 5 then return end
		hrp.Anchored = false
		if antiaim.true_velocity.Y >= 300 then
			antiaim.true_velocity = vec3(antiaim.true_velocity.X, 0, antiaim.true_velocity.Z)
		end
		hrp.AssemblyLinearVelocity = (antiaim.true_velocity or Vector3.new())
	end

	function antiaim.set_pitch_value(self, pitchValue)
		self.pitch = pitchValue;
		return antiaim
	end

	function antiaim.set_yaw_Value(self, yawValue)
		self.yaw = yawValue;
		return antiaim
	end

	local set_pitch = function() end



	function antiaim:update()
		local char = lp.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end
		local yaw, pitch = self.yaw, self.pitch

		if yaw ~= nil then
			hum.AutoRotate = false
			hrp.CFrame = cf(hrp.Position) * angles(0, rad(yaw), 0)
		end

		if pitch ~= nil then
			set_pitch(pitch)
		end
	end

	if (is_PHANTOM_FORCES) then
		antiaim.update = function(self)
			local yaw, pitch = self.yaw, self.pitch


		end
	end

	return antiaim
end)()

function getMoveVector(pos, speed, vertical)
	local cfr = CFrame.new(pos, Vector3.new(pos.X + workspace.CurrentCamera.CFrame.LookVector.X, pos.Y, pos.Z + workspace.CurrentCamera.CFrame.LookVector.Z))

	if (not uis:GetFocusedTextBox() and uis:IsKeyDown(Enum.KeyCode.W)) then
		cfr *= CFrame.new(0,0,1)
	end
	if (not uis:GetFocusedTextBox() and uis:IsKeyDown(Enum.KeyCode.S)) then
		cfr *= CFrame.new(0,0,-1)
	end
	if (not uis:GetFocusedTextBox() and uis:IsKeyDown(Enum.KeyCode.A)) then
		cfr *= CFrame.new(1,0,0)
	end
	if (not uis:GetFocusedTextBox() and uis:IsKeyDown(Enum.KeyCode.D)) then
		cfr *= CFrame.new(-1,0,0)
	end

	local diff = (pos - cfr.Position)
	local unit = (diff.Magnitude > 0.5 and diff.Unit or Vector3.zero)
	local pos = CFrame.new(pos + unit * (speed or 1)).p
	if vertical then
		local height = 0
		if uis:IsKeyDown(Enum.KeyCode.Q) then height = -1 end
		if uis:IsKeyDown(Enum.KeyCode.E) then height = 1 end

		if flags.bypass_flag and math.floor(elapsed_ticks) % 3 == 0 then
			height = -height
		end

		pos += Vector3.new(0, height, 0)
	end

	return pos
end

function getFlyVector(pos, speed, vertical)
	local cfr = CFrame.new(pos, Vector3.new(pos.X + camera.CFrame.LookVector.X, pos.Y + camera.CFrame.LookVector.Y, pos.Z + camera.CFrame.LookVector.Z))
	if (not uis:GetFocusedTextBox() and uis:IsKeyDown(Enum.KeyCode.W)) then
		cfr *= CFrame.new(0,0,1)
	end
	if (not uis:GetFocusedTextBox() and uis:IsKeyDown(Enum.KeyCode.S)) then
		cfr *= CFrame.new(0,0,-1)
	end
	if (not uis:GetFocusedTextBox() and uis:IsKeyDown(Enum.KeyCode.A)) then
		cfr *= CFrame.new(1,0,0)
	end
	if (not uis:GetFocusedTextBox() and uis:IsKeyDown(Enum.KeyCode.D)) then
		cfr *= CFrame.new(-1,0,0)
	end

	local diff = (pos - cfr.Position)
	local unit = (diff.Magnitude > 0.5 and diff.Unit or Vector3.zero)
	local pos = CFrame.new(pos + unit * (speed or 1)).Position

	return (pos ~= cfr.Position and cf(pos, cfr.Position) * angles(0, math.rad(180), 0) or cfr)
end

local chams_functions = {
	breathe = function(model, flag, clr, onScreen, name)
		if tearParts[model] then
			for _, part in tearParts[model] do
				part:Destroy()
			end
			table.clear(tearParts[model])
			tearParts[model] = nil
		end
		viewport:ClearAllChildren()
		local breathe_effect = math.atan(math.sin(tick() * 2)) * 2 / math.pi
		local outline = chamsContainer:FindFirstChild(model.Name) or Instance.new("Highlight")
		local distance = (workspace.CurrentCamera.CFrame.Position - model:GetPivot().Position).Magnitude
		outline.FillColor, outline.OutlineColor = clr, clr
		outline.FillTransparency, outline.OutlineTransparency = 100 * breathe_effect * 0.01, 100 * breathe_effect * 0.01
		outline.FillTransparency, outline.OutlineTransparency = math.lerp(outline.FillTransparency, 1, math.clamp(distance / 400, 0, 1)), math.lerp(outline.OutlineTransparency, 1, math.clamp(distance / 400, 0, 1))
		outline.Name, outline.Enabled = name or model.Name, outline.OutlineTransparency < 1 or onScreen
		outline.Adornee, outline.Parent = model, chamsContainer
	end,
	normal = function(model, flag, clr, onScreen, name)
		if tearParts[model] then
			for _, part in tearParts[model] do
				part:Destroy()
			end
			table.clear(tearParts[model])
			tearParts[model] = nil
		end
		viewport:ClearAllChildren()
		local breathe_effect = math.atan(math.sin(tick() * 2)) * 2 / math.pi
		local outline = chamsContainer:FindFirstChild(model.Name) or Instance.new("Highlight")
		local distance = (workspace.CurrentCamera.CFrame.Position - model:GetPivot().Position).Magnitude
		outline.FillColor, outline.OutlineColor = clr, clr
		outline.FillTransparency, outline.OutlineTransparency = 0.5, 0.5
		outline.FillTransparency, outline.OutlineTransparency = math.lerp(0.5, 1, math.clamp(distance / 400, 0, 1)), math.lerp(outline.OutlineTransparency, 1, math.clamp(distance / 400, 0, 1))
		outline.Name, outline.Enabled = name or model.Name, outline.OutlineTransparency < 1 or onScreen
		outline.Parent, outline.Adornee = chamsContainer, model
	end,
	inverted = function(model, flag, clr, onScreen, name)
		if tearParts[model] then
			for _, part in tearParts[model] do
				part:Destroy()
			end
			table.clear(tearParts[model])
			tearParts[model] = nil
		end
		viewport:ClearAllChildren()
		local name = name or model.Name
		if not onScreen and chamsContainer:FindFirstChild(name) then
			return chamsContainer:FindFirstChild(name):Destroy()
		end	
		local breathe_effect = math.atan(math.sin(tick() * 2)) * 2 / math.pi
		local outline = chamsContainer:FindFirstChild(name) or Instance.new("Highlight")
		local distance = (workspace.CurrentCamera.CFrame.Position - model:GetPivot().Position).Magnitude
		outline.FillColor, outline.OutlineColor = Color3.new(.5,.5,.5), clr
		outline.FillTransparency, outline.OutlineTransparency = -1, 0
		outline.Name, outline.Enabled = name, outline.OutlineTransparency < 1 or onScreen
		outline.Parent, outline.Adornee = chamsContainer, model
	end,
	occluded = function(model, flag, clr, onScreen)
		if tearParts[model] then
			for _, part in tearParts[model] do
				part:Destroy()
			end
			table.clear(tearParts[model])
			tearParts[model] = nil
		end
		viewport:ClearAllChildren()

		local m = holder:FindFirstChild(model.Name)
		if not onScreen then
			pcall(function()
				local outline = chamsContainer:FindFirstChild(model.Name)
				local occluded = chamsContainer:FindFirstChild(model.Name .. "?")
				occluded:Destroy()
				outline:Destroy()
			end)
			if m then m:Destroy() end
			return
		end

		pcall(function()
			for _,v in holder:GetChildren() do
				if not v.Linked.Value or not v.Linked.Value:IsDescendantOf(workspace) then
					v:Destroy()
				else
					local plr = players:GetPlayerFromCharacter(v.Linked.Value)
					local team = plr.Team and plr.Team == lp.Team
					if team then
						v:Destroy()
					end
				end
			end
		end)

		if not holder:FindFirstChild(model.Name) then
			for i,v in model:GetDescendants() do
				if v:IsA("BasePart") then
					v:SetAttribute("linkName", math.random() * math.random(1,1e3))
				end
			end
			local new = cloneref(model)
			new.Archivable = true
			new = new:Clone()
			if not pcall(function()
					new:FindFirstChildOfClass("Humanoid"):Destroy()
				end) then return end
			new.Parent = holder
			local chams = Instance.new("Highlight")
			chams.FillColor, chams.OutlineColor = clr, clr
			chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			chams.FillTransparency, chams.OutlineTransparency = 0, 0
			chams.Name, chams.Enabled = model.Name .. "?", onScreen
			chams.Parent, chams.Adornee = chamsContainer, new
			create("ObjectValue", {
				Name = "Linked",
				Value = model,
				Parent = new,
			})
			local outline = chamsContainer:FindFirstChild(model.Name) or Instance.new("Highlight")
			outline.FillColor, outline.OutlineColor = clr, clr:Lerp(rgb(255,255,255),0.1)
			outline.DepthMode = Enum.HighlightDepthMode.Occluded
			outline.FillTransparency, outline.OutlineTransparency = 0.99, 1
			outline.Name, outline.Enabled = model.Name, onScreen
			outline.Parent, outline.Adornee = chamsContainer, model

			local this; this = model.AncestryChanged:Once(function()
				this:Disconnect()
				this = nil
				new:Destroy()
				chams:Destroy()
			end)
			local m = new
			for i,v in m:GetDescendants() do
				if v:IsA("CharacterMesh") then
					local meshId = v.MeshId
					local bodyPart = v.BodyPart.Name
					for _,v in m:GetChildren() do
						if v:IsA("BasePart") and v.Name:gsub(" ", "") == bodyPart then
							local mesh = Instance.new("SpecialMesh")
							mesh.MeshId = string.format("rbxassetid://%s", meshId)
							mesh.Parent = v
						end
					end
					v:Destroy()
				end
			end
			for i,v in model:GetDescendants() do
				if v:IsA("BasePart") then
					local realPart = m:FindFirstChild(v.Name) or getFromAttribute(m, v:GetAttribute("linkName"))
					if realPart then
						realPart.Size *= 0.98
						realPart:BreakJoints()
						realPart.CanTouch = false
						realPart.Material = Enum.Material.SmoothPlastic
						pcall(function() realPart.TextureID = "" end)
						realPart.CanCollide = false
						realPart.CanQuery = false
						realPart.CFrame = v.CFrame
						local weld = Instance.new("Weld")
						weld.Part0 = v
						weld.Part1 = realPart
						weld.Name = ""
						weld.Parent = realPart
					end
				end
			end
		end

		pcall(function()
			local outline = chamsContainer:FindFirstChild(model.Name)
			local occluded = chamsContainer:FindFirstChild(model.Name .. "?")
			occluded.Enabled, outline.Enabled = onScreen, onScreen
		end)

		if not m then return end


	end,
}

local rgb, cf, vec3, floor, ceil, clamp = Color3.fromRGB, CFrame.new, Vector3.new, math.floor, math.ceil, math.clamp

local esp, library, baseProperties = {}, library or {}, {
	TextLabel = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		RichText = true,
	}
}
function library:new(class, properties, children)
	local object = Instance.new(class)

	if baseProperties[class] then
		for prop, value in baseProperties[class] do
			object[prop] = value
		end
	end

	for prop, value in properties do
		object[prop] = value
	end

	if children then
		for _, child in children do
			child.Parent = object
		end
	end

	return object
end

esp.config = {
	seraph = `<font color="rgb(220,50,50)"><b>[S]</b></font>`,
	ax = `<font color="rgb(220,0,9)"><b>EXP</b></font>`,
	health_bar_width = 35,
	health_bar_padding = 5,
	font = fonts.Tahoma or Font.new("rbxassetid://12187362578", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	health_alive = rgb(255,255,255),
	health_dead = rgb(0,0,0),
	color = rgb(255,255,255),
	secondary = rgb(),

	features = {}
}

library.esp_gui = library:new("ScreenGui", {
	Parent = gethui and gethui() or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

function library:isBright(rgb) 
	return (rgb.R > .5 or rgb.B > .5 or rgb.G > .5) 
end

function library:toRgbValues(color: Color3)
	return clamp(floor(color.R * 255), 0, 255),clamp(floor(color.G * 255), 0, 255),clamp(floor(color.B * 255), 0, 255)
end

function library:invert(color: Color3) 
	local r, g, b = library:toRgbValues(color)
	return rgb(255 - r, 255 - g, 255 - b)
end

function esp:update_to_theme(frame)
	local health = frame.health
	local background = health.backgroundbar
	local clr = flags.esp_primary.Color
	frame.glow.ImageColor3 = clr
	health.outline.Color = clr
	background.bg.BackgroundColor3 = clr:lerp(rgb(), .8)
end

function esp:create()
	return library:new("Frame",{
		BackgroundTransparency = 1,
		Size = UDim2.new(0,100,0,250),
		Position = UDim2.new(0.5,0,0.5,0),
		Parent = library.esp_gui
	}, {
		library:new("UIGradient", {
			Name = "gradient",
			Rotation = -90
		}),

		library:new("UIStroke", {
			Name = "box",
			Thickness = 1,
			Color = esp.config.color,
			LineJoinMode = Enum.LineJoinMode.Miter,
		}, {
			library:new("UIGradient", {
				Name = "gradient"
			})
		}),

		library:new("ImageLabel", {
			Name = "cat",
			ImageTransparency = 1,
			BackgroundTransparency = 1,
			Image = "rbxassetid://101187568031385",
			ImageColor3 = rgb(255,255,255),
			ImageTransparency = 0.25,
			Size = UDim2.new(1,0,1,0),
			ZIndex = -3,
		}),

		library:new("UIStroke", {
			Name = "outline",
			ZIndex = -1,
			Thickness = 2,
			LineJoinMode = Enum.LineJoinMode.Miter,
			Color = rgb(0,0,0)
		}),

		library:new("UIStroke", {
			Name = "inner",
			BorderStrokePosition = Enum.BorderStrokePosition.Inner,
			ZIndex = -1,
			Thickness = 1,
			LineJoinMode = Enum.LineJoinMode.Miter,
			Color = rgb(0,0,0)
		}),

		library:new("ImageLabel", {
			Name = "glow",
			Image = "rbxassetid://18245826428",
			BackgroundTransparency = 1,
			ImageColor3 = esp.config.color,
			ZIndex = -1,
			ImageTransparency = 0.8,
			Size = UDim2.new(1, 40, 1, 40),
			Position = UDim2.new(0, -20, 0, -20),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(21, 21, 79, 79)
		}, {
			library:new("UICorner", {
				CornerRadius = UDim.new(0, 4)
			})	
		}),

		-- start footer
		library:new("Frame", {
			Name = "footer",
			AnchorPoint = Vector2.new(0.5,0),
			Position = UDim2.new(0.5,0,1,5),
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			ZIndex = 25,
		}, {

			library:new("UIListLayout", {
				Name = "padding",
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 5)
			}),

			library:new("TextLabel", {
				Name = "distance",
				Text = `0M`,
				Size = UDim2.new(0,0,0,0),
				AutomaticSize = Enum.AutomaticSize.XY,
				FontFace = fonts.Pixel,
				TextSize = 12,
				TextStrokeTransparency = 0.5,
				TextColor3 = rgb(255,255,255),
				LayoutOrder = 1,
			}),

			library:new("Frame", {
				Name = "ammo",
				Size = UDim2.new(1,0,0,4),
				BackgroundColor3 = rgb(2, 2, 2),
				BackgroundTransparency = 0.4,
				LayoutOrder = 2,
			}, {
				library:new("ImageLabel", {
					Name = "glowbg",
					Image = "rbxassetid://18245826428",
					BackgroundTransparency = 1,
					ZIndex = -1,
					ImageColor3 = rgb(),
					ImageTransparency = 0.8,
					Size = UDim2.new(1, 40, 1, 40),
					Position = UDim2.new(0, -20, 0, -20),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(21, 21, 79, 79)
				}, {
					library:new("UICorner", {
						CornerRadius = UDim.new(0, 4)
					})	
				}),
				library:new("Frame", {
					Name = "fill",
					Position = UDim2.new(0,1,0,-1),
					Size = UDim2.new(1,-2,0,2),
					BackgroundColor3 = rgb(255, 255, 255),
					BackgroundTransparency = 0,
					LayoutOrder = 2,
				}, {
					library:new("UIGradient", {
						Name = "gradient",
						Rotation = 90,
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, rgb(255,255,255)),
							ColorSequenceKeypoint.new(1, rgb(158, 158, 158))
						}
					}),
				}),
			}),

		}),
		-- stop footer

		-- start header
		library:new("Frame", {
			Name = "header",
			Position = UDim2.new(0.5,0,0,-5),
			Size = UDim2.new(1,0,0,0),
			AutomaticSize = Enum.AutomaticSize.Y,
			AnchorPoint = Vector2.new(0.5,1),
			BackgroundTransparency = 1
		}, {

			library:new("UIListLayout", {
				Name = "padding",
				Padding = UDim.new(0, 1),
				VerticalAlignment = Enum.VerticalAlignment.Bottom
			}),

			library:new("TextLabel", {
				Name = "team",
				Text = `<font color="rgb(255,0,0)"><b>[N]</b></font> Neutral`,
				Size = UDim2.new(1,0,0,0),
				AutomaticSize = Enum.AutomaticSize.Y,
				FontFace = esp.config.font,
				TextStrokeTransparency = 0.5,
				TextColor3 = rgb(255,255,255),
				TextSize = 15,
				LayoutOrder = 2,
			}),

			library:new("TextLabel", {
				Name = "username",
				Text = `{esp.config.seraph} {esp.config.ax} username`,
				Size = UDim2.new(1,0,0,0),
				AutomaticSize = Enum.AutomaticSize.Y,
				FontFace = esp.config.font,
				TextStrokeTransparency = 0.5,
				TextSize = 15,
				TextColor3 = rgb(255,255,255),
				LayoutOrder = 1,
			}),

		}),

		library:new("Frame", {
			Name = "flags",
			Position = UDim2.new(1,10,0,1),
			Size = UDim2.new(1,0,0,0),
			AutomaticSize = Enum.AutomaticSize.Y,
			AnchorPoint = Vector2.new(0,0),
			BackgroundTransparency = 1
		}, {

			library:new("UIListLayout", {
				Name = "padding",
				Padding = UDim.new(0, 1),
				VerticalAlignment = Enum.VerticalAlignment.Bottom
			}),

			library:new("TextLabel", {
				Name = "team",
				Text = ``,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1,0,0,0),
				AutomaticSize = Enum.AutomaticSize.Y,
				FontFace = fonts.Pixel,
				TextStrokeTransparency = 0.5,
				TextColor3 = rgb(255,255,255),
				TextSize = 15,
				LayoutOrder = 2,
			}),

		}),
		-- end header

		--[[player_icon = library:new("ImageLabel", {
			Name = "icon",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 5, 0, -5),
			BackgroundTransparency = 0,
			BackgroundColor3 = rgb(0, 0, 0),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Size = UDim2.new(0,15,0,15),
		}),]]

		-- health
		library:new("Frame", {
			Name = "health",
			--Size = UDim2.new(0, esp.config.health_bar_width, 1, 2),
			--Position = UDim2.new(0, -(esp.config.health_bar_width + esp.config.health_bar_padding), 0, -1),
			--Size = UDim2.new(esp.config.health_bar_width / 1000, 0, 1, 2),
			--Position = UDim2.new(0 - esp.config.health_bar_width / 1000, -(esp.config.health_bar_padding), 0, -1),
			Size = UDim2.new(esp.config.health_bar_width / 1000, 0, 1, 0),
			Position = UDim2.new(0 - esp.config.health_bar_width / 1000, -(esp.config.health_bar_padding), 0, 0),
			BackgroundTransparency = 1,
		}, {
			library:new("UISizeConstraint", {
				MaxSize = Vector2.new(math.huge, math.huge),
				MinSize = Vector2.new(1, 0)
			}),

			--[[
			library:new("TextLabel", {
				Name = "percentage",
				BackgroundTransparency = 1,
				TextColor3 = rgb(255,255,255),
				TextStrokeTransparency = 0.5,
				Position = UDim2.new(0.5,0,1.001,5),	
				AnchorPoint = Vector2.new(0.5,0),
				FontFace = esp.config.font,
				Rotation = 0,
				TextSize = 12,
				Text = "100%",
				ZIndex = 5,
			}),
			]]

			library:new("TextLabel", {
				Name = "percentage",
				BackgroundTransparency = 1,
				TextColor3 = rgb(255,255,255),
				TextStrokeTransparency = 0.5,
				--Position = UDim2.new(-1,0,0.5,0),
				--AnchorPoint = Vector2.new(0,0.5),
				Position = UDim2.new(-1,0,0,0),
				AnchorPoint = Vector2.new(0.5,0),
				Size = UDim2.new(1,0,0,0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextXAlignment = Enum.TextXAlignment.Center,
				FontFace = esp.config.font,
				Rotation = 0,
				TextSize = 12,
				Text = "100%",
				ZIndex = 25,
			}),

			library:new("Frame", {
				Name = "backgroundbar",
				BackgroundColor3 = rgb(0,0,0),
				BorderSizePixel = 0,
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5,0,1,0),
				AnchorPoint = Vector2.new(0.5,1),
			}, {

				library:new("Frame", {
					Name = "bg",
					BackgroundColor3 = esp.config.color:lerp(rgb(), .8),
					BorderSizePixel = 0,
					Size = UDim2.new(1,0,1,0),
					Position = UDim2.new(0.5,0,1,0),
					AnchorPoint = Vector2.new(0.5,1),
					ZIndex = 10,
				}, {
					library:new("UIStroke", {
						Name = "first",
						BorderStrokePosition = Enum.BorderStrokePosition.Inner,
						ZIndex = 5,
						Thickness = 1,
						Transparency = 0.8,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Color = esp.config.color
					}),
					library:new("UIStroke", {
						Name = "middle",
						BorderStrokePosition = Enum.BorderStrokePosition.Inner,
						ZIndex = 4,
						Thickness = 2,
						Transparency = 0.9,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Color = esp.config.color
					}),
					library:new("UIStroke", {
						Name = "farthest",
						BorderStrokePosition = Enum.BorderStrokePosition.Inner,
						ZIndex = 3,
						Thickness = 3,
						Transparency = 0.99,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Color = esp.config.color
					}),
				}),


				library:new("ImageLabel", {
					Name = "glowbg",
					Image = "rbxassetid://18245826428",
					BackgroundTransparency = 1,
					ZIndex = -1,
					ImageColor3 = rgb(),
					ImageTransparency = 0.8,
					Size = UDim2.new(1, 40, 1, 40),
					Position = UDim2.new(0, -20, 0, -20),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(21, 21, 79, 79)
				}, {
					library:new("UICorner", {
						CornerRadius = UDim.new(0, 4)
					})	
				}),

				library:new("UIGradient", {
					Name = "gradient"
				}),
				library:new("ImageLabel", {
					Name = "glow",
					Image = "rbxassetid://18245826428",
					BackgroundTransparency = 1,
					ZIndex = -1,
					ImageTransparency = 0.5,
					Size = UDim2.new(1, 20, 1, 20),
					Position = UDim2.new(0.5,0,1,0),
					AnchorPoint = Vector2.new(0.5,1),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(21, 21, 79, 79)
				}, {
					library:new("UICorner", {
						CornerRadius = UDim.new(0, 4)
					}),
					library:new("UIGradient", {
						Name = "gradient",
						Rotation = 90
					})
				}),
			}),

			library:new("Frame", {
				Name = "bar",
				BackgroundColor3 = rgb(255,255,255),
				BorderSizePixel = 0,
				Size = UDim2.new(1,0,1,0),
				Position = UDim2.new(0.5,0,1,0),
				AnchorPoint = Vector2.new(0.5,1),
				ZIndex = 2
			}, {
				library:new("UIGradient", {
					Name = "gradient",
					Rotation = 90
				})
			}),


			library:new("UIStroke", {
				Name = "outline",
				ZIndex = 30,
				Thickness = 1,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Color = esp.config.color
			}),

			library:new("UIStroke", {
				Name = "border",
				ZIndex = -2,
				Transparency = 0.5,
				Thickness = 2,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Color = rgb(0,0,0)
			}),
		})
	})
end

local function worldToScreenPoint(obj)
	return workspace.CurrentCamera:WorldToScreenPoint(typeof(obj) == 'CFrame' and obj.Position or obj)
end

function getScreenRect(cf, size, minPixels)
	minPixels = minPixels or 10

	local half = size * 0.5

	local corners = {
		cf * Vector3.new(-half.X,  half.Y, 0),
		cf * Vector3.new( half.X,  half.Y, 0),
		cf * Vector3.new(-half.X, -half.Y, 0),
		cf * Vector3.new( half.X, -half.Y, 0),
	}

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	for _, worldPos in corners do
		local screenPos, onScreen = worldToScreenPoint(worldPos)
		if not onScreen then
			return nil
		end

		minX = math.min(minX, screenPos.X)
		minY = math.min(minY, screenPos.Y)
		maxX = math.max(maxX, screenPos.X)
		maxY = math.max(maxY, screenPos.Y)
	end

	local width  = maxX - minX
	local height = maxY - minY
	local cx = minX + width * 0.5
	local cy = minY + height * 0.5
	width  = math.max(width,  minPixels)
	height = math.max(height, minPixels)
	minX = cx - width * 0.5
	minY = cy - height * 0.5

	return minX, minY, width, height
end

function getFontSize(worldPos, base, min, max, scale)
	local camCF = workspace.CurrentCamera.CFrame
	local relative = camCF:PointToObjectSpace(worldPos.Position)

	local dist = (camCF.Position - worldPos.Position).Magnitude

	return clamp(base * (1 - clamp(dist / (250 * (scale or 1)), 0, 1)), 1, max or 36)
end

function esp:hide(player)
	local frame = esp_frames[player]
	if frame then
		frame.Visible = false
	end
end

function interp(base, next, t, ft)
	return math.lerp(base, next, t*ft)
end

function esp:full_render(dt, player, position, size, healthRatio)
	local healthRatio = healthRatio

	local frame = esp_frames[player]

	local ccf = workspace.CurrentCamera.CFrame
	local size = size or vec3(2, 4, 1)
	local pos = cf(position, ccf.LookVector + position) * cf(0, -0.25, 0)

	local distance = (ccf.Position - position).Magnitude

	esp:update_to_theme(frame)
	local features = flags.featureflags or {}
	local dist = frame.footer.distance
	local health = frame.health
	local healthgrad = health.bar.gradient
	local healthglow = health.backgroundbar.glow
	local healthbg = health.backgroundbar.bg
	local header = frame.header

	if flags.esp_distance then
		dist.Text = `{floor(distance)}{flags.esp_suffix and "M" or ""}`
		dist.Visible = true
	else
		dist.Visible = false
	end

	if flags.esp_healthbar then
		health.Size = UDim2.new(flags.health_bar_width / 1000, 0, 1, 0)
		health.Position = UDim2.new(0 - flags.health_bar_width / 1000, -(esp.config.health_bar_padding), 0, 0)
		health.bar.Size = UDim2.fromScale(1, healthRatio)
		healthgrad.Color = ColorSequence.new(flags.maxhealth.Color, flags.minhealth.Color)
		healthgrad.Offset = -Vector2.new(0,1 - healthRatio)

		if flags.health_bar_glow then
			local glow_gradient = healthglow.gradient

			healthglow.Size = UDim2.new(1, 20, healthRatio, 20)
			healthglow.Position = UDim2.new(0.5, 0, 1, 10)

			healthglow.ImageTransparency = 0.3

			glow_gradient.Color = healthgrad.Color
			glow_gradient.Offset = -Vector2.new(0,1 - healthRatio)
		else
			healthglow.Visible = false
		end


		health.percentage.Text = ""

		local thickness = clamp(1 - (distance / 250), 0.3, 1)
		health.outline.Thickness = thickness
		healthbg.first.Thickness = thickness
		healthbg.middle.Thickness = clamp(2 - (distance / 250) * 2, 0.3, 2)
		healthbg.farthest.Thickness = clamp(3 - (distance / 250) * 3, 0.3, 3)
		health.border.Thickness = thickness <= 0.5 and 1 or 2
		health.Visible = true
	else
		health.Visible = false
	end

	if flags.bounding_box and flags.esp_gradient then
		frame.box.Color = rgb(255,255,255)
		frame.box.gradient.Color = rgbseq(flags.esp_secondary.Color, flags.esp_primary.Color)
		frame.box.gradient.Rotation = flags.esp_gradient_rotation
	else
		frame.box.Color = flags.esp_secondary.Color
		frame.box.gradient.Color = rgbseq(rgb(255,255,255),rgb(255,255,255))
	end

	local box = flags.bounding_box
	frame.box.Transparency = box and 0 or 1
	frame.inner.Transparency = box and 0 or 1
	frame.outline.Transparency = box and 0 or 1
	frame.glow.Visible = box

	if flags.esp_username then
		header.username.Text = flags.prefer_display_name and player.DisplayName or player.Name
		header.username.Visible = true
	else
		header.username.Visible = false
	end

	if flags.esp_ammobar then
		frame.footer.ammo.Visible = true
		frame.footer.ammo.fill.BackgroundColor3 = flags.ammo_bar_color.Color
	else
		frame.footer.ammo.Visible = false
	end

	if box and flags.esp_cat then
		frame.cat.ImageTransparency = 0.25
	else
		frame.cat.ImageTransparency = 1
	end

	header.team.Visible = false
	frame.BackgroundTransparency = box and flags.esp_filled and 1-flags.esp_primary.Transparency or 1
	frame.gradient.Color = ColorSequence.new(flags.esp_secondary.Color, flags.esp_primary.Color)
end


function esp:render(dt, player, position, size, healthRatio)
	local healthRatio = clamp(healthRatio / 100, 0, 1)
	if not esp_frames[player] then
		esp_frames[player] = esp:create(player)
		task.spawn(esp.full_render, esp, dt, player, position, size, healthRatio)
	end

	local frame = esp_frames[player]

	local screenPos, visible = workspace.CurrentCamera:WorldToScreenPoint(position)
	if not visible then
		frame:SetAttribute("renderLast", 0)
		frame.Visible = false
		return
	end

	local ccf = workspace.CurrentCamera.CFrame
	local pos = cf(position, ccf.LookVector + position) * cf(0, -0.25, 0)
	local distance = (ccf.Position - pos.Position).Magnitude
	local x, y, w, h = getScreenRect(pos, size*(1+(distance/300)))

	local distance = (ccf.Position - position).Magnitude

	if not x then
		frame.Visible = false
		return
	end

	if not frame:GetAttribute("renderLast") then frame:SetAttribute("renderLast", tick()) end
	local lastHealth = frame:GetAttribute('lastHealth') or healthRatio
	local lastForce = frame:GetAttribute("renderLast")
	local forceRefresh

	local dist = frame.footer.distance
	local health = frame.health
	local header = frame.header


	if lastHealth ~= healthRatio then
		forceRefresh = true
	end
	frame:SetAttribute('lastHealth', healthRatio)
	if tick() - lastForce >= 8.5 then
		lastForce = tick()
		forceRefresh = true
	end

	frame:SetAttribute("renderLast", lastForce)
	if forceRefresh then
		task.spawn(esp.full_render, esp, dt, player, position, size, healthRatio)
	end


	--[[header.team.TextSize = getFontSize(pos, 17, 1, 36, 1.5)
	dist.TextSize = getFontSize(pos, 12, 1, 36, 1.5)
	header.username.TextSize = getFontSize(pos, 17, 1, 36, 1.5)
	health.percentage.TextSize = getFontSize(pos, 12, 1, 36, 1.5)]]

	header.team.TextSize = 12 * flags.esp_font_size_multiplier * (math.clamp(1 - (distance / 1000), 0.5, 1))
	dist.TextSize = 10 * flags.esp_font_size_multiplier * (math.clamp(1 - (distance / 1000), 0.5, 1))
	header.username.TextSize = 12 * flags.esp_font_size_multiplier
	health.percentage.TextSize = 10 * flags.esp_font_size_multiplier
	local flagtext = ""
	--[[if library.player_state and library.player_state[player] and library.player_state[player].exploiting then
		flagtext ..= `<font color="{rgbstr(rgb(220,0,9):lerp(rgb(133, 133, 133), 1 - library.player_state[player].exploitCharge / 2))}"><b>EXPLOITING [{library.player_state[player].exploitCharge}s]</b></font>`
	end]]
	for _, flag in frame.flags:GetChildren() do
		if not flag:IsA("TextLabel") then continue end
		flag.TextSize = 8.5 * flags.esp_font_size_multiplier * (math.clamp(1 - (distance / 1000), 0.5, 1))
		flag.Text = flagtext
	end

	local entry = library.modules.ReplicationInterface.getEntry(player)
	if entry then
		local weapon = entry:getWeaponObject()
		if entry and weapon then
			pcall(function()frame.footer.ammo.fill.Size = UDim2.new(clamp((entry.ammo or weapon.weaponData.magsize) / weapon.weaponData.magsize, 0, 1), 0, 1, 0)end)
		end
	end

	dist.Text = `{floor(distance)}M`

	frame.Position = UDim2.fromOffset(x, y)
	frame.Size = UDim2.fromOffset(w, h)

	frame.Visible  = true
end

function render_chams(plr, model, flag, clr, mat)
	if not model then return end
	local chams_color = clr or themes.preset["1"]:Lerp(themes.preset["3"], 0.5 + 0.5 * math.cos(elapsed_ticks / 12))
	if not flag then
		if chamsContainer:FindFirstChild(plr.Name) then
			chamsContainer:FindFirstChild(plr.Name):Destroy()
		end
	else
		local _, onScreen = workspace.CurrentCamera:WorldToScreenPoint((model:FindFirstChild("Torso") or model:GetPivot()).Position)

		chams_functions[mat](model, flag, chams_color, onScreen, plr.Name)
	end
end

local moduleCache = getgenv().replacementForModules and getgenv().replacementForModules[1] or (pcall(function() return debug.getupvalue(getrenv().shared.require, 1)._cache end) and debug.getupvalue(getrenv().shared.require, 1)._cache or {})
local modules = setmetatable({}, {
	__index = function(Self, Index)
		if not moduleCache[Index] then return nil end
		return moduleCache[Index].module
	end
});
local Replication      = modules.ReplicationInterface


function getFromAttribute(arr, att)
	local o
	for i,v in arr:GetDescendants() do
		if v:IsA("BasePart") and v:GetAttribute("linkName") == att then
			o = v
			break
		end
	end
	return o
end

local whitelisted_meshes = { 'rbxassetid://6178917497', 'rbxassetid://6178916430' }
library.meshes = {}

function characterChamsSelf(player, entry, charInstance)
	local h = charInstance:GetDescendants()
	local weapon = charInstance:FindFirstChildWhichIsA("Model")
	if weapon and flags.ignoreweapons then
		for _, part in weapon:GetDescendants() do
			if part:IsA("BasePart") then
				if table.find(h, part) then
					table.remove(h, table.find(h, part))
				end
			end
		end
	end

	local translatedMeshes = {
		["rbxassetid://4049240209"] = "rbxasset://fonts/rightarm.mesh",
		["rbxassetid://4049240323"] = "rbxasset://fonts/leftarm.mesh",
		["rbxassetid://4049240078"] = "rbxasset://fonts/torso.mesh"
	}

	task.spawn(function()
		if flags.altforcefield then return end
		for _,v in charInstance:GetChildren() do
			if v:IsA("BasePart") and not v:FindFirstChild("fake") then
				local mesh = v:FindFirstChildWhichIsA("SpecialMesh")
				if not mesh then continue end
				v.Transparency = 1
				local temp = Instance.new("Folder")
				temp.Name = "fake"
				temp.Parent = v
				local showcasePart = library.meshes[mesh.MeshId] and library.meshes[mesh.MeshId]:Clone()
				if not showcasePart then
					showcasePart = services.insertService:CreateMeshPartAsync(translatedMeshes[mesh.MeshId] or mesh.MeshId, Enum.CollisionFidelity.Default, Enum.RenderFidelity.Automatic)
				end
				if not library.meshes[mesh.MeshId] then
					library.meshes[mesh.MeshId] = showcasePart:Clone()
				end
				local ogp = v:Clone()
				showcasePart.CanCollide, showcasePart.CanTouch, showcasePart.CanQuery = false,false,false
				pcall(function() showcasePart:ClearAllChildren() end)
				showcasePart.Parent = v
				showcasePart.Name = "fake"
				showcasePart.Size *= 1.03
				local weld = Instance.new("Weld")
				weld.Parent = showcasePart
				weld.Part0 = v
				weld.Part1 = showcasePart
				local showcasePart = ogp
				showcasePart.Size *= .989
				showcasePart:FindFirstChildWhichIsA("SpecialMesh").Scale *= 0.9
				showcasePart.Material = Enum.Material.SmoothPlastic
				showcasePart.Transparency = 0
				showcasePart.Name = "donechangemebitch"
				--showcasePart.TextureID = mesh.TextureId
				showcasePart.Anchored = false
				showcasePart:BreakJoints()
				showcasePart.CanCollide, showcasePart.CanTouch, showcasePart.CanQuery = false,false,false
				showcasePart.Parent = v
				for _,v in showcasePart:GetChildren() do
					pcall(function() v.Color3 = flags.self_character_chams_color.Color end)
				end

				for _, base in showcasePart:GetChildren() do if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end end
				showcasePart.Color = rgb(233,233,233)
				pcall(function()
					local decal = showcasePart:FindFirstChildWhichIsA("Decal")
					if decal and decal.Texture == "rbxassetid://5196259061" then
						decal.Texture = "rbxassetid://15298379"
					end
				end)
				local weld = Instance.new("Weld")
				weld.Parent = showcasePart
				weld.Part0 = v
				weld.Part1 = showcasePart
				if flags.self_character_chams_material ~= "forcefield" or flags.self_character_chams_hide_body_parts then
					showcasePart:Destroy()
				end
				temp:Destroy()
				task.delay(0.5, characterChamsSelf, player, entry, charInstance)
			end
		end
	end)
	for _,v in h do
		if ( v:IsA("Texture") or v:IsA("Decal")) then v:Destroy() continue end
		pcall(function() v.TextureId = flags.self_character_chams_material == "forcefield" and forcefieldanimations[flags.self_character_chams_forcefield_style] or "" v.VertexColor = Vector3.new(flags.self_character_chams_color.Color.R,flags.self_character_chams_color.Color.G,flags.self_character_chams_color.Color.B) end)
		if not v:IsA("BasePart") then continue end
		local weldBase = v:FindFirstChildOfClass("Weld")
		if weldBase and v:IsA("MeshPart") and v.MeshId and not table.find(whitelisted_meshes, v.MeshId:lower()) and v.Parent:IsA("Folder") then
			v.Transparency = (flags.hide_local_attachments and 1 or 0.99)
			if flags.hide_local_attachments then
				continue
			end
		elseif weldBase and v:IsA("MeshPart") and v.Parent:IsA("Folder") and not flags.self_character_chams_hide_body_parts and flags.self_character_chams_material == "forcefield" then
			local donechangemebitch = v:FindFirstChild("donechangemebitch")
			if not donechangemebitch then
				local part = v:Clone()
				part:ClearAllChildren()
				part.Name = "donechangemebitch"
				part.Parent = v
				part.Size *= .9
				local weld = Instance.new("Weld")
				weld.Parent = part
				weld.Part0 = v
				weld.C0 *= cf(0,0.05,0)
				weld.Part1 = part

			end
		end
		if v.Name == "donechangemebitch" and flags.self_character_chams_material == "forcefield" then
			v.Transparency = 0
			continue
		elseif v.Name == "donechangemebitch" then
			v.Transparency = 1
			continue
		end
		pcall(function() v.UsePartColor = true end)
		pcall(function() v.TextureID = flags.self_character_chams_material == "forcefield" and forcefieldanimations[flags.self_character_chams_forcefield_style] or "" end)
		v.Color = flags.self_character_chams_color.Color
		if v.Material == Enum.Material.ForceField and v:IsA("MeshPart") then v.Transparency = -15 + (flags.self_character_chams_color.Transparency * 15) elseif v.Transparency ~= 1 then v.Transparency = 1 - flags.self_character_chams_color.Transparency end
		v.Material = (flags.self_character_chams_material == "flat" and Enum.Material.SmoothPlastic) or (flags.self_character_chams_material == "neon" and Enum.Material.Neon) or (flags.self_character_chams_material == "forcefield" and Enum.Material.ForceField)
	end
end


function characterChams(player, entry, charInstance)
	local team = player.Team
	local localTeam = lp.Team
	local isEnemy = entry:isEnemy() and entry:isAlive()
	local isActive = true
	if flags.enemy_only_character and isActive then
		isActive = isEnemy
	end

	if isActive then
		local _, onScreen = workspace.CurrentCamera:WorldToScreenPoint((charInstance:FindFirstChild("Torso") or charInstance:GetPivot()).Position)
		local h = charInstance:GetDescendants()
		task.spawn(function()
			for _,v in charInstance:GetChildren() do
				if v:IsA("BasePart") and not v:FindFirstChild("detected") then
					local mesh = v:FindFirstChildWhichIsA("SpecialMesh")
					if not mesh then continue end
					v.Transparency = 1
					local temp = Instance.new("Folder")
					temp.Name = "detected"
					temp.Parent = v
					local showcasePart = library.meshes[mesh.MeshId] and library.meshes[mesh.MeshId]:Clone()
					if not showcasePart then
						showcasePart = services.insertService:CreateMeshPartAsync(mesh.MeshId, Enum.CollisionFidelity.Default, Enum.RenderFidelity.Automatic)
					end
					if not library.meshes[mesh.MeshId] then
						library.meshes[mesh.MeshId] = showcasePart:Clone()
					end
					showcasePart.Name = "fake"
					if showcasePart.Size.Magnitude >= 3 then
						continue
					end
					local weld = Instance.new("Weld")
					weld.Parent = showcasePart
					weld.Part0 = v
					weld.Part1 = showcasePart
					showcasePart.CanCollide, showcasePart.CanTouch, showcasePart.CanQuery = false,false,false
					showcasePart.Parent = charInstance
					local weldUpdate; weldUpdate = charInstance.AncestryChanged:Connect(function(_, parent)
						if not pcall(function() weld.Parent = showcasePart end) then
							weld = Instance.new("Weld")
							weld.Parent = showcasePart
						end
						weld.Part0 = v
						weld.Part1 = showcasePart
					end)
					local parentChanged; parentChanged = charInstance.Destroying:Connect(function(_, parent)
						if not parent then
							parentChanged:Disconnect()
							showcasePart:Destroy()
							weldUpdate:Disconnect()
						end
					end)
					task.delay(1/30, characterChams, player, entry, charInstance)
				end
			end
		end)
		for index, v in h do
			if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end
			if v:IsA("SpecialMesh") then v.TextureId = "" continue end
			if not v:IsA("BasePart") then continue end
			if weldBase and v:IsA("MeshPart") and v.MeshId and not table.find(whitelisted_meshes, v.MeshId:lower()) and v.Parent:IsA("Folder") then
				v.Transparency = (flags.hide_local_attachments and 1 or 0.99)
			end
			pcall(function() v.UsePartColor = true end)
			pcall(function() v.TextureID = flags.character_chams_material == "forcefield" and forcefieldanimations[flags.character_chams_forcefield_style] or "" end)
			v.Color = flags.character_chams_color.Color
			if v.Transparency ~= 1 then v.Transparency = 1 - flags.character_chams_color.Transparency end
			v.Material = (flags.character_chams_material == "flat" and Enum.Material.SmoothPlastic) or (flags.character_chams_material == "neon" and Enum.Material.Neon) or (flags.character_chams_material == "forcefield" and Enum.Material.ForceField)
			if index % 20 == 0 then task.wait() end
		end
	end
end

library.playersFolder = workspace:FindFirstChild("Players")
task.spawn(function()
	if not library.playersFolder then repeat task.wait() library.playersFolder = workspace:FindFirstChild("Players") until library.playersFolder end
	library.playersFolder.DescendantAdded:Connect(function(object)
		if not flags.character_chams then return end
		if not object:IsA("Model") then return end
		local part = object:FindFirstChildWhichIsA("BasePart")
		if not part then
			repeat
				run.RenderStepped:Wait()
				part = object:FindFirstChildWhichIsA("BasePart")
			until part ~= nil
		end

		local player = Replication.getPlayerFromBodyPart(part)
		if not player then return end
		local entry = Replication.getEntry(player)
		if not entry then return end

		local connectionGroup, throttle = {}, false
		connectionGroup.descendantAdded = object.DescendantAdded:Connect(function(descendant)
			if not descendant:IsA("BasePart") then return end
			if flags.character_chams and not throttle then
				throttle = true
				characterChams(player, entry, object)
				throttle = false
			end
		end)
		connectionGroup.ancestryChanged = object.AncestryChanged:Connect(function(descendant, parent)
			if not parent or not object:IsDescendantOf(workspace) then
				for _, connection in connectionGroup do
					connection:Disconnect()
				end
				connectionGroup = nil
			end
		end)

		task.delay(0.25, characterChams, player, entry, object)
	end)
end)


library.arrows = {}
local function rot2d(v, a)
	a = rad(a)
	local x = v.x * cos(a) - v.y * sin(a)
	local y = v.x * sin(a) + v.y * cos(a)
	return vec2(x, y)
end

local function getRelative(pos, rootP)

	local camP = camera.CFrame.Position
	local relative = cf(vec3(rootP.X, camP.Y, rootP.Z), camP):PointToObjectSpace(pos)

	return vec2(relative.X, relative.Z)
end

local function relToCenter(v)

	return camera.ViewportSize/2 - v

end

local function newArrow(color)
	local tri = Drawing.new("Triangle")
	tri.Visible = false
	tri.Filled = true
	tri.Thickness = 1
	tri.Transparency = 1
	tri.Color = color
	return tri
end


players.PlayerRemoving:Connect(function(player)
	if library.arrows[player] then
		library.arrows[player]:Destroy()
		library.arrows[player] = nil
	end
end)

function clampToScreen(pos)
	local viewport = camera.ViewportSize
	return Vector2.new(clamp(pos.X, 45, viewport.X - 45), clamp(pos.Y, 45, viewport.Y - 45))
end

function normalizeAngle(a)
	a = (a + 180) % 360
	if a < 0 then a += 360 end
	return a - 180
end
-- YOUR MATH FUNCTIONS
local function GetRelative(pos, rootP)
    local camCF = camera.CFrame
    local relative = camCF:PointToObjectSpace(pos)
    return vec2(relative.X, relative.Z)
end

local function RelativeToCenter(v)
    -- This maps the 2D vector to the screen center
    return camera.ViewportSize / 2 - v
end

local function RotateVect(v, a)
    local a = rad(a)
    local x = v.x * cos(a) - v.y * sin(a)
    local y = v.x * sin(a) + v.y * cos(a)
    return vec2(x, y)
end

local function AntiA(v)
    return vec2(floor(v.x), floor(v.y))
end

-- YOUR DRAW FUNCTION INTEGRATED
local function drawArrow(player, isActive, worldPos)
    if not isActive or not flags.oof_arrows then
        local a = library.arrows[player]
        if a then a.Visible = false end
        return
    end

    local arrow = library.arrows[player]
    if not arrow then
        arrow = Drawing.new("Triangle")
        arrow.Visible = false
        arrow.Filled = true
        arrow.Thickness = 1
        library.arrows[player] = arrow
    end

    local _, onScreen = camera:WorldToViewportPoint(worldPos)
    if onScreen then
        arrow.Visible = false
        return
    end

    -- 1. Get Relative
    local rel = GetRelative(worldPos, camera.Focus.Position)
    local direction = -rel.unit
    
    -- 2. Setup Dimensions (From your flags)
    local size = flags.oof_arrows_size or 16
    local offset = flags.oof_arrows_offset or 80
    local sideLength = size / 2

	if flags.oof_arrows_dynamic_offset then
		offset += clamp((camera.Focus.Position - worldPos).Magnitude / 500, 0, 300)
	end

    -- 3. Calculate Points using YOUR RotateVect
    local base  = direction * offset
    local baseL = base + RotateVect(direction, 90) * sideLength
    local baseR = base + RotateVect(direction, -90) * sideLength
    local tip   = direction * (offset + size)

    -- 4. Apply RelativeToCenter and AntiA (Your exact request)
    arrow.PointA = AntiA(RelativeToCenter(baseL))
    arrow.PointB = AntiA(RelativeToCenter(baseR))
    arrow.PointC = AntiA(RelativeToCenter(tip))

    -- Properties
    arrow.Color = flags.oof_arrows_color.Color
    arrow.Transparency = flags.oof_arrows_color.Transparency
    arrow.Visible = true
end


local entries, scan, lastPlayerCount = {}, 0, 0
function update_esp(dt)
pcall(function()
    if not chamsContainer or not chamsContainer.Parent then return end
    for _, highlight in chamsContainer:GetChildren() do
        if not highlight:IsA("Highlight") then continue end
        if not highlight.Adornee or not highlight.Adornee:IsDescendantOf(library.playersFolder) then
            pcall(game.Destroy, highlight)
        end
    end
end)
	if (tick() - scan) >= 2 or #players:GetPlayers() ~= lastPlayerCount then
		lastPlayerCount = #players:GetPlayers()
		scan = tick()
		entries = {}
pcall(function()
    if not Replication or not Replication.operateOnAllEntries then return end
    Replication.operateOnAllEntries(function(player, entry)
        if player and entry then
            entries[player] = entry
        end
    end)
end)
	end
	if flags.localesp and library.thirdPerson then
		local boxSize, pos = vec3(2,4,1), vec3()
		pcall(function() boxSize = library.char:GetExtentsSize() pos = library.localPos or pos end)
		local charInterface = library.modules.CharacterInterface
		local charObject = charInterface.getCharacterObject()
		if charObject then
			task.spawn(esp.render, esp, dt, lp, pos, boxSize + vec3(0,0.5,0), charObject:getHealth())
		end
	else 
		task.spawn(esp.hide, esp, lp)
	end
	local t = flags.enemy_animated and 0.5 + 0.5 * math.cos(elapsed_ticks / 12) or 0
	task.spawn(render_chams, lp, library.localChar, flags.self_chams, flags.self_primary_color.Color:Lerp(flags.self_secondary_color.Color, t), flags.chams_self_material)
	task.spawn(function()
		for player, entry in entries do
			if entry._player == lp then 
				continue
			end
			local team = entry._player.Team
			local char = entry:getThirdPersonObject() and entry:getThirdPersonObject():getCharacterHash()
			if not char then 
				if library.arrows[player] then
					library.arrows[player].Visible = false
				end
				task.spawn(esp.hide, esp, entry._player) 
				continue 
			end

			local localTeam = lp.Team

			local isActive, isEnemy = flags.masterswitch, true
			local isEnemy = entry:isEnemy()
			if flags.onlyenemy and isActive then
				isActive = isEnemy
			end

			local charInstance = entry:getThirdPersonObject():getCharacterModel()
			local pos = char.Torso.Position

			if flags.oof_arrows and entry._alive and pos ~= vec3() and entry:isAlive() then
				drawArrow(player, isActive, pos)
			else
				if library.arrows[player] then
					library.arrows[player].Visible = false
				end
			end

			if isActive and entry._alive and pos ~= vec3() and entry:isAlive() and charInstance:IsDescendantOf(workspace) then
				local boxSize = charInstance:GetExtentsSize()
				task.spawn(esp.render, esp, dt, entry._player, pos, boxSize + vec3(0,0.5,0), entry._healthstate.healtick0 > 0 and entry._healthstate.health0 or (entry:isAlive() and 100 or 0))
			else
				task.spawn(esp.hide, esp, entry._player)
			end

			local isActive = flags.enemy_chams
			if flags.enemy_only and isActive then
				isActive = isEnemy
			end


			local t = flags.enemy_animated and 0.5 + 0.5 * math.cos(elapsed_ticks / 12) or 0
			local old = charInstance.Name
			task.spawn(render_chams, player, charInstance, isActive, flags.enemy_primary_color.Color:Lerp(flags.enemy_secondary_color.Color, t), flags.chams_enemy_material)
		end
	end)

end

players.PlayerRemoving:Connect(function(player)
	if library.arrows[player] then
		library.arrows[player]:Destroy()
		library.arrows[player] = nil
	end
end)

local global_shadows = lighting.GlobalShadows
local brightness = lighting.Brightness

local colorgrading = Instance.new("ColorGradingEffect")
local function update_render()
	if not colorcorrection.Parent then
		colorcorrection = Instance.new("ColorCorrectionEffect")
		colorcorrection.Name = "colorcorrectionPriv"
	end

	colorcorrection.Parent = workspace.CurrentCamera
	colorcorrection.TintColor = flags.world_color_correction.Color

	xpcall(function() sky.Parent = (flags.world_skybox and flags.world_skybox ~= 'off') and lighting or nil end, function() 
		sky = Instance.new("Sky")
		sky.Name = "skyboxPriv"
	end)
	xpcall(function() colorgrading.Parent = lighting colorgrading.TonemapperPreset = Enum.TonemapperPreset.Retro end, function() 
		colorgrading = Instance.new("ColorGradingEffect")
		colorgrading.Parent = lighting
	end)
	if flags.world_skybox ~= 'off' then
		for skyboxProp, skyboxVal in skyboxes[flags.world_skybox] do
			sky[skyboxProp] = skyboxVal
		end
	end

	if flags.time_of_day_enabled then
		if not savedTime then
			savedTime = lighting.ClockTime
		end
		lighting.ClockTime = flags.time_of_day_time
	elseif savedTime then
		lighting.ClockTime = savedTime
		savedTime = nil
	end

	local case = flags.world_nightmode
	if case == "fullbright" then
		lighting.GlobalShadows = false
		colorcorrection.Brightness = 0.1
		lighting.Brightness = 2.0
	elseif case == "nightmode" then
		lighting.GlobalShadows = global_shadows
		colorcorrection.Brightness = -0.1
		lighting.Brightness = 1.0
	else
		lighting.GlobalShadows = global_shadows
		colorcorrection.Brightness = 0.0
		brightness = lighting.Brightness
	end
end

local function update_antiaim(dt)
	if flags.desired_breaker then
		thread(antiaim.desiredBreaker)
	end
	if flags.velocity_breaker then
		antiaim.desync:start_prediction()
	end
end

insert(cons, services.runService.Stepped:Connect(function()
	if not flags.velocity_breaker then return end
	antiaim.desync:end_prediction()
end))
local cfg, config_write_tick = library:get_config(), tick()
insert(cons, services.runService.RenderStepped:Connect(function(dt)
	globals.frametime = dt

	if tick() - config_write_tick >= 1 and cfg ~= library:get_config() and not mapped.configs[configName] then
		config_write_tick = tick()
		writefile(library.directory .. `/configs/{configName}.cfg`, library:get_config())
		cfg = library:get_config()
		if flags.autosave_notification then
			createNotification({text = "autosaving config..."})
		end
		--socket:Send("0x321655Dead")
	end


	local lua_len = 0
	for k in loaded_luas do
		lua_len += 1
	end
	lua:change_visibility(lua_len > 0)
	elapsed_ticks += dt * 60

	-- spawn new feature threads
	thread(update_render)
	thread(update_antiaim)
end))

services.runService:BindToRenderStep("camera", Enum.RenderPriority.Last.Value + 1, function()
	thread(update_esp)
end)


task.spawn(function()

	local userIdList, customIconList, tracked_players = {}, {}, {}

	local function connect()
		local success, ws = pcall(function()
			return WebSocket.connect("wss://seraph.wtf/ws")
		end)
		if success and ws then
			return ws
		else
			createNotification({text = "Failed to connect to Websocket, retrying in 1 second..."})
			task.wait(1)
			return connect()
		end
	end


	local OnClose = Instance.new("BindableEvent")

	local OnMessage = Instance.new("BindableEvent")

	task.spawn(function()
		task.wait(2)
		local webSocket = connect()
		webSocket.OnClose:Connect(function(...)
			OnClose:Fire(...)
		end)
		webSocket.OnMessage:Connect(function(...)
			OnMessage:Fire(...)
		end)
	end)

	OnClose.Event:Connect(function(code, reason)
		createNotification({text = "Websocket closed!"})
		task.wait(.1)
		createNotification({text = "Attempting to reconnect in 2 seconds..."})
		task.delay(2, function()
			webSocket = connect() --WebSocket.connect("wss://ws.seraph.wtf:1000")
			webSocket.OnClose:Connect(function(...)
				OnClose:Fire(...)
			end)
			webSocket.OnMessage:Connect(function(...)
				OnMessage:Fire(...)
			end)
			createNotification({text = "Reconnected to Websocket!"})
		end)
	end)

	task.spawn(function()

		function addCharacterStuff(char, which)
			if not char:FindFirstChild("seraph fiery horns") and which == "fieryHorns" then
				local fiery = game:GetObjects('rbxassetid://1744060292')[1]:Clone() 
				fiery.Handle.Fire.Color,fiery.Handle.Fire.SecondaryColor = rgb(151, 125, 214), rgb(121, 96, 180) 
				fiery.Name = "seraph fiery horns" 
				fiery.Parent = workspace
				fiery.Parent = char
				local weld = Instance.new("Weld")
				weld.Part1, weld.Part0 = char:FindFirstChild("Head"), fiery.Handle
				weld.C0,weld.C1 = cf(0, -0.665, -0),cf(0, 0.57, 0)
				weld.Parent = fiery.Handle
			end

			if which == "headless" then
				pcall(function()
					local head = char:FindFirstChild("Head")
					if head:IsA("MeshPart") then
						head.MeshId = "rbxassetid://134082579"
						head.TextureID = ""
					end
					local mesh = head:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh")
					mesh.MeshType = Enum.MeshType.Head
					mesh.Scale = vec3(0, 0, 0)
					mesh.Name = "seraph headless"
					mesh.Parent = head
				end)
			end
		end

		function library:send_seraph_chat(message, username, hexColor)
			local channel = services.textChatService.TextChannels:FindFirstChild("Global") or services.textChatService.TextChannels:FindFirstChild("RBXSystem")
			if not channel then channel = services.textChatService.TextChannels:FindFirstChildOfClass("TextChannel") end
			channel:DisplaySystemMessage(
				`<font face="Arial" color='{rgbstr(themes.preset.button_alt)}'>[seraph.wtf]</font> <font color='{hexColor}' face="Arial">{username}:</font> {message}` -- <font color='{hexColor}'>{username}</font><font color='rgb(155,155,155)'>:</font> <font color='rgb(233,233,233)'>{message}</font>
			)
		end
		
		for _, gui in services.coreGui:GetDescendants() do
			if gui:IsA("TextBox") and gui:FindFirstAncestor("ExperienceChat") then
				local selfCons = {}
				selfCon = gui.FocusLost:Connect(function(...)
					local textBox = ...
					if gui.Text:sub(1,1) == "@" then
						local ogText = gui.Text
						gui.Text = ""
						return webSocket:Send(http_service:JSONEncode({
							type = "addChatMessage",
							name = seraphAcc.username or seraphAcc.name or lp.Name,
							message = ogText:sub(2),
							hexColor = seraphAcc.hexColor or "#FFF"
						}))

					end
					for _, con in selfCons do
						if con == selfCon then continue end
						con:Defer(...)
					end
				end)
				--print(#getconnections(gui.FocusLost))

				for _, connection in getconnections(gui.FocusLost) do
					if pcall(function() return tostring(connection.Function) end) and connection.Function ~= nil then
						print("Connection found")
					else
						table.insert(selfCons, connection)
						connection:Disable()
						connection:Enable()
					end
				end
			end
		end
	--[[
		services.textChatService.SendingMessage:Connect(function(textChatMessage)
			if textChatMessage and textChatMessage.Text:sub(1,1) == "@" then
				local ogText = textChatMessage.Text
				textChatMessage.Text = "/e "
				textChatMessage.TextChannel = nil
				return webSocket:Send(http_service:JSONEncode({
					type = "addChatMessage",
					name = seraphAcc.username or seraphAcc.name or lp.Name,
					message = ogText:sub(2),
					hexColor = seraphAcc.hexColor or "#FFF"
				}))
			end
		end)
	--[[
		for _,v in services.textChatService.TextChannels:GetChildren() do
			local wrapper__ = coroutine.wrap(function()
				local old; old = hookfunction(v.SendAsync, function(self, message, ...)
					if message and message:sub(1,1) == "@" then
						return webSocket:Send(http_service:JSONEncode({
							type = "addChatMessage",
							name = seraphAcc.username or seraphAcc.name or lp.Name,
							message = message:sub(2),
							hexColor = seraphAcc.hexColor or "#FFF"
						}))
					end
					return old(self, message, ...)
				end)
			end)
			pcall(wrapper__)
		end
	]]
		OnMessage.Event:Connect(function(message)
			local data = http_service:JSONDecode(message)
			if not data then return end
			if not data.type then return end
			if data.type == "connect" then
				local userId = tonumber(data.userId)
				if not table.find(userIdList, userId) then
					insert(userIdList, userId)
				end
				tracked_players[data.userId] = tick()
			elseif data.type == "setCustomIcon" then
				local userId = tonumber(data.userId)
				if not table.find(customIconList, userId) then
					insert(customIconList, userId)
				end
			elseif data.type == "fieryHorns" or data.type == "headless" then
				local userId = tonumber(data.userId)
				local plr = players:GetPlayerByUserId(userId)
				if plr and plr.Character then
					thread(addCharacterStuff, plr.Character, data.type)
				end
			elseif data.type == "addChatMessage" then
				print("hi")
				library:send_seraph_chat(data.message, data.name, data.hexColor)
			end
		end)

	end)

	function checkPlayer(player)
		if table.find(userIdList, player.UserId) then
			local playerList = coregui:FindFirstChild("PlayerList")
			if not playerList then return end 
			local pChild = nil
			for _, obj in playerList:GetDescendants() do
				if obj.Name:match(tostring(player.UserId)) then
					pChild = obj
					--print(obj:GetFullName())
				end
			end
			if not pChild then
				return --print('failed')
			end

			local icon = pChild:FindFirstChild(`PlayerIcon`, true)
			if icon:IsA("TextLabel") then 
				icon.Text = ""
			else 
				icon.Image = ""
			end

			local img = icon:FindFirstChildOfClass("ImageLabel") or Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.new(1,10,1,10)
			img.Position = UDim2.new(0,-5,0,-5)
			img.Image = getcustomasset("seraph/imgs/atom.png")
			img.Parent = icon

			local char = player.Character
			if not char then
				return
			end

			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then
				return
			end

			local verified = utf8.char(0xE000)
			if not hum.DisplayName:match(verified) then
				hum.DisplayName = `{verified} {hum.DisplayName}`
			end
		end
	end
	task.spawn(function()
		for _, player in services.Players:GetPlayers() do
			task.spawn(checkPlayer, player)
		end
		insert(cons, services.players.PlayerAdded:Connect(checkPlayer))
	end)
end)


function fixDesync(dt)
	for _, player in players:GetPlayers() do
		if player == lp then continue end
		local char = player.Character
		if not char then continue end
		local rootpart = char:FindFirstChild("HumanoidRootPart")
		if not rootpart then continue end
		sethiddenproperty(rootpart, "NetworkIsSleeping", false)
		sethiddenproperty(rootpart, "PhysicsRepRootPart", nil)
	end
end

task.spawn(function()
	local smoothedFov = camera.FieldOfView
	camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
		if zoomKey.active then
			if not oldFov then
				oldFov = camera.FieldOfView
			end
			camera.FieldOfView = smoothedFov
		else
			smoothedFov = camera.FieldOfView
			if oldFov then
				camera.FieldOfView = oldFov
				oldFov = nil
			end
			if forceFOV.active then
				camera.FieldOfView = flags.real_fov
			end
		end
	end)
	local elapseCheck = 0
	cons[#cons + 1] = services.runService.Stepped:Connect(function(_, dt)
		local scopeGui = lp.PlayerGui:FindFirstChild("UnscaledScreenGui")
		if scopeGui then scopeGui.Enabled = not flags.viewmodel_noscope end
		if zoomKey.active then
			smoothedFov = math.lerp(smoothedFov, flags.zoom_fov, correctAlpha(0.4, dt))
			if not oldFov then
				oldFov = camera.FieldOfView
			end
			camera.FieldOfView = smoothedFov
		else
			smoothedFov = camera.FieldOfView
			if oldFov then
				camera.FieldOfView = oldFov
				oldFov = nil
			end
		end

		if forceFOV.active then
			camera.FieldOfView = flags.real_fov
		end

		if flags.desyncresolver then
			thread(fixDesync, dt)
		end

		elapseCheck += dt
		if elapseCheck >= 1 then
			elapseCheck = 0	
			for _, player in services.Players:GetPlayers() do
				checkPlayer(player)
			end
		end
	end)

	function listenChange(obj, prop, func)
		return obj:GetPropertyChangedSignal(prop):Connect(func)
	end

	function thirdPersonCheck()
		if thirdPerson.active then
			if not thirdPersonArray then
				thirdPersonArray = {}
				for _, prop in {'CameraMaxZoomDistance','CameraMinZoomDistance','CameraMode'} do
					thirdPersonArray[prop] = lp[prop]
				end
				thirdPersonArray.cameraMode = listenChange(lp,"CameraMode",function() lp.CameraMode = Enum.CameraMode.Classic end)
				thirdPersonArray.cameraMaxZoomDistance = listenChange(lp,"CameraMaxZoomDistance",function() lp.CameraMaxZoomDistance = flags.thirdpersonDistance end)
				thirdPersonArray.cameraMinZoomDistance = listenChange(lp,"CameraMinZoomDistance",function() lp.CameraMinZoomDistance = flags.thirdpersonDistance end)
				lp.CameraMaxZoomDistance = flags.thirdpersonDistance
				lp.CameraMinZoomDistance = flags.thirdpersonDistance
				lp.CameraMode = Enum.CameraMode.Classic

				local distance = flags.thirdpersonDistance
				local height = 2
				local rotX, rotY = 0, 0

				thirdPersonArray.inputChanged = uis.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement then
						local sens = uis.MouseDeltaSensitivity
						rotX = rotX - input.Delta.X * sens
						rotY = math.clamp(rotY - input.Delta.Y * sens, -80, 80)
					end
				end)

				thirdPersonArray.MouseBehavior = uis.MouseBehavior
				uis.MouseBehavior = Enum.MouseBehavior.Default
				camera.CameraType = Enum.CameraType.Scriptable
				--mouse2press()
				run:BindToRenderStep("camFix", Enum.RenderPriority.Camera.Value + 1, function()
					local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
					if not root then return end
					local look = CFrame.Angles(0, math.rad(rotX), 0) * CFrame.Angles(math.rad(rotY), 0, 0)
					local targetPos = root.Position
					local camPos = targetPos - look.LookVector * distance + Vector3.new(0, height, 0)

					camera.CFrame = CFrame.new(camPos, targetPos)
					uis.MouseBehavior = Enum.MouseBehavior.LockCenter
				end)
				thirdPersonArray.mouseBehavior = listenChange(uis, "MouseBehavior", function()
					uis.MouseBehavior = Enum.MouseBehavior.LockCenter
				end)
				uis.MouseBehavior = Enum.MouseBehavior.Default
			end
		elseif thirdPersonArray then
			--mouse2release()
			for i,v in thirdPersonArray do
				pcall(function()
					v:Disconnect()
				end)
			end
			for i,v in thirdPersonArray do
				pcall(function()
					lp[i] = v
				end)
			end
			uis.MouseBehavior = thirdPersonArray.MouseBehavior
			camera.CameraType = Enum.CameraType.Custom
			run:UnbindFromRenderStep("camFix")
			uis.MouseBehavior = thirdPersonArray.MouseBehavior
			thirdPersonArray = nil
		end
	end

	if game.GameId then
		thirdPersonCheck = function()
			local act = thirdPerson.active
			library.thirdPerson = act
			--[[if act then
				if not thirdPersonArray then
					thirdPersonArray = {}

					--mouse2press()
					run:BindToRenderStep("camFix", Enum.RenderPriority.Camera.Value + 1, function()
						--camera.CFrame *= CFrame.new(0,flags.thirdpersonDistance/6,flags.thirdpersonDistance)
					end)

					local db = false
					thirdPersonArray.camera = listenChange(camera, "CFrame", function()
						if db then return end
						db = true
						local old = camera.Focus.Position
						pcall(function() old = library.char.HumanoidRootPart.CFrame.Position end)
						camera.CFrame *= CFrame.new(0,flags.thirdpersonDistance/32,flags.thirdpersonDistance)
						db = false
					end)
				end
			elseif thirdPersonArray then
				--mouse2release()
				for i,v in thirdPersonArray do
					pcall(function()
						v:Disconnect()
					end)
				end
				run:UnbindFromRenderStep("camFix")
				thirdPersonArray = nil
			end]]
		end
	end

	function checkTearParts()
		if #tearParts == 0 then return end
		for model, parts in tearParts do
			if not model or not model:IsDescendantOf(game) then
				for _, part in parts do
					part:Destroy()
				end
				table.clear(parts)
				tearParts[model] = nil
			end
		end
	end

	function createWidgetDrag(frame, frameName)
		local n = 'seraph/configs/'..frameName..'.vector'
		library:draggify(frame)
		pcall(function()
			local savedFramePos = http_service:JSONDecode(readfile(n))
			local translated = Vector2.new(savedFramePos.X, savedFramePos.Y)

			frame.Position = UDim2.new(0,translated.X,0,translated.Y)
		end)

		local check; check = function() 
			task.delay(1, function()
				writefile(n, http_service:JSONEncode({
					X = frame.Position.X.Offset,
					Y = frame.Position.Y.Offset
				}))
				check()
			end) 
		end 
		task.delay(1, check)
	end

	task.spawn(function()

		local lol = Instance.new("ScreenGui")
		local frame = Instance.new("Frame")
		local bar = Instance.new("Frame")
		local gradient = Instance.new("UIGradient")
		local username = Instance.new("TextLabel")
		local pad = Instance.new("UIPadding")
		local UICorner = Instance.new("UICorner")
		local label = Instance.new("ImageLabel")
		local UICorner_2 = Instance.new("UICorner")
		local layout = Instance.new("UIListLayout")


		lol.Name = "lol"
		lol.Parent = gethui()
		lol.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		frame.Name = "frame"
		frame.Parent = lol
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = Color3.fromRGB(21, 21, 20)
		frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		frame.BorderSizePixel = 0
		frame.Position = UDim2.new(0.150000006, 0, 0.150000006, 0)
		frame.Size = UDim2.new(0, 150, 0, 15)
		frame.AutomaticSize = Enum.AutomaticSize.Y

		bar.Name = "bar"
		bar.Parent = frame
		bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.Position = UDim2.new(0, 1, 0, 1)
		bar.Size = UDim2.new(1, -2, 0, 2)

		gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, themes.preset.button), ColorSequenceKeypoint.new(0.5, themes.preset.button_alt), ColorSequenceKeypoint.new(1.00, themes.preset.button)}
		gradient.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0.00, 1.00), NumberSequenceKeypoint.new(0.50, 0.00), NumberSequenceKeypoint.new(1.00, 1.00)}
		gradient.Name = "gradient"
		gradient.Parent = bar
		library.gradientChanged:Connect(function()
			gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, themes.preset.button), ColorSequenceKeypoint.new(0.5, themes.preset.button_alt), ColorSequenceKeypoint.new(1.00, themes.preset.button)}
		end)

		local scale = Instance.new("UIScale")
		scale.Name = "scale"
		scale.Scale = 1
		scale.Parent = frame

		local outer = Instance.new("UIStroke")
		outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outer.LineJoinMode = Enum.LineJoinMode.Miter
		outer.Name = "outer"
		outer.Color = Color3.fromRGB(39, 40, 41)
		outer.ZIndex = 5
		outer.Thickness = 3
		outer.Parent = frame

		local outeroutline = Instance.new("UIStroke")
		outeroutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outeroutline.LineJoinMode = Enum.LineJoinMode.Miter
		outeroutline.Name = "outeroutline"
		outeroutline.Color = Color3.fromRGB(60, 65, 60)
		outeroutline.ZIndex = 4
		outeroutline.Thickness = 4
		outeroutline.Parent = frame

		local inner = Instance.new("UIStroke")
		inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		inner.LineJoinMode = Enum.LineJoinMode.Round
		inner.Name = "inner"
		inner.Color = Color3.fromRGB(60, 65, 60)
		inner.ZIndex = 4
		inner.BorderStrokePosition = Enum.BorderStrokePosition.Inner
		inner.Parent = frame

		local outline = Instance.new("UIStroke")
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outline.LineJoinMode = Enum.LineJoinMode.Miter
		outline.Name = "outline"
		outline.Color = Color3.fromRGB(2, 3, 3)
		outline.ZIndex = 4
		outline.Thickness = 5
		outline.Parent = frame

		username.Name = "username"
		username.Parent = frame
		username.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		username.BackgroundTransparency = 1.000
		username.BorderColor3 = Color3.fromRGB(0, 0, 0)
		username.BorderSizePixel = 0
		username.LayoutOrder = 1
		username.Size = UDim2.new(0, 0, 0, 16)
		username.AutomaticSize = Enum.AutomaticSize.X
		username.Font = Enum.Font.Code
		username.Text = "%s"
		username.TextColor3 = Color3.fromRGB(255, 255, 255)
		username.TextSize = 14.000

		local holder = username:Clone()
		holder.Text = ""
		holder.Parent = frame


		pad.Name = "pad"
		pad.Parent = frame
		pad.PaddingBottom = UDim.new(0, 5)
		pad.PaddingLeft = UDim.new(0, 5)
		pad.PaddingRight = UDim.new(0, 5)

		UICorner.Parent = frame

		label.Name = "label"
		label.Parent = frame
		label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		label.BorderColor3 = Color3.fromRGB(0, 0, 0)
		label.BorderSizePixel = 0
		label.Size = UDim2.new(0, 35, 0, 35)
		label.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"

		UICorner_2.CornerRadius = UDim.new(0, 4)
		UICorner_2.Parent = label

		layout.Name = "layout"
		layout.Parent = frame
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 5)

		local layout = layout:Clone()
		layout.Name = "layout"
		layout.Parent = holder
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom 
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 5)

		holder.AutomaticSize = Enum.AutomaticSize.XY


		label.Parent = holder
		username.Parent = holder

		function formatUnixDate(ts)
			local day = tonumber(os.date("%d", ts))
			local month = os.date("%B", ts)
			local year = os.date("%Y", ts)

			local suffix = "th"
			if day % 10 == 1 and day ~= 11 then suffix = "st"
			elseif day % 10 == 2 and day ~= 12 then suffix = "nd"
			elseif day % 10 == 3 and day ~= 13 then suffix = "rd" end

			return string.format("%s %d%s, %s", month, day, suffix, year)
		end

		
		main_frame = frame

		if seraphAcc.icon then
			label.Image = "rbxassetid://76229822465645"
			local expires = username:Clone()
			expires.Name = "expires"
			expires.LayoutOrder = 2
			print(seraphAcc.expires)
			expires.Text = string.rep(" ", 1) .. "expires on ".. formatUnixDate(tonumber(seraphAcc.expires))
			expires.Parent = label.Parent
			username.TextColor3 = Color3.fromHex(seraphAcc.hexColor)
			username.RichText = true
			username.Text = string.rep(" ", 1) .. seraphAcc.username.."<font color=\"rgb(255,255,255)\">,</font>"
			insert(cons, holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				frame.Size = UDim2.new(0, math.max(holder.AbsoluteSize.X + 15, 5), 0, frame.Size.Y.Offset)
			end))
			task.delay(0.1, function()
				frame.Size = UDim2.new(0, math.max(holder.AbsoluteSize.X + 15, 5), 0, frame.Size.Y.Offset)
			end)
		end

		createWidgetDrag(frame, "account_info")
	end)

	task.spawn(function()
		local bind_list = Instance.new("ScreenGui")
		bind_list.Name = "bind_list"
		bind_list.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		bind_list.Parent = gethui()


		local frame = Instance.new("Frame")
		frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Name = "frame"
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		frame.Size = UDim2.new(0, 50, 0, 15)
		frame.BorderSizePixel = 0
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.BackgroundColor3 = Color3.fromRGB(21, 21, 20)
		frame.Parent = bind_list

		local scale = Instance.new("UIScale")
		scale.Name = "scale"
		scale.Scale = 1
		scale.Parent = frame

		local outer = Instance.new("UIStroke")
		outer.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outer.LineJoinMode = Enum.LineJoinMode.Miter
		outer.Name = "outer"
		outer.Color = Color3.fromRGB(39, 40, 41)
		outer.ZIndex = 5
		outer.Thickness = 3
		outer.Parent = frame

		local outeroutline = Instance.new("UIStroke")
		outeroutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outeroutline.LineJoinMode = Enum.LineJoinMode.Miter
		outeroutline.Name = "outeroutline"
		outeroutline.Color = Color3.fromRGB(60, 65, 60)
		outeroutline.ZIndex = 4
		outeroutline.Thickness = 4
		outeroutline.Parent = frame

		local inner = Instance.new("UIStroke")
		inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		inner.LineJoinMode = Enum.LineJoinMode.Round
		inner.Name = "inner"
		inner.Color = Color3.fromRGB(60, 65, 60)
		inner.ZIndex = 4
		inner.BorderStrokePosition = Enum.BorderStrokePosition.Inner
		inner.Parent = frame

		local outline = Instance.new("UIStroke")
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outline.LineJoinMode = Enum.LineJoinMode.Miter
		outline.Name = "outline"
		outline.Color = Color3.fromRGB(2, 3, 3)
		outline.ZIndex = 4
		outline.Thickness = 5
		outline.Parent = frame

		local bar = Instance.new("Frame")
		bar.Name = "bar"
		bar.Position = UDim2.new(0, 1, 0, 1)
		bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
		bar.Size = UDim2.new(1, -2, 0, 2)
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		bar.Parent = frame

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, themes.preset.button), ColorSequenceKeypoint.new(0.5, themes.preset.button_alt), ColorSequenceKeypoint.new(1.00, themes.preset.button)}
		gradient.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1)
		}
		gradient.Name = "gradient"
		gradient.Parent = bar
		library.gradientChanged:Connect(function()
			gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, themes.preset.button), ColorSequenceKeypoint.new(0.5, themes.preset.button_alt), ColorSequenceKeypoint.new(1.00, themes.preset.button)}
		end)

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.Name = "layout"
		layout.Parent = frame

		local example = Instance.new("TextLabel")
		example.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		example.TextColor3 = Color3.fromRGB(255, 255, 255)
		example.BorderColor3 = Color3.fromRGB(0, 0, 0)
		example.Text = "[K] yoo"
		example.Name = "example"
		example.BackgroundTransparency = 1
		example.Size = UDim2.new(0, 0, 0, 16)
		example.BorderSizePixel = 0
		example.AutomaticSize = Enum.AutomaticSize.X
		example.TextSize = 14
		example.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		example.Parent = frame

		local pad = Instance.new("UIPadding")
		pad.Name = "pad"
		pad.PaddingBottom = UDim.new(0, 5)
		pad.PaddingRight = UDim.new(0, 5)
		pad.PaddingLeft = UDim.new(0, 5)
		pad.Parent = frame

		local UICorner = Instance.new("UICorner")
		UICorner.Parent = frame
		UICorner.CornerRadius = UDim.new(0, 4)

		bindList, bindExample, binds, bindScale = bind_list, example:Clone(), {}, scale
		example:Destroy()

		createWidgetDrag(frame, "bind_list")
	end)

	local elapseTime = tick()
	local renders = {
		keybinds = {
			off = function(dt)
				bindScale.Scale = 0.0
				for i, keybind in keybinds do
					local text = keybind.text
					text.Visible = false
				end
			end,
			widget = function(dt)
				local currentSize = 50
				local activeBinds = 0
				for i, keybind in keybinds do
					local text, mode, active = keybind.text, keybind.mode, keybind.active
					if not keybind.inset then keybind.inset = 0 end
					if active then
						activeBinds += 1
					end
					text.Visible = false

					local bindFrame = binds[keybind] or bindExample:Clone()
					binds[keybind] = bindFrame
					bindFrame.Visible = active
					bindFrame.TextXAlignment = Enum.TextXAlignment.Left
					bindFrame.TextTransparency = clamp(bindFrame.TextTransparency - (active and dt or -dt) * 10, 0, 1)
					bindFrame.TextStrokeTransparency = clamp(bindFrame.TextStrokeTransparency - (active and dt or -dt) * 10, 0, 0.5)
					bindFrame.Text = `[{keybind.key and keybind.key.Name or "-"}] {string.lower(keybind.display or keybind.name)} ({string.lower(mode)})`
					bindFrame.Parent = bindList.frame
					if (bindFrame.AbsoluteSize.X + 20) > currentSize and bindFrame.visible then
						currentSize = bindFrame.AbsoluteSize.X + 20
					end
				end
				bindScale.Scale = clamp(bindScale.Scale + (activeBinds > 0 and dt or -dt) * 15, 0, 1)
				bindList.frame.Size = UDim2.new(0, currentSize, 0, 15)
			end,
			crosshair = function(dt)
				bindScale.Scale = 0.0
				local inset = 0
				local center = workspace.CurrentCamera.ViewportSize / 2 + vec2(0, 150)
				for i, keybind in keybinds do
					local text, mode, active = keybind.text, keybind.mode, keybind.active
					if not keybind.inset then keybind.inset = 0 end
					text.Size = math.lerp(text.Size, active and 22 or 0, correctAlpha(0.15, dt))
					text.Transparency = math.clamp(text.Transparency + (active and dt or -dt) * 10, 0, 1)
					text.Center = true
					text.Text = string.lower(`{keybind.display or keybind.name} [{mode}]`)
					text.Outline = true
					text.OutlineColor = text.Color:Lerp(rgb(), 0.75)
					text.Color = themes.preset.button_alt:Lerp(themes.preset.button, 0.5 + 0.5 * math.cos((elapsed_ticks + i * 2) / 12))
					text.Position = center + vec2(0, inset)
					text.Visible = true
					keybind.inset = math.lerp(keybind.inset, active and text.TextBounds.Y + 2 or 0, correctAlpha(0.35, dt))

					inset += keybind.inset
				end
			end
		}
	}

	function updateNotifications(dt)
		for i, notifData in notifications do
			local notif = notifData.notif
			notifData.time -= dt
			local textContainer = notif.holder.textContainer
			local totalLength, count = 0, 0
			for _, v in textContainer:GetChildren() do
				if v:IsA("TextLabel") then
					totalLength += v.AbsoluteSize.X
					count += 1
				end
				continue
			end

			totalLength += 5 * count - 1
			notif.Size = notif.Size:lerp(UDim2.new(0,totalLength + 2,0,23), correctAlpha(0.45, dt))
			notif.loading.Size = UDim2.new(math.lerp(1, 0, 1 - (notifData.time / notifData.totalTime)), 0, 0, 1)
			if notifData.time <= 0 then
				--notif.Position = notif.Position:Lerp(UDim2.new(1.5, 0,1, -5 - (35 * (i - 1))), dt * 5)
				notif.Position = notif.Position:Lerp(UDim2.new(1, -5,1, 60), correctAlpha(0.35, dt))
				notif.scale.Scale = math.clamp(notif.scale.Scale - dt * 2, 0.0, 1.0)
				if notif.scale.Scale <= 0.05 then
					table.clear(notifData)
					notif:Destroy()
					table.remove(notifications, i)
					continue
				end
			else
				notif.Position = notif.Position:Lerp(UDim2.new(1, -5,1, -5 - (35 * ((#notifications - i)))), correctAlpha(0.35, dt))
				notif.scale.Scale = math.clamp(notif.scale.Scale + dt * 10, 0.0, 1.0)
			end
			notif.Parent = library.gui

		end
	end

	services.runService:BindToRenderStep("movement0x078DE4A", Enum.RenderPriority.Character.Value, function(dt)
		if tick() - elapseTime >= 1 and webSocket and webSocket.Send then
			elapseTime = tick()
			webSocket:Send(http_service:JSONEncode({
				type = "connect",
				userId = tostring(lp.UserId),
			}))
			if currentText == "development" then
				webSocket:Send(http_service:JSONEncode({
					type = "setCustomIcon",
					userId = tostring(lp.UserId),
				}))
			end

			task.delay(0.2, function()
				if flags.headless_flag then
					webSocket:Send(http_service:JSONEncode({
						type = "headless",
						userId = tostring(lp.UserId),
					}))
				end

				if flags.fiery_flag then
					webSocket:Send(http_service:JSONEncode({
						type = "fieryHorns",
						userId = tostring(lp.UserId),
					}))
				end
			end)
		end

		main_frame.Visible = flags.linked_discord_profile

		--sethiddenproperty(workspace,"SignalBehavior",Enum.SignalBehavior.Immediate)
		thread(thirdPersonCheck)
		thread(checkTearParts)

		if library.gui_visible then
			for _, depend in dependants do
				local element, check = depend[1], depend[2]
				local success = pcall(element.show_element, check())
				if not success then
					warn("Failed to update dependant element:", element.name, check(), success)
				end
				
			end
		end
		renders.keybinds[flags.keybinds_type](dt)

		thread(updateNotifications, dt);
	end)

	insert(cons, services.players.PlayerRemoving:Connect(function(player)
		if esp_frames[player] then
			esp_frames[player]:Destroy()
			esp_frames[player] = nil
		end
		local viewModel = viewport:FindFirstChild(player.Name)
		if viewModel then viewModel:Destroy() end
	end))

	if not rage.visible then
		--legit:open_tab()
	end
	task.spawn(function()
		window:set_title(`seraph<font color="{rgbstr(themes.preset.button_alt)}">.wtf</font> {build_str} | {configName}`)
		createNotification({
			text = `welcome to seraph, {lp.Name}!`,
		})
		task.wait(0.5)
		createNotification({
			text = "we hope you enjoy your time using seraph!",
		})
		task.wait(0.5)
		createNotification({
			text = "if you encounter any issues, or have any suggestions, then feel free to make a post in the community server",
		})
	end)


	unload_full = function()
		table.clear(notifications)
		services.runService:UnbindFromRenderStep("movement0x078DE4A")
		bindList:Destroy()
		chamsContainer:Destroy()
		sky:Destroy()
		bloom:Destroy()
		colorcorrection:Destroy()
		main_frame:Destroy()
	end

	task.spawn(function()
		local old = Instance.new("ImageLabel")
		old.Name = "old"
		old.Position = UDim2.new(0, 125, 0, 125)
		old.Size = UDim2.new(0, 200, 0, 160)
		old.BackgroundColor3 = Color3.new(1, 1, 1)
		old.BackgroundTransparency = 1
		old.BorderSizePixel = 0
		old.BorderColor3 = Color3.new(0, 0, 0)
		old.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		old.Parent = library.gui

		local scale = Instance.new("UIScale")
		scale.Name = "scale"
		scale.Scale = 1.0
		scale.Parent = old

		local new = Instance.new("ImageLabel")
		new.Name = "new"
		new.Size = UDim2.new(1, 0, 1, 0)
		new.BackgroundColor3 = Color3.new(1, 1, 1)
		new.BackgroundTransparency = 1
		new.BorderSizePixel = 0
		new.BorderColor3 = Color3.new(0, 0, 0)
		new.Visible = true
		new.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		new.Parent = old

		library:draggify(old)

		local pos = old.Position

		old.Position = UDim2.new(0, 1, 0, 1)
		scale.Scale = 0.01

		for i = 1, 150 do
			local frame_translation = string.format("frame_%03d_delay-0.02s.png", i-1)
			local image = getcustomasset(`seraph/gifs/{frame_translation}`)
			new.Image = image
			old.Image = image
			task.wait()
		end

		scale.Scale = 1
		old.Position = pos

		pcall(function()
			local savedFramePos = http_service:JSONDecode(readfile('seraph/configs/spinning.vector'))
			local translated = Vector2.new(savedFramePos.X, savedFramePos.Y)

			old.Position = UDim2.new(0,translated.X,0,translated.Y)
		end)


		new.Image = ""
		old.Image = ""

		while task.wait() do
			if library.unloaded then break end
			if flags.spinning_logo then
				scale.Scale = flags.logosize / 100
				for i = 1, 150 do
					local frame_translation = string.format("frame_%03d_delay-0.02s.png", i-1)
					local image = getcustomasset(`seraph/gifs/{frame_translation}`)

					if i > 1 then
						local frame_translation = string.format("frame_%03d_delay-0.02s.png", i-2)
						local image = getcustomasset(`seraph/gifs/{frame_translation}`)
						new.Image = image
					end

					old.Visible = flags.spinning_logo
					old.Image = image
					new.ImageTransparency, old.ImageTransparency = 0.0, 0.0
					for i = 1, 2 do new.ImageTransparency,old.ImageTransparency = i / 2, 0; task.wait() end
				end
				writefile('seraph/configs/spinning.vector', http_service:JSONEncode({
					X = old.Position.X.Offset,
					Y = old.Position.Y.Offset
				}))
			else
				scale.Scale = 0.0
			end
		end
	end)

end)


pcall(function()
	local baseConfig = table.clone(flags)
	library.empty_flags = baseConfig
	local cfgdata = readfile(library.directory .. `/configs/{configName}.cfg`)
	if cfgdata and typeof(cfgdata) == 'string' then
		task.delay(1/30, function()
			library:load_config(cfgdata)
		end)
	end
end)

--"