--[[
	NovaUI - Modern Roblox UI Library
	================================================================
	Sebuah library UI dua-panel (sidebar + content panel) dengan tema
	dark modern, aksen merah, animasi halus (TweenService), dan
	komponen lengkap: Button, Toggle, Slider, Dropdown (Single/Multi),
	Textbox, ColorPicker, Keybind, Label, Section, Paragraph,
	Notification, Dialog, Tab, Window.

	Struktur file (cari header "SECTION:" untuk navigasi cepat):
		SECTION: SERVICES & CONSTANTS
		SECTION: THEME
		SECTION: UTILITIES (Create, Tween, Corner/Stroke/Shadow, Ripple, Drag, Resize)
		SECTION: ICONS
		SECTION: CONFIG (save/load, guarded utk lingkungan non-executor)
		SECTION: NOTIFICATION
		SECTION: DIALOG
		SECTION: COMPONENTS (Button, Toggle, Slider, Dropdown, Textbox,
		                     ColorPicker, Keybind, Label, Section, Paragraph)
		SECTION: TAB
		SECTION: WINDOW (sidebar, topbar, search, drag/resize/minimize)
		SECTION: PUBLIC API

	Pemakaian dasar:
		local NovaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/kjbookk-prog/Novalaunch/refs/heads/main/nove.lua"))()
		local Window = NovaUI:CreateWindow({
			Title = "Oxyo",
			SubTitle = "Premium Hub",
			Theme = "Default",
		})
		local Tab = Window:CreateTab({ Title = "Evade", Subtitle = "Survive Nextbots", Icon = "gamepad" })
		local Section = Tab:CreateSection("General")
		Section:CreateToggle({ Title = "Anti AFK", Default = false, Callback = function(v) end })

	================================================================
]]

local NovaUI = {}
NovaUI.__index = NovaUI
NovaUI._version = "1.0.0"

--====================================================================
-- SECTION: SERVICES & CONSTANTS
--====================================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local TextService      = game:GetService("TextService")
local GuiService       = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local EASE = Enum.EasingStyle.Quint
local EASE_OUT = Enum.EasingDirection.Out

--====================================================================
-- SECTION: THEME
--====================================================================
-- Palet warna terpusat. Semua komponen membaca dari sini sehingga
-- theme baru bisa ditambahkan cukup dengan menambah entry baru.
NovaUI.Themes = {
	Default = {
		Background      = Color3.fromRGB(13, 13, 15),
		PanelPrimary     = Color3.fromRGB(18, 18, 21),
		PanelSecondary   = Color3.fromRGB(24, 24, 28),
		PanelTertiary    = Color3.fromRGB(31, 31, 36),
		PanelHover       = Color3.fromRGB(38, 38, 44),
		Accent           = Color3.fromRGB(224, 58, 68),
		AccentHover      = Color3.fromRGB(240, 74, 84),
		AccentDim        = Color3.fromRGB(70, 28, 32),
		AccentGradient   = Color3.fromRGB(255, 90, 90),
		Stroke           = Color3.fromRGB(42, 42, 48),
		StrokeLight      = Color3.fromRGB(55, 55, 62),
		TextPrimary      = Color3.fromRGB(238, 238, 242),
		TextSecondary    = Color3.fromRGB(150, 150, 160),
		TextTertiary     = Color3.fromRGB(96, 96, 106),
		Success          = Color3.fromRGB(64, 200, 122),
		Warning          = Color3.fromRGB(235, 180, 64),
		Error            = Color3.fromRGB(230, 70, 70),
		Font             = Enum.Font.GothamMedium,
		FontBold         = Enum.Font.GothamBold,
		FontSemibold     = Enum.Font.GothamSemibold,
	},
}

--====================================================================
-- SECTION: UTILITIES
--====================================================================
local Util = {}

