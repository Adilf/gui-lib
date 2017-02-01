--[[Base class for gui stuff
Works as extension over the game-api, takes table with a bunch of fields
passes some to the api, makes use of the remaining ones


--below are fields that are rethrown to game-api when possible:
]]
local api_fields={type=true,name=true,style=true,
sprite=true,state=true,direction=true,caption=true,size=true,value=true,colspan=true}
--apart from these, additional fields can be present for each function,
--only those will be mentioned in comments to functions


gui={
	new=function(parameters)
		--[[
		{
		anchor, --initial element from which gui grows (flow, frame), created elsewhere, passed here as
		data, --arbitrary data 
		on_close(me), --destructor function if given, called during gui:destroy() after all the children guis are destroyed
		on_duplicate(me), --function to handle duplicates, called when another gui with the same name is already present, if it returns true, the old gui will be kept, otherwise, it should take care of removing that.
		on_restore(me), --function to restore metatables in data during onload, if you can't restore them throug the other references
		elements, --a table of parameters for :add() function (elements with handlers)
		children, --a table of parameters for :child() function (so it is possible to define whole gui with one external call)(parent elements)
		update(me,tick), --a function for on_tick handlings, currently, it is done dirty in gui dispatch, so this function is only executed if all its parents have at least placeholder update function as well.
		}
		]]
		local p=parameters
		
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
		handler=function(gui,object) --a function that gets called when button pressed, text altered ...
			gets encompassing gui object as argument (the data associated with the gui is in 'arg.data'
			and the reference to an object itself (button, textbox, anything)
			This function is serialized, so it should only reference global variables, any upvalue it might need should be stored in gui.data table.		
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
	--[[basically, a call to gui.new, it can handle creation of the anchor element (frame\flow) if you set needed fields (see api_fields) 
		]]
		local dub=me.children[params.name]
		local keep_old
		if dub and dub.anchor.valid and dub.on_duplicate then 
			keep_old=dub:on_duplicate() 
		end
		if not keep_old then
			local e_par={}
			for k in pairs(api_fields) do e_par[k]=params[k] end
			params.anchor=params.anchor or me.anchor.add(e_par)
			local ch=gui.new(params)
			me.children[ch.name]=ch
			ch.parent=me
			return ch
		else
			return dub
		end
	end,
	destroy=function(me)
	--destroys the gui object
		for _,c in pairs(me.children) do
			c:destroy()
		end
		if me.on_close then me:on_close() end
		me.anchor.destroy()
	end,
	check=function(me,el)--service function
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
	on_tick=function(me,tick)--service function
		if not me.anchor.valid then return end
		for _,c in pairs(me.children) do
			if c.update then c:on_tick(tick) end
		end
		me:update(tick)
	end,
	get_top=function(me)--get the topmost gui in the inheritance tree
		return me.parent and me.parent:get_top() or me
	end,
}
}
