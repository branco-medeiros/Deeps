local Peg = LibStub:NewLibrary("LibPeg-1.0", 0)

if not Peg then return end


local function seq(list, ctx)
	for it in ipairs(list) do
		local result = it:matches(ctx)
		if result:failed() then return result end
		ctx = result
	end
	return ctx
end

local function alt(list, ctx)
	local bad = nil
	for it in ipairs(list) do
		local result = it:matches(ctx:clone()) 
		if result:succeeded() then return result end
		if not bad or result.position > bad.position then bad = result end
	end
	if not bad then bad = ctx:fail() end
	return bad
end

local function iterate(min, max, action, ctx)
	local temp = nil
	local count = 0
	local p = ctx.position
	while true do
		local result = action:matches(ctx:clone())
		if result:failed() then break end
		
		ctx = result
		
		count = count + 1
		if max and count >= max then break end
		
		local p2 = ctx.position
		if p2 == p then break end
		p = p2
	end
	
	if min and count < min then return ctx:fail() end
	return ctx
end

local function lit(value, ctx)
	local cur = ctx:current()
	if not cur then return ctx:fail() end
	if value.equals(cur) then
		ctx:moveNext()
		return ctx:succeed()
	end
	return ctx:fail()
end

local function any(ctx)
	if ctx:finished() then return ctx:fail() end
	ctx:moveNext()
	return ctx
end

local function epsilon(ctx)
	return ctx
end

local function ensure(action, ctx)
	local result = action:matches(ctx:clone())
	if result:failed() then ctx:fail() end
	return ctx
end

local function prevent(action, ctx)
	local result = action:matches(ctx:clone())
	if result:succeeded() then ctx:fail() end
	return ctx
end

local function error(msg, ctx)
	ctx:tag("error"):push(msg)
	return ctx:fail()
end

local function capture(name, action, ctx)
	local capinfo = {id=name, start = ctx.position}
	local tag = ctx:tag("cap")
	tag:push(capinfo)
	ctx = action:matches(ctx)
	if not ctx:failed() then
		capinfo.stop = ctx.position
	else
		tag:pop()
	end
	return ctx
end

--------------------------------------------------------------------------------
-- rule
--------------------------------------------------------------------------------

local function rule(name)
	local rl = {}
	rl.name = name
	
	function rl:matches(ctx)
		ctx:on({rule=self, ctx = ctx, event=Peg.ENTER})
		if self.matcher then 
			ctx = self.matcher:matches(ctx)
		else
			ctx = error("Rule " .. self.name .. " has no matcher", ctx)
		end
		ctx:on({rule=self, ctx =  ctx, event=Peg.LEAVE})
		return ctx
	end
	
	function rl:assign(matcher)
		self.matcher = matcher
		return self
	end
	
	function rl:isNamed(value)
		return self.name == value
	end
end

--------------------------------------------------------------------------------
-- grammar
--------------------------------------------------------------------------------

local function grammar()

	local gr = {rules = {}}
	
	function gr:rule(name)
		if not name then 
			return self.defaultRule
		end
		
		local rl = self.rules[name]
		if not rl then
			rl = rule(name)
			self.rules[name] = rl
		end
		if not self.defaultRule then self.defaultRule = rl end
		return rl
	end
end


--------------------------------------------------------------------------------
-- stack
--------------------------------------------------------------------------------

local function stack()
	local stk = {
		node = {prev=nil, value=nil, index = 1}
	}
	
	function stk:eachNode(fn)
		local cur = self.node
		while cur do
			local v = fn(cur)
			if v then break end
			cur = cur.prev
		end
		return cur
	end
	
	function stk:findNode(index)
		if not index or index == 0 then return self.node end
		if index < 0 then index = self.node.index + index end
		if index < 0 or index > self.node.index then return nil end
		return self:eachNode(function(n) return n.index == index end)
	end	
	
	function stk:push(value)
		if self.node.value then 
			self.node = {prev = self.node, value=value, index = self.node.index+1}
		else
			self.node.value = value
		end
		return self
	end
	
	function stk:pop(index)
		local node = self:finNode(index)
		if not node then return nil end
		local v = node.value
		if node.prev then node = node.prev else node.value = nil end
		self.node = node
		return v
	end
	
	function stk:peek(index)
		local node = self:findNode(index)
		return (node and node.value) or nil
	end
	
	
	function stk:index()
		return self.node.index
	end
	
	function stk:each(fn)
		self:eachNode(function(n) return fn(n.value, n.index) end)
		return self
	end
	
	function stk:toArray()
		local t = {}
		self:eachNode(function(n) t[n.index] = n.value end)
		return t
	end
	
	function clone()
		local c = stack()
		c.node.prev = self.node.prev
		c.node.value = self.node.value
		c.node.index = self.node.index
		return c
	end
	
	return stk
end


--------------------------------------------------------------------------------
-- context
--------------------------------------------------------------------------------