-- Factory pembuat instance ringkas ala "declarative" -> mengurangi duplikasi
function Util.Create(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do
		if prop ~= "Parent" then
			inst[prop] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Util.Tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

function Util.QuickTween(obj, props, duration, style, direction)
	return Util.Tween(obj, TweenInfo.new(duration or 0.22, style or EASE, direction or EASE_OUT), props)
end

function Util.Corner(parent, radius)
	return Util.Create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

function Util.Stroke(parent, color, thickness, transparency)
	return Util.Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Util.Padding(parent, all, l, r, t, b)
	return Util.Create("UIPadding", {
		PaddingLeft = UDim.new(0, l or all),
		PaddingRight = UDim.new(0, r or all),
		PaddingTop = UDim.new(0, t or all),
		PaddingBottom = UDim.new(0, b or all),
		Parent = parent,
	})
end

function Util.Gradient(parent, colorSequence, rotation)
	return Util.Create("UIGradient", {
		Color = colorSequence,
		Rotation = rotation or 0,
		Parent = parent,
	})
end

-- Shadow halus menggunakan ImageLabel 9-slice (dropshadow generik)
function Util.Shadow(parent, transparency, size)
	local shadow = Util.Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = transparency or 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, size or 30, 1, size or 30),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0,
		Parent = parent,
	})
	return shadow
end

-- Efek ripple material-design saat elemen ditekan
function Util.Ripple(button, theme)
	button.ClipsDescendants = true
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = input.Position
		local relX = pos.X - button.AbsolutePosition.X
		local relY = pos.Y - button.AbsolutePosition.Y
		local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.6

		local ripple = Util.Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.82,
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0, relX, 0, relY),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = button.ZIndex + 1,
			Parent = button,
		})
		Util.Corner(ripple, 999)

		Util.QuickTween(ripple, { Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Quad)
		task.delay(0.5, function()
			ripple:Destroy()
		end)
	end)
end

-- Hover generik: interpolasi warna background antara Normal <-> Hover
function Util.Hover(obj, normalColor, hoverColor, duration)
	obj.MouseEnter:Connect(function()
		Util.QuickTween(obj, { BackgroundColor3 = hoverColor }, duration or 0.15)
	end)
	obj.MouseLeave:Connect(function()
		Util.QuickTween(obj, { BackgroundColor3 = normalColor }, duration or 0.15)
	end)
end

-- Membuat frame draggable lewat sebuah "handle" (mis. topbar)
function Util.Draggify(frame, handle)
	handle = handle or frame
	local dragging, dragInput, startPos, startInputPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = frame.Position
			startInputPos = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - startInputPos
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Membuat frame resizable lewat handle kecil di pojok kanan-bawah
function Util.Resizify(frame, minSize, maxSize)
	minSize = minSize or Vector2.new(560, 380)
	maxSize = maxSize or Vector2.new(1400, 900)

	local grip = Util.Create("Frame", {
		Name = "ResizeGrip",
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(1, -18, 1, -18),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = frame,
	})

	local resizing, startSize, startInputPos

	grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startSize = frame.Size
			startInputPos = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInputPos
			local newX = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
			local newY = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
			frame.Size = UDim2.new(0, newX, 0, newY)
		end
	end)

	return grip
end

NovaUI._Util = Util

--====================================================================
-- SECTION: ICONS
-- Table nama -> asset id. Bisa ditambah bebas. Jika nama tidak ada,
-- fallback ke bullet sederhana sehingga library tidak pernah error.
--====================================================================
NovaUI.Icons = {
	home        = "rbxassetid://10723347404",
	gamepad     = "rbxassetid://10734950309",
	settings    = "rbxassetid://10734943902",
	search      = "rbxassetid://10734950309",
	close       = "rbxassetid://10747384394",
	minimize    = "rbxassetid://10747371002",
	dice        = "rbxassetid://10723407163",
	shield      = "rbxassetid://10723407923",
	bolt        = "rbxassetid://10723406145",
	chevronDown = "rbxassetid://10709790771",
	check       = "rbxassetid://10709790644",
	discord     = "rbxassetid://10723407510",
	user        = "rbxassetid://10723365040",
	info        = "rbxassetid://10734950404",
	warning     = "rbxassetid://10734949905",
	x           = "rbxassetid://10747384394",
}

