args = ...

local DEEPS = "Deeps"
local DEEPS_DB = "DeepsDB"
local DEEPS_CMD = "deeps"
local DPS_CMD = "dps"
local FONT = "Fonts\\FRIZQT__.TTF"

local CONTAINER = "SimpleGroup" 
-- local CONTAINER = "InlineGroup" 

--local DEFAULT_BDR_TEX = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark'
local DEFAULT_BDR_TEX = "Interface\\Tooltips\\UI-Tooltip-Border"


local Deeps = LibStub("AceAddon-3.0"):NewAddon(
	DEEPS, 
	"AceConsole-3.0", 
	"AceEvent-3.0"
)
_G.Deeps = Deeps
local Config = LibStub("AceConfig-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local function GetFrameHeight(frame)
  return frame.height or frame:GetHeight() or 0
end

local function GetFrameWidth(frame)
  return frame.width or frame:GetWidth() or 0
end

local function DoLayout(child)
	--if child.DoLayout then child:DoLayout() end
end

local function FinishLayout(content, height)
	if content.obj.LayoutFinished then 
		content.obj:LayoutFinished(nil, height) 
	end
end

local function SetPoints(target, ...)
	if target.frame then target = target.frame end
	target:ClearAllPoints()
	for i, p in ipairs({...}) do
		if type(p) == "table" then
			target:SetPoint(unpack(p))
		else
			target:SetPoint(p)
		end
		--target:SetPoint((type(p) == "table" and unpack(p)) or p)
	end
end

local function SetAllPoints(target)
	SetPoints(target, "TOP", "LEFT", "RIGHT", "BOTTOM")
end

local function SetMinSize(frame, width, height)
	if frame.SetMinResize then frame:SetMinResize(width, height) end
end

local function SetBorder(frame, size, r, g, b)
  if frame.frame and not frame.SetBackdrop then frame = frame.frame end
  if not size or size == 0 then
    frame:SetBackdrop({edgeFile = nil, edgeSize = 0})
  else
    frame:SetBackdrop({edgeFile=DEFAULT_BDR_TEX, edgeSize=size})
    if r then frame:SetBackdropBorderColor(r, g or r, b or r) end
  end --if
end 


AceGUI:RegisterLayout("None", function(content, children)
	if children then
		for i, c in ipairs(children) do
			DoLayout(c)
		end
	end
	FinishLayout(content)
end)

local options = {
	name=DEEPS,
	handler=Deeps,
	type="group",
	args = {		
		debug = {
			type="toggle",
			name="Debug",
			desc="Enables/Disables the action priority debugging",
			get="debugging",
			set="debugging"
		}	
	}
}


-------------------------------------------------------------------------------
function Deeps:Debug(...)
  if self:debugging() then self:Print(...) end
end


-------------------------------------------------------------------------------
function Deeps:OnInitialize()
	local defaults = self:GetDefaultSettings()
	-- handle profiles
	self.db = LibStub("AceDB-3.0"):New(DEEPS_DB, defaults, true)
	
  self:Debug("Addon initializing")

	-- configuration window (via Interface > Addons > Deeps)
	Config:RegisterOptionsTable(DEEPS, options, {DEEPS_CMD, DPS_CMD})
	
	--chat commands
	self:RegisterChatCommand(DEEPS_CMD, "HandleCommand")
	self:RegisterChatCommand(DPS_CMD, "HandleCommand")
end


-------------------------------------------------------------------------------
function Deeps:OnEnable()
	self:Debug("Addon enabled...")
	self:InitializeUI()
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:OnSpecChange()
end


-------------------------------------------------------------------------------
function Deeps:OnDisable()
	self:Debug("Addon Disabled...")
end


-------------------------------------------------------------------------------
function Deeps:OnSpecChange()
  self:Debug("Spec changed")
  local sname, sid = UnitClass("player")
  local snum = GetSpecialization()
  local _, info = GetSpecializationInfo(snum)
  self.SpecId = self:GetClassId(sid, snum)
  self.SpecText =  sname .. ': ' .. info
  self.SpecData = self:GetSpecData(self.SpecId)
  self:Reload()
end

-- event handlers

-------------------------------------------------------------------------------
function Deeps:ACTIVE_TALENT_GROUP_CHANGED()
	self:OnSpecChange()
end


-- comands

-------------------------------------------------------------------------------
function Deeps:HandleCommand(input)
  self:Debug("Handle Command", input)
  if not input or input:trim() == "" then
    self:ShowMainWindow()
  else
    LibStub("AceConfigCmd-3.0"):HandleCommand(DEEPS_CMD, DEEPS, input)
  end
end


-------------------------------------------------------------------------------
function Deeps:ShowMainWindow()
  self.MainFrame:Show()
end


-------------------------------------------------------------------------------
function Deeps:ShowCommands()
	self:Print("CmdList called")
end


-------------------------------------------------------------------------------
function Deeps:debugging(value)
  if(value ~= nil) then self.db.profile.debug = value end
	return self.db.profile.debug
end


-------------------------------------------------------------------------------
function Deeps:GetSpecData(id)
  local ret = self.db.profile.specs[id]
  if not ret then
    ret = {
      prio = {},
      spells = {},
      conditions = {},
      slots = {}
    }
    self.db.profile.specs[id] = ret
  end
  return ret
end


-------------------------------------------------------------------------------
function Deeps:GetDefaultSettings()
  return {
    profile = {
      debug = false,
      specs = {}
    }
  }
end


-------------------------------------------------------------------------------
function Deeps:Reload()
  -- fills the interface with the specified spec data

  self.SpecLabel:SetSpecName()
	self.TabSelectors:SelectTab("prio")

	-- clear editors
end

function Deeps:ClearUI()
  self:SelectPriority(nil)
  self:SelectSpell(nil)
  self:SelectCondition(nil)
  self:SelectSlot(nil)

  self.PriorityScroll.scroll:ReleaseChildren()
  self.SpellScroll.scroll:ReleaseChildren()
  self.ConditionsScroll.scroll: ReleaseChildren()
  self.SlotsScroll.scroll:ReleaseChildrent()
end


-------------------------------------------------------------------------------
function Deeps:SelectPriority(value)
  self.Priority = value
  self.PriorityName:SetText((value and value.name ) or '')
  self.PrioritySpell:SetText((value and value.spell) or '')
end


-------------------------------------------------------------------------------
function Deeps:InitializeUI()
	if self.MainFrame == nil then
		self:CreateMainFrame()
		self.MainFrame.frame:Hide()
		-- register the main frame to closwe with ESC
		_G["Deeps.Frame"] = self.MainFrame
		tinsert(UISpecialFrames, "Deeps.Frame")
	end
end


-------------------------------------------------------------------------------
function Deeps:GetClassId(class, id)
  return class .. '-' .. id
end


-------------------------------------------------------------------------------
function Deeps:CreateMainFrame()
	-- main frame:
	
  -- CurrentTab (the currently selected tab frame (from this.Tabs) 
  -- MainFrame  (this frame)
  
	-- SpecLabel     shows the current spec
	-- TabSelectors  the tab control
	-- SpellsTab     
	-- SlotsTab
	-- ConditionsTab
  -- Footer     	 contains the close button

  --[[

    +-------------------------------------+
    | SpecLabel                           | <- header
    +-------------------------------------+
    |[Spells] [Slots] [Conditions]        | <- tabs
    +-------------------------------------+   
    |                                     |   
    |    <depends on the selected tab>    | <- main   
    |                                     |   
    |                                     |
    |                                     |
    +-------------------------------------+
    |                             [Close] | <- footer
    +-------------------------------------+

  ]]
  
	local this = self
  
  -- main frame

	local frame = AceGUI:Create("Window")
	frame:SetTitle("Deeps")
	frame:SetWidth(600)
	frame:SetHeight(500)
	SetMinSize(frame.frame, 600, 500);
	frame:SetCallback("OnClose", function(widget) widget:Hide() end)
  frame:SetLayout("None")
	self.MainFrame = frame
	frame.frame:Show()

	local header = AceGUI:Create(CONTAINER)
	header:SetLayout("Fill")
	header:SetAutoAdjustHeight(false)
	header:SetFullWidth(true)
	header:SetHeight(40)
	frame:AddChild(header)
	SetPoints(header, "TOP", "LEFT", "RIGHT")
	self.SpecLabel = self:CreateHeader(header)

  
  local tabs = AceGUI:Create(CONTAINER)
	tabs:SetLayout("Fill")
	tabs:SetAutoAdjustHeight(false)
	tabs:SetHeight(30)
	tabs:SetFullWidth(true)
	frame:AddChild(tabs)
	SetPoints(tabs, "LEFT", "RIGHT", {"TOP", header.frame, "BOTTOM"})
	self.TabSelectors = self:CreateTabSelectors(tabs)

  local main = AceGUI:Create(CONTAINER)
	main:SetLayout("None")
	main:SetAutoAdjustHeight(false)
	main:SetHeight(500 - 3*30 - 2 * 25) -- full-height - 3 * widgets - 2 * margins 
	main:SetFullWidth(true)
	SetBorder(main, 16)
	frame:AddChild(main)

	SetPoints(main, "LEFT", "RIGHT", {"TOP", tabs.frame, "BOTTOM"})
	self.Main = main

	self.SpellsTab = self:CreateSpellsTab(main)
	self.SlotsTab = self:CreateSlotsTab(main)
	self.ConditionsTab = self:CreateConditionsTab(main)
	self.CuurrentTab = nil
  -- tab panels 
	self.Tabs = {
    prio = self.SpellsTab,
    slots = self.SlotsTab,
    conditions = self.ConditionsTab
	}
	
	for k, c in pairs(self.Tabs) do
		SetPoints(c, {"TOPLEFT", 10, -10}, {"BOTTOMRIGHT", -10, 10})
		c.frame:Hide()
	end
	
  local footer = AceGUI:Create(CONTAINER)
	footer:SetLayout("None")
	footer:SetAutoAdjustHeight(false)
	footer:SetHeight(30)
	footer:SetFullWidth(true)
  frame:AddChild(footer)
	SetPoints(footer, "LEFT", "RIGHT", "BOTTOM")
	self.Footer = self:CreateFooter(footer)

	main:SetPoint("BOTTOM", footer.frame, "TOP")

	return self
end


-------------------------------------------------------------------------------
function Deeps:CreateHeader(container, height)
	-- spec label
	local this = self
  local label = AceGUI:Create("Label")
	label:SetFullWidth(true)
	label:SetHeight(height or 40)
	label:SetFont(FONT, 16, "OUTLINE")
	label:SetColor(252/255, 232/255, 3/255)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("CENTER")
	container:AddChild(label)
	
	label.SetSpecName = function(self, text)
		if not text then text = this.SpecText end
		self:SetText("Priority Rotation for " .. text)
	end
	label:SetSpecName("[Spec name]")
	
	return label
end


-------------------------------------------------------------------------------
function Deeps:CreateTabSelectors(container)
  --- tabs controls
	local this = self
	local tabs = AceGUI:Create(CONTAINER)
	tabs:SetLayout("None")
	container:AddChild(tabs)

	tabs.SelectTab = function(self, id)
    local prev = this.CurrentTab
    local cur = this.Tabs[id]
		if prev then prev:Deactivate() end
		if cur then cur:Activate(container) end
    this.CurrentTab = cur
	end

	local b1 = self:UICreateButton(tabs, "Spells", nil, function(btn) tabs:SelectTab("prio") end)
	local b2 = self:UICreateButton(tabs, "Slots", nil, function(btn) tabs:SelectTab("slots") end)
	local b3 = self:UICreateButton(tabs, "Conditions", nil, function(btn) tabs:SelectTab("conditions") end)

	SetPoints(b2, "CENTER")
	SetPoints(b1, "CENTER", {"RIGHT", b2.frame, "LEFT", -10, 0})
	SetPoints(b3, "CENTER", {"LEFT", b2.frame, "RIGHT", 10, 0})

	return tabs

end


-------------------------------------------------------------------------------
function Deeps:CreateTabSelectorsAceGUITabs(container)
	-- the aceGUI tabs are really ugly
  --- tabs controls
	local this = self
	local tabs = AceGUI:Create("TabGroup")
  tabs:SetFullWidth(true)
  tabs:SetTabs({
    {value ="prio", text ="Spells"}, 
    {value ="slots", text ="Slots"},
    {value ="conditions", text ="Conditions"}
  })
	tabs:SetLayout("Fill")
	container:AddChild(tabs)
	tabs:SetCallback("OnGroupSelected", function(container, event, group)
    local prev = this.CurrentTab
    local cur = this.Tabs[group]
		if prev then prev:Deactivate() end
		if cur then cur:Activate(container) end
    this.CurrentTab = cur
	end)
	
  return tabs

end


-------------------------------------------------------------------------------
function Deeps:CreateFooter(container)
  -- closebutton
  local closebtn = AceGUI:Create("Button")
  closebtn:SetText("Close")
	closebtn:SetWidth(150)
	container:AddChild(closebtn)
	closebtn:ClearAllPoints()
	closebtn:SetPoint("RIGHT", container.content, "RIGHT", -10, 0)
  return closebtn
end


-------------------------------------------------------------------------------
function Deeps:CreatePrioritiesTab()
--[[
 Prio:
 +-------------------+  Spell
 |                 | |  [                        ] [ Find ]
 |                 | |  +--+ 
 |                 | |  |  | <Spell Name>
 |                 | |  +--+ 
 |                 | |  Desciption
 |                 | |  [                                  ]
 |                 | |  [X] Show Key or [       ]
 |                 | |  [X] No Target
 |                 | |  [X] No Range
 |                 | |  [X] Not Instant
 |                 | |  [X] While Moving
 |                 | |  [X] Use range from Spell [         ]
 |                 | |      +-+
 |                 | |      | | Spell
 |                 | |      +-+
 |                 | |  Condition
 |                 | |  +--------------------------------+-+
 |                 | |  |[X] Condition                   | |
 |                 | |  |[X] Condition                   | |
 |                 | |  |[X] Condition                   | |
 |                 | |  |[X] Condition                   | |
 |                 | |  |[X] Condition                   | |
 +-------------------+  |[X] Condition                   | |
       [^] [v] [X] [+]  +--------------------------------+-+
                        [X] All [X] Any [X] None
                                     [   save  ]  [ Cancel ]
       ^                
       +---  [X] +--+ Spell Name
                 |  | Usage description
                 +--+
]]


	--print("creating prio tab")
	local tab = self:UICreateTab("prio")
	tab:SetLayout("Flow")
	--tab:SetUserData("table", {columns={.4, .6}, alignH="fill", alignV="fill", space=5})
	--first col
	--print(">> first col")
	col = AceGUI:Create("InlineGroup") --CONTAINER)
	col:SetLayout("HeaderMainFooter")
	col:SetFullHeight(true)
	col:SetRelativeWidth(0.4)
	col:SetAutoAdjustHeight(false)
	tab:AddChild(col)

  -- first-col > priority list label
	--print(">> first-col > priority list label")
	self:UICreateLabel(col, "Priority List:")
	
	-- first-col > priorities scroll
	--print(">> first-col > priority scroll")
	self.PriorityScroll = self:UICreateScroll(col, 200)

	-- first-col > priority edit buttons
	--print(">> first-col > priority edit buttons")
	local temp = AceGUI:Create(CONTAINER)
	temp:SetLayout("Flow")
	temp:SetHeight(80)
	col:AddChild(temp)
	self.MovePrioUp = self:UICreateButton(temp, "Up", 60)
	self.MovePrioDown = self:UICreateButton(temp, "Down", 70)
	self.CreatePrio = self:UICreateButton(temp, "New", 60)
	self.DeletePrio = self:UICreateButton(temp, "Del", 60)
 

	--second col
	--print(">> second-col")
	col = AceGUI:Create(CONTAINER)
	col:SetLayout("None")
	col:SetFullHeight(true)
	col:SetRelativeWidth(0.6)
	col:SetAutoAdjustHeight(false)
	tab:AddChild(col)

	local scroll = self:UICreateScroll(col)
	self.PriorityEditScroll = scroll

	scroll:SetAutoAdjustHeight(false)
	scroll:ClearAllPoints()
	scroll:SetPoint("TOPLEFT", col.content)
	scroll:SetPoint("BOTTOMRIGHT", col.container, "BOTTOMRIGHT", 0, -80)

	scroll.scroll:SetLayout("List")

	self.FindSpell = self:UICreateTextBox(scroll, "Find", false)
	
	
	-- second-col > spell info (icon + spell name)
	
	-- second-col > description
	--print(">> second-col > description")
	self.PrioDescription = self:UICreateMultilineTextBox(scroll, "Description")
	
	-- second-col > flags
	-- print(">> second-col > flags")
	self.PrioShowKey = self:UICreateCheckBox(scroll, "Show Key")
	self.PrioNoTarget = self:UICreateCheckBox(scroll, "No Target")
	self.PrioNoRange = self:UICreateCheckBox(scroll, "No Range")
	self.PrioNotInstant = self:UICreateCheckBox(scroll, "Not Instant")
	self.PrioWhileMoving = self:UICreateCheckBox(scroll, "While Moving")

	-- second-col > label for conditions
	--print(">> second-col > conditions")
  self:UICreateLabel(scroll, "Conditions")

	-- second-col > condition list
	local condition = AceGUI:Create(CONTAINER)
	condition:SetLayout("Fill")
	condition:SetAutoAdjustHeight(false)
	condition:SetRelativeWidth(1)
	condition:SetHeight(100)
	scroll.scroll:AddChild(condition)
  self.PriorityConditions = self:UICreateScroll(condition)
	

	-- second-col > save button
	--print(">> second-col > save btn")


	local save = self:UICreateButton(col, "Save")
	save:ClearAllPoints()
	save:SetPoint("BOTTOMRIGHT", col.content, "RIGHT", -10, -20)
	
	self.SavePrio = save

	return tab
end



-------------------------------------------------------------------------------
function Deeps:CreateSpellsTab(container)
	local tab = self:UICreateTab("spells")
	tab:SetLayout("None")

	local select = self:UICreateListSelector(tab, "Spell Priorities")
	SetPoints(select, "TOP", "LEFT", {"RIGHT", tab.frame, "CENTER"}, "BOTTOM")
	
	container:AddChild(tab)
	return tab
end


-------------------------------------------------------------------------------
function Deeps:CreateConditionsTab(container)
	--print("creating conditions tab")
  local tab = self:UICreateTab("conditions") 
	self:UICreateLabel(tab, "Conditions Tab")
	container:AddChild(tab)
	return tab
end


-------------------------------------------------------------------------------
function Deeps:CreateSlotsTab(container)
	--print("creating slots tab")
	local tab = self:UICreateTab("slots")
	self:UICreateLabel(tab, "Slots Tab")
	container:AddChild(tab)
	return tab
end



-------------------------------------------------------------------------------
function Deeps:UICreateTextBox(container, label, showOkButton)
  local item = AceGUI:Create("EditBox")
  item:SetFullWidth(true)
  if label then item:SetLabel(label) end
  item:DisableButton(not showOkButton)
  container:AddChild(item)
  return item
end


-------------------------------------------------------------------------------
function Deeps:UICreateMultilineTextBox(container, label, showOkButton, numlines)
  local item = AceGUI:Create("MultiLineEditBox")
  item:SetFullWidth(true)
  if label then item:SetLabel(label) end
	item:DisableButton(not showOkButton)
	item:SetNumLines(numlines or 3)
  container:AddChild(item)
  return item
end


-------------------------------------------------------------------------------
function Deeps:UICreateDropdown(container, label, onSelect)
	local item = AceGUI:Create("Dropdown")
	if label then item:SetLabel(label) end
	if onSelect then item:SetCallback("OnValueChanged", onSelect) end
	item:SetFullWidth(true)
	container:AddChild(item)
	return item
end


-------------------------------------------------------------------------------
function Deeps:UICreateLabel(container, label)
	local item = AceGUI:Create("Label")
	item:SetFullWidth(true)
	item:SetText(label)
	container:AddChild(item)
	return item
end


-------------------------------------------------------------------------------
function Deeps:UICreateButton(container, text, width, onChange)
	local item = AceGUI:Create("Button")
	item:SetText(text)
	item:SetWidth(width or 100)
	if onChange then item:SetCallback("OnClick", onChange) end
	container:AddChild(item)
	return item
end


-------------------------------------------------------------------------------
function Deeps:UICreateCheckBox(container, label)
	local item = AceGUI:Create("CheckBox")
	item:SetFullWidth(true)
	item:SetLabel(label)
	container:AddChild(item)
	return item
end


-------------------------------------------------------------------------------
function Deeps:UICreateScroll(container, height, onScroll)
	local item = AceGUI:Create(CONTAINER)
	item:SetFullWidth(true)
	item:SetHeight(height or 100)
	item:SetAutoAdjustHeight(false)
	item:SetLayout("Fill")
	SetBorder(item, 16)
	container:AddChild(item)
	
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	item:AddChild(scroll)
	
	item.scroll = scroll
	return item
end


-------------------------------------------------------------------------------
function Deeps:UICreateTab(id)
	local tab = AceGUI:Create(CONTAINER)
	tab.TabId = id
	tab:SetFullWidth(true)
	tab:SetFullHeight(true)
	tab:SetLayout("Flow")

	function tab:Activate(container)
		local frame = self.frame;
		frame:ClearAllPoints()
		frame:Show()
		frame:SetPoint("TOPLEFT")
		frame:SetPoint("BOTTOMRIGHT")
		return self
	end

	function tab:Deactivate()
		self.frame:Hide()
		return self
	end
	
	return tab
end


-------------------------------------------------------------------------------
function Deeps:UICreateListSelector(container, label)
--[[
	* creates a control to select, order, add and remove elements
	label
	+-----------------------+-+
	|                       | | <- scroll box 
	|                       | |
	|                       | |
	+-----------------------+-+
	[up][down][del][add]        <- buttons

	api:
	- AddChild(item) 
		adds a child to the list of items; the child may have to draw itself

	- RemoveChild(index) 
		removes the child given by index
		
	- SetCurrentIndex(index)
		specifies the index of the 'current' item

	- GetCurrentIndex()
		returns the index of the 'current' item

	
		
	events:
	- OnUp()
		triggered when the up button is clicked
	- OnDown()
		triggered when the down button is clicked
	- OnAdd()
		triggered when the add button is clicked
	- OnDel()
		triggered when the del button is clicked
]]

	local main = AceGUI:Create(CONTAINER)
	main:SetLayout("None")

	local label = self:UICreateLabel(main, label or "Selecione:")
	label:SetFont(FONT, 14)
	label:SetHeight(20)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("CENTER")
	local scroll = self:UICreateScroll(main)
	local slist = scroll.scroll

	local upbtn = self:UICreateButton(main, "Up", 70, function() main:Fire("OnUp", main.currentIndex) end )
	local downbtn = self:UICreateButton(main, "Down", 70, function() main:Fire("OnDown", main.currentIndex) end )
	local addbtn = self:UICreateButton(main, "Add", 70, function() main:Fire("OnAdd", main.currentIndex) end )
	local delbtn = self:UICreateButton(main, "Del", 70, function() main:Fire("OnDel", main.currentIndex) end )

	main.currentIndex = nil
	main.label = label
	main.scroll = scroll
	main.slist = slist
	main.upbtn = upbtn
	main.downbtn = downbtn
	main.addbtn = addbtn
	main.delbtn = delbtn

	main.SetCurrentIndex = function(self, index)
		self.currentIndex = index
		return self
	end

	main.GetCurrentIndex = function(self)
		return self.currentIndex
	end

	main.AddItem = function(self, item)
		self.slist:AddChild(item)
		return #(self.slist.children)
	end

	main.GetItem = function(self, index)
		return self.slist.children[index]
	end

	main.RemoveItem = function(self, index)
		local list =  self.slist.children
		local item = list[index]
		list[index] = nil
		AceGUI:Release(item)
		return self
	end

	SetPoints(label, "TOP", "LEFT", "RIGHT")
	SetPoints(scroll, "LEFT", "RIGHT", {"TOP", label.frame, "BOTTOM"})
	local prev = main
	for i, btn in pairs({upbtn, downbtn, addbtn, delbtn}) do
		SetPoints(btn, 
			{"BOTTOM", main.frame},
			{"LEFT", prev.frame, (prev == main and "LEFT") or "RIGHT"}
		)
		--btn:ClearAllPoints()
		--btn:SetPoint("BOTTOM", main.frame)
		--btn:SetPoint("LEFT", (prev and prev.frame) or main.frame, (prev and "RIGHT") or "LEFT")
		prev = btn
	end
	scroll:SetPoint("BOTTOM", upbtn.frame, "TOP")

	container:AddChild(main)
	return main
end
	

-------------------------------------------------------------------------------
function Deeps:dump(what)
	local function info(item, shallow)
		local t = type(item)
		if t ~= "table" or shallow then return tostring(item) end
		local ret = {}
		local n = 1
		for k, v in pairs(item) do
			ret[n] = " " .. tostring(k) .. ": " .. info(v, true)
			n = n + 1
		end
		return ret
	end

	local t = info(what)
	if type(t) == "table" then
		for i, v in ipairs(info(what)) do
			print(v)
		end
	else
		print(" >> " .. t)
	end
end

Deeps.SetBorder = SetBorder
Deeps.SetPoints = SetPoints