local function context(source)

	local ctx = {
		tags = {},
		position = 0
	}
	
	local tp = type(source)
	if tp == "string" then
		function ctx:at(pos)
			return string.sub(self.source, pos, pos)
		end
		
		function ctx:sub(first, last)
			return string.sub(self.source, first, last)
		end
		
		ctx.source = source
	else
		function ctx:at(pos)
			return self.source[pos]
		end
		
		function ctx:sub(first, last)
			return table.unpack(self.source, first, last)
		end
		
		ctx. source = (tp == "table" and source) or {source}
	end
	
	
	function ctx:tag(key)
		local t = self.tags[key]
		if not t then 
			t = stack()
			self.tags[key] = t
		end
		return t
	end
	
	function ctx:fail()
		self.failed = true
		return self
	end
	
	function ctx:succeed()
		self.failed = false
		return self
	end
	
	function ctx:failed()
		return self.failed == true
	end
	
	function ctx:succeeded()
		return not self.failed
	end
	
	function ctx:current()
		return self:at(self.position)
	end
	
	function ctx:finished()
		return self.position >= #source
	end
	
	function ctx:moveNext()
		if self.position >= #source then return false end
		self.position = self.position + 1
		return true
	end
	
	function ctx:on(data)
		if self.listeners then
			for i, fn in ipairs(self.listeners) do
				fn(data)
			end
		end
		return self
	end
	
	function ctx:slice(first, last)
		if not last then
			local p = self.position
			last = (p < first and #source) or p
		end
		return self:sub(first, last)
	end
	
	
	function ctx:clone()
		return context(self.source):assing(self)
	end
	
	function ctx:assign(other)
		if not other then return end
		self.position = other.position
		selft.failed = other.failed
		self.listeners = other.listeners
		self.tags = {}
		for k, t in pairs(other.tags) do
			self.tags[k] = t:clone()
		end
		return self
	end
	
	return ctx
end

--------------------------------------------------------------------------------
-- utilities
--------------------------------------------------------------------------------


local function AsMatcher(value)
	if value.matches and type(value.matches) == "function" then return value end
	return Peg:lit(value)
end

local function AsMatcherList(...)
	local result = {}
	for i, v in ipairs({...}) do
		tinsert(result, AsMatcher(v))
	end
	return result
end

local function isContext(value)
	return value and 
		value.tags and 
		value.source and 
		value.at and 
		value.moveNext and 
		value.current and 
		true
end

local Any = {
	matches = any
}

local Epsilon = {
	matches = epsilon
}
		
--------------------------------------------------------------------------------
-- Peg
--------------------------------------------------------------------------------

		
function Peg:seq(...)
	local args = AsMatcherList(...)
	return {
		matches = function(ctx)
			return seq(args, ctx)
		end
	}
end

function Peg:alt(...)
	local args = AsMatcherList(...)
	return {
		matches = function(ctx)
			return alt(args, ctx)
		end
	}
end

function Peg:opt(Matcher)
	Matcher = AsMatcher(Matcher)
	return {
		matches=function(ctx)
			return iterate(false, 1, Matcher, ctx)
		end
	}
end

function Peg:star(Matcher)
	Matcher = AsMatcher(Matcher)
	return {
		matches=function(ctx)
			return iterate(false, false, Matcher, ctx)
		end
	}
end

function Peg:plus(Matcher)
	Matcher = AsMatcher(Matcher)
	return {
		matches=function(ctx)
			return iterate(1, false, Matcher, ctx)
		end
	}
end

function Peg:lit(value)

	if value == nil then
		
		value = {
		 equals = function() return false end
		}
		
	elseif type(value) == "function" then
		
		local fn = value
		value = {
			equals = function(v) return fn(v) end
		}
	
	elseif not value.equals or type(value.equals) ~= "function" then
	
		local v1 = value
		value = {
			equals = function(v2)
				return v1 == v2
			end
		}
	end
	
	return {
		matches = function(ctx)
			return lit(value, ctx)
		end
	}
end

function Peg:is(Matcher)
	Matcher = AsMatcher(Matcher)
	return {
		matches=function(ctx)
			return ensure(Matcher, ctx)
		end
	}
end

function Peg:isnot(Matcher)
	Matcher = AsMatcher(Matcher)
	return {
		matches=function(ctx)
			return prevent(Matcher, ctx)
		end
	}
end

function Peg:any()
	return Any
end

function Peg:epsilon()
	return Epsilon
end

function Peg:grammar()
	return grammar()
end

function Peg:rule(name)
	return rule(name)
end

function Peg:context(source)
	return (isContext(source) and source) or context(source)
end

--------------------------------------------------------------------------------
-- matching functions
--------------------------------------------------------------------------------
local Matcher = {}
function Matcher:match(peg, value)
	
end

return {
	Matcher = Matcher,
	Peg = Peg,
	Stack = stack,
	Context = context
}