function NovaUI:GetIcon(name)
	return self.Icons[name] or self.Icons.bolt
end

--====================================================================
-- SECTION: CONFIG
-- Penyimpanan konfigurasi memakai writefile/readfile/isfile jika
-- tersedia di lingkungan eksekusi (dijaga dengan pcall), dengan
-- fallback ke penyimpanan dalam-memori supaya library tetap berjalan
-- normal di lingkungan tanpa akses filesystem (mis. Roblox Studio).
--====================================================================
local Config = {}
Config.__index = Config

local function fsAvailable()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

function Config.new(name)
	local self = setmetatable({}, Config)
	self.Name = name or "NovaUI_Config"
	self.Path = self.Name .. ".json"
	self.Store = {}
	self:Load()
	return self
end

function Config:Load()
	if fsAvailable() then
		local ok, result = pcall(function()
			if isfile(self.Path) then
				return HttpService:JSONDecode(readfile(self.Path))
			end
			return {}
		end)
		self.Store = ok and result or {}
	end
end

function Config:Save()
	if fsAvailable() then
		pcall(function()
			writefile(self.Path, HttpService:JSONEncode(self.Store))
		end)
	end
end

function Config:Set(key, value)
	self.Store[key] = value
	self:Save()
end

function Config:Get(key, default)
	if self.Store[key] == nil then
		return default
	end
	return self.Store[key]
end

NovaUI._Config = Config

--====================================================================
-- SECTION: NOTIFICATION
--====================================================================
local Notification = {}
Notification.__index = Notification

function Notification.new(gui, theme)
	local self = setmetatable({}, Notification)
	self.Theme = theme
	self.Container = Util.Create("Frame", {
		Name = "NotificationContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 320, 1, -40),
		Position = UDim2.new(1, -340, 0, 20),
		Parent = gui,
	})
	Util.Create("UIListLayout", {
		Padding = UDim.new(0, 10),
		VerticalAlignment = Enum.VerticalAlignment.Top,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Container,
	})
	return self
end

-- Types: "Info", "Success", "Warning", "Error"
function Notification:Push(opts)
	opts = opts or {}
	local theme = self.Theme
	local accentByType = {
		Info = theme.Accent,
		Success = theme.Success,
		Warning = theme.Warning,
		Error = theme.Error,
	}
	local accent = accentByType[opts.Type] or theme.Accent

	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 40, 0, 0),
		ClipsDescendants = true,
	})
	Util.Corner(card, 12)
	Util.Stroke(card, theme.Stroke, 1)
	Util.Padding(card, 14)

	Util.Create("Frame", {
		BackgroundColor3 = accent,
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.new(0, 0, 0, 4),
		Parent = card,
	}, {}).Parent = card
	Util.Corner(card:FindFirstChildOfClass("Frame"), 4)

	local title = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "Notification",
		Font = theme.FontSemibold,
		TextSize = 15,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -12, 0, 20),
		Position = UDim2.new(0, 12, 0, 0),
		Parent = card,
	})

	local desc = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Content or "",
		Font = theme.Font,
		TextSize = 13,
		TextColor3 = theme.TextSecondary,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 12, 0, 24),
		Parent = card,
	})

	card.Parent = self.Container
	card.Size = UDim2.new(1, 0, 0, 0)

	-- Slide-in + fade
	card.BackgroundTransparency = 1
	title.TextTransparency = 1
	desc.TextTransparency = 1
	Util.QuickTween(card, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.35)
	Util.QuickTween(title, { TextTransparency = 0 }, 0.35)
	Util.QuickTween(desc, { TextTransparency = 0 }, 0.35)

	local duration = opts.Duration or 4.5
	task.delay(duration, function()
		if card and card.Parent then
			Util.QuickTween(card, { Position = UDim2.new(1, 40, 0, 0) }, 0.3)
			task.delay(0.3, function()
				if card then card:Destroy() end
			end)
		end
	end)

	return card
end

NovaUI._Notification = Notification

