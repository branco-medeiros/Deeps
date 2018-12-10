main = ...

-- TO DO:
-- 1) ensure that the toggle commands (e.g. /dps debug ) show a message indicating the 
-- 		state change
-- 2) Remove the several initialization messages



Deeps = LibStub("AceAddon-3.0"):NewAddon("Deeps", "AceConsole-3.0", "AceEvent-3.0")
Config = LibStub("AceConfig-3.0")

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
