args = ...

local Deeps = LibStub("AceAddon-3.0"):NewAddon(
	"Deeps", 
	"AceConsole-3.0", 
	"AceEvent-3.0"
)
local Config = LibStub("AceConfig-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local options = {
	name="Deeps",
	handler=Deeps,
	type="group",
	args = {
		list = {
			type="execute",
			name="List",
			desc="Lists the spell priorities used",
			func="CmdList"
		},
		
		debug = {
			type="toggle",
			name="Debug",
			desc="Enables/Disables the action priority debugging",
			get="getDebugging",
			set="setDebugging"
		}
		
	}

}

Deeps.debugging = false

function Deeps:OnInitialize()
	self:Print("Addon initializing...")
	Config:RegisterOptionsTable("Deeps", options, {"deeps", "dps"})
end


function Deeps:OnEnable()
	self:Print("Addon enabled...")
end

function Deeps:OnDisable()
	self:Print("Addon Disabled...")
end

function Deeps:CmdList()
	self.Print("CmdList called")
end

function Deeps:getDebugging()
	return self.debugging
end

function Deeps:setDebugging(value)
	self.debugging = value
end


function Deeps:initializeUI()
	local frame = AceGUI:Create("Window")
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	self.MainFrame = frame
	frame:SetLayout("Flow")
	
	local LeftFrame = AceGUI:Create("SimpleGroup")
	LeftFrame:SetRelativeWidth(0.5)
	LeftFrame:SetFullHeight(true)
	frame:AddChild(LeftFrame)
	
	local RightFrame = AceGUI:Create("SimpleGroup")
	RightFrame:SetRelativeWidth(0.5)
	RightFrame:SetFullHeight(true)
	frame:AddChild(RightFrame)
	
	LeftFrame:SetLayout("List")
	
	local w = AceGUI:Create("Label")
	w:SetText("Spec")
	w:SetFullWidth(true)
	LeftFrame:AddChild(w)
	
	w = AceGUI:Create("DropdownGroup")
	w:SetFullWidth(true)
	LeftFrame:AddChild(w)
	self.SpecList = w
	
	w = AceGUI:Create("Label")
	w:SetText("Priority List")
	w:SetFullWidth(true)
	LeftFrame:AddChild(w)
	
	local container = AceGUI:Create("SimpleGroup")
	container:SetFullWidth(true)
	container:SetLayout("Fill")
	container:SetHeight(100)
  LefFrame:AddChild(container)

	w = AceGUI:Create("ScrollFrame")
	w:SetLayout("List")
	container:AddChild(w)
	self.PriorityList = w
	
	
	
	
	
end