--====================================================================
-- SECTION: DIALOG
--====================================================================
local Dialog = {}
Dialog.__index = Dialog

function Dialog.new(gui, theme)
	local self = setmetatable({}, Dialog)
	self.Theme = theme
	self.Gui = gui
	return self
end

function Dialog:Open(opts)
	opts = opts or {}
	local theme = self.Theme

	local backdrop = Util.Create("Frame", {
		Name = "DialogBackdrop",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 100,
		Parent = self.Gui,
	})

	local box = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(0, 360, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 101,
		Parent = backdrop,
	})
	Util.Corner(box, 14)
	Util.Stroke(box, theme.Stroke, 1)
	Util.Shadow(box, 0.5, 60)
	Util.Padding(box, 20)

	local layout = Util.Create("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = box,
	})

	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "Confirm",
		Font = theme.FontBold,
		TextSize = 18,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
		Parent = box,
	})

	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Content or "",
		Font = theme.Font,
		TextSize = 14,
		TextColor3 = theme.TextSecondary,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = box,
	})

	local btnRow = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 3,
		Parent = box,
	})
	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 10),
		Parent = btnRow,
	})

	local function closeDialog()
		Util.QuickTween(backdrop, { BackgroundTransparency = 1 }, 0.2)
		Util.QuickTween(box, { Size = UDim2.new(0, 340, 0, box.AbsoluteSize.Y) }, 0.2)
		task.delay(0.2, function() backdrop:Destroy() end)
	end

	for i, btnOpt in ipairs(opts.Buttons or { { Text = "OK", Callback = function() end } }) do
		local isAccent = btnOpt.Accent
		local btn = Util.Create("TextButton", {
			BackgroundColor3 = isAccent and theme.Accent or theme.PanelTertiary,
			Size = UDim2.new(0, 96, 1, 0),
			Text = btnOpt.Text or "OK",
			Font = theme.FontSemibold,
			TextSize = 14,
			TextColor3 = isAccent and Color3.new(1,1,1) or theme.TextPrimary,
			AutoButtonColor = false,
			Parent = btnRow,
		})
		Util.Corner(btn, 8)
		Util.Ripple(btn, theme)
		Util.Hover(btn, btn.BackgroundColor3, isAccent and theme.AccentHover or theme.PanelHover)
		btn.MouseButton1Click:Connect(function()
			if btnOpt.Callback then btnOpt.Callback() end
			closeDialog()
		end)
	end

	backdrop.BackgroundTransparency = 1
	box.Size = UDim2.new(0, 320, 0, 0)
	Util.QuickTween(backdrop, { BackgroundTransparency = 0.45 }, 0.25)
	Util.QuickTween(box, { Size = UDim2.new(0, 360, 0, box.AbsoluteSize.Y) }, 0.25, Enum.EasingStyle.Back)

	return backdrop
end

NovaUI._Dialog = Dialog

--====================================================================
-- SECTION: COMPONENTS
-- Setiap komponen adalah fungsi factory yang menerima (parent, theme, opts)
-- dan mengembalikan sebuah object dengan API :Set()/:Get() bila relevan.
-- Semua komponen berbagi "shell" (card container) yang seragam lewat
-- Components.BaseCard supaya tampilan konsisten & kode tidak berduplikasi.
--====================================================================
local Components = {}

-- Card dasar dipakai semua komponen baris-tunggal (Button/Toggle/Slider/dst)
function Components.BaseCard(parent, theme, title, subtitle, height)
	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(1, 0, 0, height or 52),
		Parent = parent,
	})
	Util.Corner(card, 10)
	Util.Stroke(card, theme.Stroke, 1)

	local textHolder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.55, 0, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		Parent = card,
	})

	local titleLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title or "",
		Font = theme.FontSemibold,
		TextSize = 14,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, subtitle and 0.5 or 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = textHolder,
	})

	local subLabel
	if subtitle and subtitle ~= "" then
		subLabel = Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = subtitle,
			Font = theme.Font,
			TextSize = 12,
			TextColor3 = theme.TextTertiary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0.5, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			Parent = textHolder,
		})
	end

	Util.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = textHolder,
	})

	return card, titleLabel, subLabel
