args = ...

local DEEPS = "Deeps"
local DEEPS_DB = "DeepsDB"
local DEEPS_CMD = "deeps"
local DPS_CMD = "dps"

local Deeps = LibStub("AceAddon-3.0"):NewAddon(
	DEEPS, 
	"AceConsole-3.0", 
	"AceEvent-3.0"
)
_G.Deeps = Deeps
local Config = LibStub("AceConfig-3.0")
local AceGUI = LibStub("AceGUI-3.0")

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
  self.db = LibStub("AceDB-3.0"):New(DEEPS_DB, defaults, true)
  self:Debug("Addon initializing")
  Config:RegisterOptionsTable(DEEPS, options, {DEEPS_CMD, DPS_CMD})
	self:RegisterChatCommand(DEEPS_CMD, "HandleCommand")
	self:RegisterChatCommand(DPS_CMD, "HandleCommand")
end

function Deeps:OnEnable()
	self:Debug("Addon enabled...")
  self:InitializeUI()
	self:OnSpecChange()
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
  if(value ~= nil) self.db.profile.debug = value
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

  self.SpecLabel:SetText(self.SpecName)
  
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
  -- main frame
  -- CurrentTab (the currently selected tab frame (from this.Tabs) 
  -- MainFrame  (this frame)
  -- SpecLabel  (contaians the spec text)
  -- TabGroup   (the actual tab control)
  -- Tabs       (dict with each tab content)
  --[[

    +-------------------------------------+
    | SpecLabel                           |
    +-------------------------------------+
    |[Spells] [Slots] [Conditions]        |
    +-------------------------------------+
    |                                     |
    |    <depends on the selected tab>    |
    |                                     |
    |                                     |
    |                                     |
    +-------------------------------------+
    |                             [Close] |
    +-------------------------------------+

  ]]
  
	local this = self
  
  -- main frame

	local frame = AceGUI:Create("Window")
	frame:SetTitle("Deeps")
	frame:SetWidth(600)
	frame:SetHeight(500)
	frame:SetCallback("OnClose", function(widget) widget:Hide() end)
  frame:SetLayout("Flow")
	self.MainFrame = frame

  -- spec label

  local label = AceGUI:Create("Label")
  label:SetFullWidth(true)
  label:SetFontObject(GameFontHilightLarge)
  frame:AddChild(label)
  self.SpecLabel = label


  --- tabs controls

	local tabs = AceGUI:Create("TabGroup")
  tabs:SetFullWidth(true)
  tabs:SetTabs({
    {value ="prio", text ="Spells"}, 
    {value ="slots", text ="Slots"},
    {value ="conditions", text ="Conditions"}
  })
	tabs:SetLayout("Flow")
	frame:AddChild(tabs)
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
    conditions = self.CreateConditionsTab()
  }

	frame:Hide()
	
end

function Deeps:GetClassId(class, id)
  return class .. '-' .. id
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


	local tab = self:CreateTab("prio")
	
	--first col
	col = AceGUI:Create("SimpleGroup")
	col:SetWidth(250)
	col:SetFullHeight(true)
	col:SetLayout("Flow")
	tab:AddChild(col)

	self:CreateLabel(col, "Priority List")
	self.PriorityScroll = self:CreateScroll(col, 200)
	self.MoveUp = self:CreateButton(col, "Move Up")
	self.MoveDown = self:CreateButton(col, "Move Down")

	--second col
	col = AceGUI:Create("SimpleGroup")
	col:SetWidth(250)
	col:SetFullHeight(true)
	col:SetLayout("Flow")
	tab:AddChild(col)
	
	self.PriorityName = self:CreateEditControl(col, "Name")
  self.PrioritySpells = self:CreateDropdownControl(col, "Spell")
  self:CreateLabel(col, "Conditions")
  self.PriorityConditions = self:CreateScroll(col)
  self.SavePrio = self:CreateButton(col, "Save")
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

function Deeps:CreateScroll(container, height, onScroll)
	local item = AceGUI:Create("SimpleGroup")
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
	local tab = AceGUI:Create("SimpleGroup")
	tab.TabId = id
	tab:SetFullWidth(true)
	tab:SetLayout("Flow")

	function tab:Activate(container)
		container:AddChild(self)
		self.frame:Show()
		return self
	end
	
	function tab:Deactivate()
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
		return self
	end
	
	return tab
end


