--[[-----------------------------------------------------------------------------
ScrollFrame Container
Plain container that scrolls its content and doesn't grow in height.
Based on AceGUI ScrollFrame, but with a custom scrollbar look.
-------------------------------------------------------------------------------]]
local _, Ctx = ...
local Amr = Ctx.Amr
local Type, Version = "AmrUiScrollFrame", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end


--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function FixScrollOnUpdate(frame)
	frame:SetScript("OnUpdate", nil)
	frame.obj:FixScroll()
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function ScrollFrame_OnMouseWheel(frame, value)
	frame.obj:MoveScroll(value)
end

local function ScrollFrame_OnSizeChanged(frame)
	frame:SetScript("OnUpdate", FixScrollOnUpdate)
end

local function ScrollBar_OnScrollValueChanged(frame, value)
	frame.obj:SetScroll(value)
end

local function ScrollBar_UpArrowClick(frame)
	frame.obj:MoveScroll(50)
end

local function ScrollBar_DownArrowClick(frame)
	frame.obj:MoveScroll(-50)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self) 
		self:SetScroll(0)
		self.scrollframe:SetScript("OnUpdate", FixScrollOnUpdate)
	end,

	["OnRelease"] = function(self)
		self.status = nil
		for k in pairs(self.localstatus) do
			self.localstatus[k] = nil
		end
		self.scrollframe:SetPoint("BOTTOMRIGHT")
		self.scrollbar:Hide()
		self.uparrow:Hide()
		self.downarrow:Hide()
		self.scrollBarShown = nil
		self.content.height, self.content.width = nil, nil
	end,

	["SetScroll"] = function(self, value)
		local status = self.status or self.localstatus
		local viewheight = self.scrollframe:GetHeight()
		local height = self.content:GetHeight()
		local offset

		if viewheight > height then
			offset = 0
		else
			offset = floor((height - viewheight) / 1000.0 * value)
		end
		self.content:ClearAllPoints()
		self.content:SetPoint("TOPLEFT", 0, offset)
		self.content:SetPoint("TOPRIGHT", 0, offset)
		status.offset = offset
		status.scrollvalue = value
	end,

	["MoveScroll"] = function(self, value)
		local status = self.status or self.localstatus
		local height, viewheight = self.scrollframe:GetHeight(), self.content:GetHeight()
		
		if self.scrollBarShown then
			local diff = height - viewheight
			local delta = 1
			if value < 0 then
				delta = -1
			end
			self.scrollbar:SetValue(min(max(status.scrollvalue + delta*(1000/(diff/45)),0), 1000))
		end
	end,

	["FixScroll"] = function(self)
		if self.updateLock then return end
		self.updateLock = true
		local status = self.status or self.localstatus
		local height, viewheight = self.scrollframe:GetHeight(), self.content:GetHeight()
		local offset = status.offset or 0
		--local curvalue = self.scrollbar:GetValue()
		-- Give us a margin of error of 2 pixels to stop some conditions that i would blame on floating point inaccuracys
		-- No-one is going to miss 2 pixels at the bottom of the frame, anyhow!
		if viewheight < height + 2 then
			if self.scrollBarShown then
				self.scrollBarShown = nil
				self.scrollbar:Hide()
				self.uparrow:Hide()
				self.downarrow:Hide()
				self.scrollbar:SetValue(0)
				self.scrollframe:SetPoint("BOTTOMRIGHT")
				self:DoLayout()
			end
		else
			if not self.scrollBarShown then
				self.scrollBarShown = true
				self.scrollbar:Show()
				self.uparrow:Show()
				self.downarrow:Show()
				self.scrollframe:SetPoint("BOTTOMRIGHT", -20, 0)
				self:DoLayout()
			end
			local value = (offset / (viewheight - height) * 1000)
			if value > 1000 then value = 1000 end
			self.scrollbar:SetValue(value)
			self:SetScroll(value)
			if value < 1000 then
				self.content:ClearAllPoints()
				self.content:SetPoint("TOPLEFT", 0, offset)
				self.content:SetPoint("TOPRIGHT", 0, offset)
				status.offset = offset
			end
		end
		self.updateLock = nil
	end,

	["LayoutFinished"] = function(self, width, height)
		self.content:SetHeight(height or 0 + 20)
		self.scrollframe:SetScript("OnUpdate", FixScrollOnUpdate)
	end,

	["SetStatusTable"] = function(self, status)
		assert(type(status) == "table")
		self.status = status
		if not status.scrollvalue then
			status.scrollvalue = 0
		end
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.content
		content.width = width
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		content.height = height
	end
}
--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local name = "AmrUiScrollFrame" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", name, UIParent)
	local num = AceGUI:GetNextWidgetNum(Type)

	local scrollframe = CreateFrame("ScrollFrame", nil, frame)
	scrollframe:SetPoint("TOPLEFT")
	scrollframe:SetPoint("BOTTOMRIGHT")
	scrollframe:EnableMouseWheel(true)
	scrollframe:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
	scrollframe:SetScript("OnSizeChanged", ScrollFrame_OnSizeChanged)

	local scrollbar = CreateFrame("Slider", ("AmrUiScrollFrame%dScrollBar"):format(num), scrollframe)
	scrollbar:SetPoint("TOPLEFT", scrollframe, "TOPRIGHT", 4, -16)
	scrollbar:SetPoint("BOTTOMLEFT", scrollframe, "BOTTOMRIGHT", 4, 16)
	scrollbar:SetMinMaxValues(0, 1000)
	scrollbar:SetValueStep(1)
	scrollbar:SetValue(0)
	scrollbar:SetWidth(16)
	scrollbar:Hide()
	
	local thumb = Amr.CreateTexture(scrollbar, Amr.Colors.Gray)
	thumb:SetWidth(16)
	thumb:SetHeight(32)	
	scrollbar:SetThumbTexture(thumb)
	
	local uparrow = CreateFrame("Button", nil, frame)
	uparrow:SetWidth(16)
	uparrow:SetHeight(16)
	
	local tex = uparrow:CreateTexture()
	tex:SetWidth(16)
	tex:SetHeight(16)
	tex:SetTexture("Interface\\AddOns\\" .. Amr.ADDON_NAME .. "\\Media\\IconScrollUp")
	tex:SetPoint("LEFT", uparrow, "LEFT")
	uparrow:SetNormalTexture(tex)
	
	uparrow:SetPoint("BOTTOMRIGHT", scrollbar, "TOPRIGHT")
	uparrow:SetScript("OnClick", ScrollBar_UpArrowClick)
	uparrow:Hide()
	
	local downarrow = CreateFrame("Button", nil, frame)
	downarrow:SetWidth(16)
	downarrow:SetHeight(16)
	
	tex = downarrow:CreateTexture()
	tex:SetWidth(16)
	tex:SetHeight(16)
	tex:SetTexture("Interface\\AddOns\\" .. Amr.ADDON_NAME .. "\\Media\\IconScrollDown")
	tex:SetPoint("LEFT", downarrow, "LEFT")
	downarrow:SetNormalTexture(tex)
	
	downarrow:SetPoint("TOPRIGHT", scrollbar, "BOTTOMRIGHT")
	downarrow:SetScript("OnClick", ScrollBar_DownArrowClick)
	downarrow:Hide()
	
	-- set the script as the last step, so it doesn't fire yet
	scrollbar:SetScript("OnValueChanged", ScrollBar_OnScrollValueChanged)

	local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND")
	scrollbg:SetPoint("TOPLEFT", scrollbar, "TOPLEFT", 0, 16)
	scrollbg:SetPoint("BOTTOMRIGHT", scrollbar, "BOTTOMRIGHT", 0, -16)
	scrollbg:SetColorTexture(0, 0, 0, 0.3)
	
	--Container Support
	local content = CreateFrame("Frame", nil, scrollframe)
	content:SetPoint("TOPLEFT")
	content:SetPoint("TOPRIGHT")
	content:SetHeight(400)
	scrollframe:SetScrollChild(content)

	local widget = {
		localstatus = { scrollvalue = 0 },
		scrollframe = scrollframe,
		uparrow     = uparrow,
		downarrow   = downarrow,
		scrollbar   = scrollbar,
		content     = content,
		frame       = frame,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	scrollframe.obj, scrollbar.obj, uparrow.obj, downarrow.obj = widget, widget, widget, widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)