end

-- ---------------------------------------------------------------
-- BUTTON
-- ---------------------------------------------------------------
function Components.CreateButton(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, opts.Description, 52)

	local action = Util.Create("TextButton", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(0, 110, 0, 32),
		Position = UDim2.new(1, -124, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = opts.ButtonText or "Execute",
		Font = theme.FontSemibold,
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Parent = card,
	})
	Util.Corner(action, 8)
	Util.Ripple(action, theme)
	Util.Hover(action, theme.Accent, theme.AccentHover)

	action.MouseButton1Click:Connect(function()
		if opts.Callback then
			task.spawn(opts.Callback)
		end
	end)

	return { Instance = card, SetText = function(_, t) action.Text = t end }
end

-- ---------------------------------------------------------------
-- TOGGLE
-- ---------------------------------------------------------------
function Components.CreateToggle(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, opts.Description, 52)
	local state = opts.Default or false

	local track = Util.Create("Frame", {
		BackgroundColor3 = state and theme.Accent or theme.PanelTertiary,
		Size = UDim2.new(0, 44, 0, 24),
		Position = UDim2.new(1, -58, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	})
	Util.Corner(track, 999)
	Util.Stroke(track, theme.Stroke, 1)

	local knob = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 18, 0, 18),
		Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = track,
	})
	Util.Corner(knob, 999)

	local hitbox = Util.Create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 0, 1, 0),
		Parent = track,
	})

	local self = { Value = state }

	local function render(animate)
		local dur = animate and 0.2 or 0
		Util.QuickTween(track, { BackgroundColor3 = self.Value and theme.Accent or theme.PanelTertiary }, dur)
		Util.QuickTween(knob, { Position = self.Value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, dur, Enum.EasingStyle.Back)
	end

	hitbox.MouseButton1Click:Connect(function()
		self.Value = not self.Value
		render(true)
		if opts.Callback then task.spawn(opts.Callback, self.Value) end
	end)

	function self:Set(value)
		self.Value = value
		render(true)
	end

	self.Instance = card
	return self
end

-- ---------------------------------------------------------------
-- SLIDER
-- ---------------------------------------------------------------
function Components.CreateSlider(parent, theme, opts)
	opts = opts or {}
	local min, max = opts.Min or 0, opts.Max or 100
	local increment = opts.Increment or 1
	local value = math.clamp(opts.Default or min, min, max)

	local card = Components.BaseCard(parent, theme, opts.Title, nil, 58)

	local valueLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = tostring(value) .. (opts.Suffix or ""),
		Font = theme.FontSemibold,
		TextSize = 13,
		TextColor3 = theme.Accent,
		Size = UDim2.new(0, 60, 0, 18),
		Position = UDim2.new(1, -74, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})

	local barBack = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(1, -28, 0, 6),
		Position = UDim2.new(0, 14, 1, -16),
		Parent = card,
	})
	Util.Corner(barBack, 999)

	local ratio = (value - min) / math.max(max - min, 1e-6)
	local barFill = Util.Create("Frame", {
		BackgroundColor3 = theme.Accent,
		Size = UDim2.new(ratio, 0, 1, 0),
		Parent = barBack,
	})
	Util.Corner(barFill, 999)

	local knob = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(ratio, 0, 0.5, 0),
		Parent = barBack,
	})
	Util.Corner(knob, 999)
	Util.Stroke(knob, theme.Accent, 2)

	local self = { Value = value }

	local function setFromRatio(r, fire)
		r = math.clamp(r, 0, 1)
		local raw = min + (max - min) * r
		local stepped = math.floor(raw / increment + 0.5) * increment
		stepped = math.clamp(stepped, min, max)
		self.Value = stepped
		local newRatio = (stepped - min) / math.max(max - min, 1e-6)
		Util.QuickTween(barFill, { Size = UDim2.new(newRatio, 0, 1, 0) }, 0.05)
		Util.QuickTween(knob, { Position = UDim2.new(newRatio, 0, 0.5, 0) }, 0.05)
		valueLabel.Text = tostring(stepped) .. (opts.Suffix or "")
		if fire and opts.Callback then task.spawn(opts.Callback, stepped) end
	end

	local dragging = false
	local hitbox = Util.Create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 20, 0, 20),
		Position = UDim2.new(0, -10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = barBack,
	})

	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local r = (input.Position.X - barBack.AbsolutePosition.X) / barBack.AbsoluteSize.X
			setFromRatio(r, true)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local r = (input.Position.X - barBack.AbsolutePosition.X) / barBack.AbsoluteSize.X
			setFromRatio(r, true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	function self:Set(v)
		setFromRatio((v - min) / math.max(max - min, 1e-6), false)
	end

	self.Instance = card
	return self
end

-- ---------------------------------------------------------------
-- DROPDOWN (Single & Multi select)
-- ---------------------------------------------------------------
function Components.CreateDropdown(parent, theme, opts)
	opts = opts or {}
	local options = opts.Options or {}
	local multi = opts.Multi or false
	local selected = {}

	if multi then
		for _, v in ipairs(opts.Default or {}) do selected[v] = true end
	else
		if opts.Default then selected[opts.Default] = true end
	end

	local card = Components.BaseCard(parent, theme, opts.Title, nil, 52)
	card.ClipsDescendants = false

	local function currentText()
		local list = {}
		for k, v in pairs(selected) do if v then table.insert(list, k) end end
		if #list == 0 then return opts.Placeholder or "Select..." end
		return table.concat(list, ", ")
	end

	local display = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 160, 0, 32),
		Position = UDim2.new(1, -174, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "",
		AutoButtonColor = false,
		Parent = card,
	})
	Util.Corner(display, 8)
	Util.Stroke(display, theme.Stroke, 1)

	local displayLabel = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = currentText(),
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Parent = display,
	})

	local arrow = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "▾",
		Font = theme.Font,
		TextSize = 14,
		TextColor3 = theme.TextSecondary,
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -24, 0, 0),
		Parent = display,
	})

	local listFrame = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 160, 0, 0),
		Position = UDim2.new(1, -174, 1, 6),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 50,
		Parent = card,
	})
	Util.Corner(listFrame, 8)
	Util.Stroke(listFrame, theme.Stroke, 1)
	local listLayout = Util.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = listFrame })
	Util.Padding(listFrame, 4)

	local open = false
	local function toggleList()
		open = not open
		listFrame.Visible = true
		local targetHeight = math.min(#options * 30 + 8, 180)
		Util.QuickTween(listFrame, { Size = UDim2.new(0, 160, 0, open and targetHeight or 0) }, 0.2)
		Util.QuickTween(arrow, { Rotation = open and 180 or 0 }, 0.2)
		if not open then
			task.delay(0.2, function() if not open then listFrame.Visible = false end end)
		end
	end

	display.MouseButton1Click:Connect(toggleList)

	for i, option in ipairs(options) do
		local optBtn = Util.Create("TextButton", {
			BackgroundColor3 = theme.PanelTertiary,
			Size = UDim2.new(1, 0, 0, 28),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			ZIndex = 51,
			Parent = listFrame,
		})
		Util.Corner(optBtn, 6)
		local optLabel = Util.Create("TextLabel", {
			BackgroundTransparency = 1,
			Text = tostring(option),
			Font = theme.Font,
			TextSize = 12,
			TextColor3 = selected[option] and theme.Accent or theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			ZIndex = 51,
			Parent = optBtn,
		})
		Util.Hover(optBtn, theme.PanelTertiary, theme.PanelHover)

		optBtn.MouseButton1Click:Connect(function()
			if multi then
				selected[option] = not selected[option]
				optLabel.TextColor3 = selected[option] and theme.Accent or theme.TextSecondary
			else
				selected = { [option] = true }
				for _, child in ipairs(listFrame:GetChildren()) do
					if child:IsA("TextButton") then
						child:FindFirstChildOfClass("TextLabel").TextColor3 = theme.TextSecondary
					end
				end
				optLabel.TextColor3 = theme.Accent
				toggleList()
			end
			displayLabel.Text = currentText()
			if opts.Callback then
				if multi then
					local list = {}
					for k, v in pairs(selected) do if v then table.insert(list, k) end end
					task.spawn(opts.Callback, list)
				else
					task.spawn(opts.Callback, option)
				end
			end
		end)
	end

	return {
		Instance = card,
		Get = function() return selected end,
	}
end

-- ---------------------------------------------------------------
-- TEXTBOX
-- ---------------------------------------------------------------
function Components.CreateTextbox(parent, theme, opts)
	opts = opts or {}
	local card = Components.BaseCard(parent, theme, opts.Title, nil, 52)

	local box = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 160, 0, 32),
		Position = UDim2.new(1, -174, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	})
	Util.Corner(box, 8)
	Util.Stroke(box, theme.Stroke, 1)

	local input = Util.Create("TextBox", {
		BackgroundTransparency = 1,
		Text = opts.Default or "",
		PlaceholderText = opts.Placeholder or "Enter text...",
		Font = theme.Font,
		TextSize = 12,
		TextColor3 = theme.TextPrimary,
		PlaceholderColor3 = theme.TextTertiary,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = box,
	})

	input.Focused:Connect(function()
		Util.QuickTween(box, {}, 0.1)
		Util.Stroke(box, theme.Accent, 1.5)
	end)

	input.FocusLost:Connect(function(enterPressed)
		if opts.Callback then task.spawn(opts.Callback, input.Text, enterPressed) end
	end)

	return { Instance = card, Get = function() return input.Text end, Set = function(_, t) input.Text = t end }
