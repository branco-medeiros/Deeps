args = ...

local DEEPS = "Deeps"
local DEEPS_DB = "DeepsDB"
local DEEPS_CMD = "deeps"
local DPS_CMD = "dps"
local CONTAINER = "SimpleGroup"

local DEFAULT_BDR_TEX = 'Interface\\DialogFrame\\UI-DialogBox-Background-Dark'

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

local function FinishLayout(content, height)
	if content.obj.LayoutFinished then 
		content.obj:LayoutFinished(nil, height) 
	end
end


local function SetBorder(frame, size, r, g, b)
  if frame.frame and not frame.SetBackdrop then frame = frame.frame end
  if not size or size == 0 then
    frame:SetBackdrop({edgeFile = nil, edgeSize = 0})
  else
    frame:SetBackdrop({edgeFile=DEFAULT_BDR_TEX, edgeSize=size})
    frame:SetBackdropBorderColor(r or 0, g or 0, b or 0)
  end --if
end -- fn Icon_SetBorder


AceGUI:RegisterLayout("None", function(content, children)
	FinishLayout(content)
end)

AceGUI:RegisterLayout("HeaderMainFooter",
	function(content, children)
    local last = #children
		local width = GetFrameWidth(content)
		local height = GetFrameHeight(content)
		local clientheight = height
		local itemheight = 0
		for i = 1, last do
			local j = (i == 1 and i) or (i == 2 and last) or i-1 
			local child = children[j]
			local frame = child.frame
			local done = false
			frame:ClearAllPoints()
			frame:Show()
			frame:SetWidth(width)
			frame:SetPoint("LEFT", content)
			frame:SetPoint("RIGHT", content)
			height = GetFrameHeight(frame)
			
			if j == 1 then
				frame:SetPoint("TOP", content)
				clientheight = clientheight - height
				done = true
			end
			
			if j == last then
				frame:SetPoint("BOTTOM", content)
				if not done then 
					clientheight = clientheight - height
					if last > 2 then itemheight = clientheight / (last-2) end
				end
				done = true
			end

			if not done then
				frame:SetHeight(itemheight)
				frame:SetPoint("TOP", children[j-1].frame, "BOTTOM")
			end
			if child.DoLayout then child:DoLayout() end
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

function Deeps:Debug(...)
  if self:debugging() then self:Print(...) end
end

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

function Deeps:OnEnable()
	self:Debug("Addon enabled...")
  self:InitializeUI()
	self:OnSpecChange()
	--self.TabGroup:SelectTab("prio")
end

function Deeps:OnDisable()
	self:Debug("Addon Disabled...")
end

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


-- comands

function Deeps:HandleCommand(input)
  self:Debug("Handle Command", input)
  if not input or input:trim() == "" then
    self:ShowMainWindow()
  else
    LibStub("AceConfigCmd-3.0"):HandleCommand(DEEPS_CMD, DEEPS, input)
  end
end

function Deeps:ShowMainWindow()
  self.MainFrame:Show()
end

function Deeps:ShowCommands()
	self:Print("CmdList called")
end

function Deeps:debugging(value)
  if(value ~= nil) then self.db.profile.debug = value end
	return self.db.profile.debug
end

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

function Deeps:GetDefaultSettings()
  return {
    profile = {
      debug = false,
      specs = {}
    }
  }
end

function Deeps:Reload()
  -- fills the interface with the specified spec data

  self.SpecLabel:SetText(self.SpecText)
	self.TabGroup:SelectTab("prio")

	-- clear editors
end

function Deeps:ClearUI()
  self:SelectPriority(nil)
  self:SelectSpell(nil)
  self:SelectCondition(nil)
  self:SelectSlot(nil)

  self.PriorityScroll:ReleaseChildren()
  self.SpellScroll:ReleaseChildren()
  self.ConditionsScroll: ReleaseChildren()
  self.SlotsScroll:ReleaseChildrent()
end

function Deeps:SelectPriority(value)
  self.Priority = value
  self.PriorityName:SetText((value and value.name ) or '')
  self.PrioritySpell:SetText((value and value.spell) or '')


end

function Deeps:InitializeUI()

 if not self.MainFrame then
		self:CreateMainFrame()
		-- register the main frame to closwe with ESC
		_G["Deeps.Frame"] = self.MainFrame
		tinsert(UISpecialFrames, "Deeps.Frame")
 end
end

function Deeps:GetClassId(class, id)
  return class .. '-' .. id
end


function Deeps:CreateMainFrame()
  -- main frame
  -- CurrentTab (the currently selected tab frame (from this.Tabs) 
  -- MainFrame  (this frame)
  
  -- Header     (the header)
  -- Main       (the tab container)
  -- Footer     (the footer)
  
  -- SpecLabel  (contaians the spec text)
  -- TabGroup   (the actual tab control)
  -- Tabs       (dict with each tab content)

  --[[

    +-------------------------------------+
    | SpecLabel                           | <- header
    +-------------------------------------+
    |[Spells] [Slots] [Conditions]        | <- main
    +-------------------------------------+   
    |                                     |   
    |    <depends on the selected tab>    |   
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
	frame:SetCallback("OnClose", function(widget) widget:Hide() end)
  frame:SetLayout("HeaderMainFooter")
	self.MainFrame = frame

  local header = AceGUI:Create(CONTAINER)
  header:SetLayout("Fill")
  header:SetHeight(30)
	header.frame:SetBackdropColor(0.5, 0, 0, 1)
  frame:AddChild(header)
  self.Header = header
  
  local main = AceGUI:Create(CONTAINER)
  main:SetLayout("Fill")
	main.frame:SetBackdropColor(0, 0.5, 0, 1)
  frame:AddChild(main)
  self.Main = main
  
  local footer = AceGUI:Create(CONTAINER)
  --footer:SetLayout("Table")
	--footer:SetUserData("table", {columns= {1}, space=10, alignH="RIGHT", alignV="CENTER"})
	footer:SetLayout("None")
	footer:SetAutoAdjustHeight(false)
  footer:SetHeight(30)
  frame:AddChild(footer)
  self.Footer = footer
  
  -- spec label

  local label = AceGUI:Create("Label")
  label:SetFullWidth(true)
  label:SetFontObject(GameFontHilightLarge)
  header:AddChild(label)
  label:SetText("Spec name...")
  self.SpecLabel = label


  --- tabs controls

	local tabs = AceGUI:Create("TabGroup")
  tabs:SetFullWidth(true)
  tabs:SetTabs({
    {value ="prio", text ="Spells"}, 
    {value ="slots", text ="Slots"},
    {value ="conditions", text ="Conditions"}
  })
	tabs:SetLayout("Fill")
	main:AddChild(tabs)
	tabs:SetCallback("OnGroupSelected", function(container, event, group)
    local prev = this.CurrentTab
    local cur = this.Tabs[group]
		if prev then prev:Deactivate() end
		if cur then cur:Activate(container) end
    this.CurrentTab = cur
	end)
  self.TabGroup = tabs

  -- tab panels 
	self.Tabs = {
    prio = self:CreatePrioritiesTab(),
    slots = self:CreateSlotsTab(),
    conditions = self:CreateConditionsTab()
  }

  -- closebutton
	
  local closebtn = AceGUI:Create("Button")
  closebtn:SetText("Close")
	closebtn:SetWidth(150)
	footer:AddChild(closebtn)
	closebtn:ClearAllPoints()
	closebtn:SetPoint("RIGHT", footer.content, "RIGHT", -10, 0)

  self.CloseBtn = closebtn
	
	return self


end


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


	-- print("creating prio tab")
	local tab = self:CreateTab("prio")
	tab:SetLayout("Flow")
	--tab:SetUserData("table", {columns={.4, .6}, alignH="fill", alignV="fill", space=5})
	--first col
	-- print(">> first col")
	col = AceGUI:Create("InlineGroup") --CONTAINER)
	col:SetLayout("HeaderMainFooter")
	col:SetFullHeight(true)
	col:SetRelativeWidth(0.4)
	col:SetAutoAdjustHeight(false)
	tab:AddChild(col)

  -- first-col > priority list label
	-- print(">> first-col > priority list label")
	self:CreateLabel(col, "Priority List:")
	
	-- first-col > priorities scroll
	-- print(">> first-col > priority scroll")
	self.PriorityScroll = self:CreateScroll(col, 200)

	-- first-col > priority edit buttons
	-- print(">> first-col > priority edit buttons")
	local temp = AceGUI:Create(CONTAINER)
	temp:SetLayout("Flow")
	temp:SetHeight(80)
	col:AddChild(temp)
	self.MovePrioUp = self:CreateButton(temp, "Up", 60)
	self.MovePrioDown = self:CreateButton(temp, "Down", 70)
	self.CreatePrio = self:CreateButton(temp, "New", 60)
	self.DeletePrio = self:CreateButton(temp, "Del", 60)
 

	--second col
	-- print(">> second-col")
	col = AceGUI:Create("InlineGroup") --CONTAINER)
	col:SetLayout("List")
	col:SetFullHeight(true)
	col:SetRelativeWidth(0.6)
	col:SetAutoAdjustHeight(false)
	tab:AddChild(col)

	-- second-col > find spell 
	-- print(">> second-col > find spell")
	self.FindSpell = self:CreateEditControl(col, "Find", false)
	
	
	-- second-col > spell info (icon + spell name)
	
	-- second-col > description
	-- print(">> second-col > description")
	self.PrioDescription = self:CreateMultilineEditControl(col, "Description")
	
	-- second-col > flags
	-- print(">> second-col > flags")
	self.PrioShowKey = self:CreateCheckBox(col, "Show Key")
	self.PrioNoTarget = self:CreateCheckBox(col, "No Target")
	self.PrioNoRange = self:CreateCheckBox(col, "No Range")
	self.PrioNotInstant = self:CreateCheckBox(col, "Not Instant")
	self.PrioWhileMoving = self:CreateCheckBox(col, "While Moving")

	-- second-col > label for conditions
	-- print(">> second-col > conditions")
  self:CreateLabel(col, "Conditions")

	-- second-col > condition list
	local scrollbox = AceGUI:Create(CONTAINER)
	scrollbox:SetLayout("Fill")
	scrollbox:SetAutoAdjustHeight(false)
	scrollbox:SetRelativeWidth(1)
	scrollbox:SetHeight(100)
	col:AddChild(scrollbox)
  self.PriorityConditions = self:CreateScroll(scrollbox)
	

	-- second-col > save button
	-- print(">> second-col > save btn")

	-- usa a container for the button
	local temp = AceGUI:Create(CONTAINER)
	temp:SetLayout("None")
	temp:SetAutoAdjustHeight(false)
	temp:SetRelativeWidth(1)
	temp:SetHeight(80)
	col:AddChild(temp)

	local save = self:CreateButton(temp, "Save")
	save:ClearAllPoints()
	save:SetPoint("RIGHT", temp.content, "RIGHT", -10, 0)
	
	self.SavePrio = save

	return tab
end


function Deeps:CreateSpellsTab()
	local tab = self:CreateTab("spells")
	self:CreateLabel(tab, "Spells Tab")
	return tab
end


function Deeps:CreateConditionsTab()
  local tab = self:CreateTab("conditions")
  
	self:CreateLabel(tab, "Conditions Tab")
	return tab
end


function Deeps:CreateSlotsTab()
	local tab = self:CreateTab("slots")
	self:CreateLabel(tab, "Slots Tab")
	return tab
end



function Deeps:CreateEditControl(container, label, showOkButton)
  local item = AceGUI:Create("EditBox")
  item:SetFullWidth(true)
  if label then item:SetLabel(label) end
  item:DisableButton(not showOkButton)
  container:AddChild(item)
  return item
end


function Deeps:CreateMultilineEditControl(container, label, showOkButton, numlines)
  local item = AceGUI:Create("MultiLineEditBox")
  item:SetFullWidth(true)
  if label then item:SetLabel(label) end
	item:DisableButton(not showOkButton)
	item:SetNumLines(numlines or 3)
  container:AddChild(item)
  return item
end


function Deeps:CreateDropdownControl(container, label, onSelect)
	local item = AceGUI:Create("Dropdown")
	if label then item:SetLabel(label) end
	if onSelect then item:SetCallback("OnValueChanged", onSelect) end
	item:SetFullWidth(true)
	container:AddChild(item)
	return item
end

function Deeps:CreateLabel(container, label)
	local item = AceGUI:Create("Label")
	item:SetFullWidth(true)
	item:SetText(label)
	container:AddChild(item)
	return item
end

function Deeps:CreateButton(container, text, width, onChange)
	local item = AceGUI:Create("Button")
	item:SetText(text)
	item:SetWidth(width or 100)
	container:AddChild(item)
	return item
end


function Deeps:CreateCheckBox(container, label)
	local item = AceGUI:Create("CheckBox")
	item:SetFullWidth(true)
	item:SetLabel(label)
	container:AddChild(item)
	return item
end


function Deeps:CreateScroll(container, height, onScroll)
	local item = AceGUI:Create("InlineGroup")
	item:SetFullWidth(true)
	item:SetHeight(height or 100)
	item:SetLayout("Fill")
	container:AddChild(item)
	
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	item:AddChild(scroll)
	
	return scroll
end

function Deeps:CreateTab(id)
	local tab = AceGUI:Create(CONTAINER)
	tab.TabId = id
	tab:SetFullWidth(true)
	tab:SetFullHeight(true)
	tab:SetLayout("Flow")

	function tab:Activate(container)
		-- print("tab activate: " .. self.TabId)
		container:AddChild(self)
		local frame = self.frame;
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT")
		frame:SetPoint("BOTTOMRIGHT")
		frame:Show()
		-- print("tab activate: " .. self.TabId .. " > done")
		return self
	end
	
	function tab:Deactivate()
		-- print("tab deactivate: " .. self.TabId)
		if self.parent then
			local idx = 0
			local children = self.parent.children
			for n, c in ipairs(children) do
				if c == self then
					idx = n
					break
				end
			end
			if idx > 0 then table.remove(children, idx) end
			self.frame:SetParent(nil)
			self.parent = nil
		end
		self.frame:Hide()
		-- print("tab deactivate: " .. self.TabId .. " > done")
		return self
	end
	
	return tab
end

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