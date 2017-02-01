--[[Base class for gui stuff
Works as extension over the game-api, takes table with a bunch of fields
passes some to the api, makes use of the remaining ones


--below are fields that are rethrown to game-api when possible:
]]
local api_fields={type=true,name=true,style=true,
sprite=true,state=true,direction=true,caption=true,size=true,value=true,colspan=true}
--apart from these, additional fields can be present for each function,
--only those will be mentioned in comments to functions

local check=function(p)
--checks whether table p is valid for creation of gui object
	if not (p.name and p.type and p.anchor and p.anchor.valid) then
		--debug(p)
	end
end

gui={
	new=function(parameters)
		--[[
		{
		anchor, --initial element from which gui grows, created elsewhere (flow, frame)
		data, --arbitrary data 
		on_close, --destructor function
		on_duplicate, --function to handle duplicates
		on_restore, --function to restore metatables in data
		elements, --a table of parameters for :add() function (elements with handlers)
		children, --a table of parameters for :child() function (so it is possible to define whole gui with one external call)(parent elements)
		update(me,tick), --a function for on_tick handlings
		}
		]]
		local p=parameters
		--check(p)
		
		local anchor=p.anchor
		
		local n=setmetatable({
			name=p.name,
			anchor=anchor,--initial element from which gui grows, created elsewhere (flow, frame)
			data=p.data,--arbitrary data 
			on_close=p.on_close,--destructor function
			on_duplicate=p.on_duplicate,--function to handle duplicates
			on_restore=p.on_restore,
			update=p.update,
			parent=false,--parent object of same class
			blocked_by=false,--a link to other object that prevents this one from working
			children={},--children objects of the same class
			elements={},--buttons, textfields, radiobuttons --the direct children of the anchor
			handlers={},--[[callback functions for elements
				these functions are called with the whole gui object as argument: handler(n,element)
				here 'n' is the encompassing gui object, related to the anchor
				]]
			},gui)
		if p.elements then
			for _,el in pairs(p.elements) do
				n:add(el)
			end
		end
		if p.children then for _,ch in pairs(p.children) do
			n:child(ch)
		end end
		return n
	end,
	restore=function(obj)
		setmetatable(obj,gui)
		for _,c in pairs(obj.children) do gui.restore(c) end
		if obj.on_restore then obj.on_restore(obj) end
	end,
__index={
	add=function(me,par)
	--function for adding any active elements
		--[[
		{name,
		handler,function that gets called when button pressed, text altered ...
			gets encompassing gui object as argument (the data associated with the gui is in 'arg.data'
			and the reference to an object itself)
			must not reference anything outside its scope
			
		}
		]]
		local e_par={}
		for k in pairs(api_fields) do e_par[k]=par[k] end
		local el=me.anchor.add(e_par)
		me.elements[el.name]=el
		if par.handler then me.handlers[el.name]=par.handler end
		return el
	end,
	child=function(me,params)
	--[[
		{
		data, --arbitrary data 
		on_close, --destructor function
		on_duplicate, --function to handle duplicates
		elements, --a table of parameters for :add() function 
		children, --a table of parameters for :child() function (so it is possible to define whole gui with one external call)
		}
		]]
		local dub=me.children[params.name]
		if dub and dub.anchor.valid and dub.on_duplicate then dub:on_duplicate() end
		local e_par={}
		for k in pairs(api_fields) do e_par[k]=params[k] end
		params.anchor=me.anchor.add(e_par)
		--debug(gui)
		local ch=gui.new(params)
		me.children[ch.name]=ch
		ch.parent=me
		return ch
	end,
	destroy=function(me)
	--destroys the gui object
		for _,c in pairs(me.children) do
			c:destroy()
		end
		if me.on_close then me:on_close() end
		me.anchor.destroy()
	end,
	check=function(me,el)
	--service function
		if not me.blocked_by then
			if not me.anchor.valid then return end
			for n, e in pairs(me.elements) do
				if e==el then
					if me.handlers[n] then me.handlers[n](me,el) end
					return
				end
			end
			for _,c in pairs(me.children) do
				c:check(el)
			end
		else
			me.blocked_by:check()
		end
	end,
	on_tick=function(me,tick)
		if not me.anchor.valid then return end
		for _,c in pairs(me.children) do
			if c.update then c:on_tick(tick) end
		end
		me:update(tick)
	end,
	get_top=function (me)
		return me.parent and me.parent:get_top() or me
	end,
}
}