end

-- ---------------------------------------------------------------
-- COLOR PICKER (HSV sederhana: hue strip + saturation/value canvas)
-- ---------------------------------------------------------------
function Components.CreateColorPicker(parent, theme, opts)
	opts = opts or {}
	local color = opts.Default or Color3.fromRGB(255, 255, 255)

	local card = Components.BaseCard(parent, theme, opts.Title, nil, 52)
	card.ClipsDescendants = false

	local swatch = Util.Create("TextButton", {
		BackgroundColor3 = color,
		Size = UDim2.new(0, 44, 0, 28),
		Position = UDim2.new(1, -58, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "",
		AutoButtonColor = false,
		Parent = card,
	})
	Util.Corner(swatch, 6)
	Util.Stroke(swatch, theme.Stroke, 1)

	local panel = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 200, 0, 0),
		Position = UDim2.new(1, -244, 1, 6),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 50,
		Parent = card,
	})
	Util.Corner(panel, 10)
	Util.Stroke(panel, theme.Stroke, 1)
	Util.Padding(panel, 10)

	local svCanvas = Util.Create("ImageLabel", {
		Image = "rbxassetid://4155801252", -- generic saturation/value gradient map
		Size = UDim2.new(1, 0, 0, 120),
		BackgroundColor3 = color,
		ZIndex = 51,
		Parent = panel,
	})
	Util.Corner(svCanvas, 6)

	local svCursor = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 10, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 0, 0, 0),
		ZIndex = 52,
		Parent = svCanvas,
	})
	Util.Corner(svCursor, 999)
	Util.Stroke(svCursor, Color3.new(0,0,0), 1)

	local hueBar = Util.Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 130),
		ZIndex = 51,
		Parent = panel,
	})
	Util.Corner(hueBar, 999)
	Util.Gradient(hueBar, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
		ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
		ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
		ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
		ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
		ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
	}))

	local hueCursor = Util.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 4, 1, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 52,
		Parent = hueBar,
	})
	Util.Corner(hueCursor, 2)

	local h, s, v = Color3.toHSV(color)
	local self = { Value = color }

	local function updateColor()
		local c = Color3.fromHSV(h, s, v)
		self.Value = c
		swatch.BackgroundColor3 = c
		svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		if opts.Callback then task.spawn(opts.Callback, c) end
	end

	local draggingSV, draggingHue = false, false

	svCanvas.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = true
		end
	end)
	hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
		end
	end)
	UserInputService.InputEnded:Connect(function()
		draggingSV = false
		draggingHue = false
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if draggingSV then
			local relX = math.clamp((input.Position.X - svCanvas.AbsolutePosition.X) / svCanvas.AbsoluteSize.X, 0, 1)
			local relY = math.clamp((input.Position.Y - svCanvas.AbsolutePosition.Y) / svCanvas.AbsoluteSize.Y, 0, 1)
			s = relX
			v = 1 - relY
			svCursor.Position = UDim2.new(relX, 0, relY, 0)
			updateColor()
		elseif draggingHue then
			local relX = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
			h = relX
			hueCursor.Position = UDim2.new(relX, 0, 0.5, 0)
			updateColor()
		end
	end)

	local panelOpen = false
	swatch.MouseButton1Click:Connect(function()
		panelOpen = not panelOpen
		panel.Visible = true
		Util.QuickTween(panel, { Size = UDim2.new(0, 200, 0, panelOpen and 160 or 0) }, 0.22)
		if not panelOpen then
			task.delay(0.22, function() if not panelOpen then panel.Visible = false end end)
		end
	end)

	self.Instance = card
	return self
