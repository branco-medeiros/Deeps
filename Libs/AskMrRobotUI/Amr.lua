local _, Ctx = ...
local Amr = {}
Ctx.Amr = Amr

local AceGUI = LibStub("AceGUI-3.0")

Amr.ADDON_NAME = "Deeps\\Libs\\AskMrRobotUI"
-- used to make some stuff layer correctly
Amr.FrameLevels = {
	High = 100,
	Highest = 125
}

-- standard colors used throughout the UI (in standard 0-255 RGB format, game uses 0-1 decimals, but we auto-convert it below)
Amr.Colors = {
	White =              { R = 255, G = 255, B = 255 },
	Black =              { R =   0, G =   0, B =   0 },
	Gray =               { R = 153, G = 153, B = 153 },
	Orange =             { R = 201, G =  87, B =   1 },
	Green =              { R =  77, G = 134, B =  45 },
	Blue =               { R =  54, G = 172, B = 204 },
	Red =                { R = 204, G =  38, B =  38 },
	Gold =               { R = 255, G = 215, B =   0 },
	BrightGreen =        { R =   0, G = 255, B =   0 },
	Text =               { R = 255, G = 255, B = 255 },
	TextHover =          { R = 255, G = 255, B =   0 },
	TextGray =           { R = 120, G = 120, B = 120 },
	TextHeaderActive =   { R = 223, G = 134, B =  61 },
	TextHeaderDisabled = { R = 188, G = 188, B = 188 },
	TextTan =            { R = 223, G = 192, B = 159 },
	BorderBlue =         { R =  26, G =  83, B =  98 },
	BorderGray =         { R =  96, G =  96, B =  96 },
	Bg =                 { R =  41, G =  41, B =  41 },
	BgInput =            { R =  17, G =  17, B =  17 },
	BarHigh =            { R = 114, G = 197, B =  66 },
	BarMed =             { R = 255, G = 196, B =  36 },
	BarLow =             { R = 201, G =  87, B =   1 }
}

-- convert from common RGB to 0-1 RGB values
for k,v in pairs(Amr.Colors) do
	v.R = v.R / 255
	v.G = v.G / 255
	v.B = v.B / 255
end

-- get colors for classes from WoW's constants
Amr.Colors.Classes = {}
for k,v in pairs(RAID_CLASS_COLORS) do
	Amr.Colors.Classes[k] = { R = v.r, G = v.g, B = v.b }
end

-- get colors for item qualities from WoW's constants
Amr.Colors.Qualities = {}
for k,v in pairs(ITEM_QUALITY_COLORS) do
	Amr.Colors.Qualities[k] = { R = v.r, G = v.g, B = v.b }
end

-- helper to take 0-1 value and turn into 2-digit hex value
local function decToHex(num)
	num = math.ceil(num * 255)
	num = string.format("%X", num)
	if string.len(num) == 1 then num = "0" .. num end
	return num
end

function Amr.ColorToHex(color, alpha)
	return decToHex(alpha) .. decToHex(color.R) .. decToHex(color.G) .. decToHex(color.B)
end

local function getFontPath(style)
	local locale = GetLocale()
	if locale == "koKR" then
		return "Fonts\\2002.TTF"
	elseif locale == "zhCN" then
		return "Fonts\\ARKai_T.ttf"
	elseif locale == "zhTW" then
		return "Fonts\\bLEI00D.ttf"
	elseif locale == "ruRU" then
		return "Fonts\\FRIZQT___CYR.TTF"
	else
		return "Interface\\AddOns\\" .. Amr.ADDON_NAME .. "\\Media\\Ubuntu-" .. style .. ".ttf"
	end
end

-- create a font with the specified style (Regular, Bold, Italic), size (pixels, max of 32), color (object with R, G, B), and alpha (if not specified, defaults to 1)
function Amr.CreateFont(style, size, color, a)
	local alpha = a or 1
	local id = string.format("%s_%d_%f_%f_%f_%f", style, size, color.R, color.G, color.B, alpha)
	local font = CreateFont(id)
	font:SetFont(getFontPath(style), size)
	font:SetTextColor(color.R, color.G, color.B, alpha)
	return font
end

-- helper to create a solid texture from a color with R,G,B properties
function Amr.CreateTexture(parent, color, alpha, layer)
	local t = parent:CreateTexture(nil, layer or "ARTWORK")
	t:SetColorTexture(color.R, color.G, color.B, alpha or 1)
	return t
end

-- helper to create a cheater shadow without having to create custom images
function Amr.DropShadow(frame)
	local shadow = frame:CreateTexture(nil, "BACKGROUND")
	shadow:SetColorTexture(0, 0, 0, 0.4)
	shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
	
	shadow = frame:CreateTexture(nil, "BACKGROUND")
	shadow:SetColorTexture(0, 0, 0, 0.3)
	shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
	
	shadow = frame:CreateTexture(nil, "BACKGROUND")
	shadow:SetColorTexture(0, 0, 0, 0.1)
	shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
	shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3)
end


-- a layout that does nothing, just lets the children position themselves how they prefer
AceGUI:RegisterLayout("None", function(content, children)
	if content.obj.LayoutFinished then	
		content.obj:LayoutFinished(nil, nil)
	end
end)