end

-- ---------------------------------------------------------------
-- KEYBIND
-- ---------------------------------------------------------------
function Components.CreateKeybind(parent, theme, opts)
	opts = opts or {}
	local currentKey = opts.Default or Enum.KeyCode.Unknown
	local card = Components.BaseCard(parent, theme, opts.Title, nil, 52)

	local keyBtn = Util.Create("TextButton", {
		BackgroundColor3 = theme.PanelTertiary,
		Size = UDim2.new(0, 100, 0, 30),
		Position = UDim2.new(1, -114, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = currentKey.Name ~= "Unknown" and currentKey.Name or "None",
		Font = theme.FontSemibold,
		TextSize = 12,
		TextColor3 = theme.TextSecondary,
		AutoButtonColor = false,
		Parent = card,
	})
	Util.Corner(keyBtn, 8)
	Util.Stroke(keyBtn, theme.Stroke, 1)

	local listening = false
	local self = { Value = currentKey }

	keyBtn.MouseButton1Click:Connect(function()
		listening = true
		keyBtn.Text = "..."
		Util.Stroke(keyBtn, theme.Accent, 1.5)
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if not listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			currentKey = input.KeyCode
			self.Value = currentKey
			keyBtn.Text = currentKey.Name
			listening = false
			Util.Stroke(keyBtn, theme.Stroke, 1)
			if opts.Callback then task.spawn(opts.Callback, currentKey) end
		end
	end)

	return self
end

-- ---------------------------------------------------------------
-- LABEL / SECTION HEADER / PARAGRAPH (elemen non-interaktif)
-- ---------------------------------------------------------------
function Components.CreateLabel(parent, theme, opts)
	opts = opts or {}
	local label = Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Text or "",
		Font = theme.Font,
		TextSize = 13,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	return { Instance = label, Set = function(_, t) label.Text = t end }
end

function Components.CreateSectionHeader(parent, theme, title)
	local holder = Util.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		Parent = parent,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = title or "Section",
		Font = theme.FontBold,
		TextSize = 13,
		TextColor3 = theme.TextTertiary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = holder,
	})
	return holder
end

function Components.CreateParagraph(parent, theme, opts)
	opts = opts or {}
	local card = Util.Create("Frame", {
		BackgroundColor3 = theme.PanelSecondary,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	Util.Corner(card, 10)
	Util.Stroke(card, theme.Stroke, 1)
	Util.Padding(card, 14)

	Util.Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Title or "",
		Font = theme.FontSemibold,
		TextSize = 14,
		TextColor3 = theme.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 1,
		Parent = card,
	})
	Util.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.Content or "",
		Font = theme.Font,
		TextSize = 13,
		TextColor3 = theme.TextSecondary,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = card,
	})

	return { Instance = card }
end

NovaUI._Components = Components

return NovaUI
