--[[Handles the management of gui objects
Most notably, handles the events.
]]
require "gui"

local roots={top=true,left=true,center=true}
gui_dispatch={--singleton as usual
	init=function(handle)
		handle.on_tick=handle.on_tick or {}
		handle.data=handle.data or {}
		gui_dispatch.data=handle.data
		gui_dispatch.updatable=handle.on_tick
		return handle
	end,
	restore=function(handle)
		gui_dispatch.data=handle.data
		gui_dispatch.updatable=handle.on_tick
		for _,player in pairs(handle.data) do 
			for _,g in pairs(player) do 
				gui.restore(g) 
			end
		end
	end,
	tracked_events={--shortcut to event codes
		defines.events.on_gui_checked_state_changed,
		defines.events.on_gui_click,
		defines.events.on_gui_text_changed,
		},
	------
	on_gui_event=function(event)--should be fed  to script on_event
		local me=gui_dispatch
		local pind=event.player_index
		if me.data[pind] then
			for k,g in pairs(me.data[pind]) do 
				if g.anchor.valid then 
					g:check(event.element) 
				else
					me.data[pind][k]=nil
				end
			end
		end
	end,
	on_tick=function(event)
		local tick=event.tick
		local gs=gui_dispatch.updatable
		for i= #gs,1,-1 do
			local g=gs[i]
			if g.anchor.valid then g:on_tick(tick)
			else table.remove(gs,i)
			end
		end
		--for _,p in pairs(gui_dispatch.updatable) do
			--for k,g in pairs(p) do
				--if g.anchor.valid then g:on_tick(tick)
				--else p[k]=nil
				--end
			--end
		--end
	end,
	open=function(parameters)--creates the root element of a gui and starts gui growth
		--[[ 
		parameters={
			player_index,
			name,--!mandatory
			root,--!mandatory
			type,--!mandatory
			style,
			data,
			on_close,
			on_duplicate,
			on_tick,--should be in all parents of elements that are updated
			elements,
			children,
			}
			this table is rethrown downstream to gui.new() function
		]]
		--sdb(global)
		local me=gui_dispatch
		local pind=parameters.player_index
		local name=parameters.name
		me.data[pind]=me.data[pind] or {}
		
		::retry::--this is label for goto
		if me.data[pind][name] and me.data[pind][name].anchor.valid then
			if me.data[pind][name].on_duplicate then 
				--local abort=me.data[pind][name]:on_duplicate(_ENV)--guis can handle teir duplicates gracefully
				local abort=me.data[pind][name]:on_duplicate()--guis can handle teir duplicates gracefully
				if not closed then
					goto retry--this is the goto, no other way came to mind with this 
				end
			else
				error  ('gui element already present'..name)
			end
			return 
		else--if no duplicates
			local p=parameters
			if not roots[p.root] then error ('incorrect gui location specified: '..p.root) end
			--p.anchor=game.players[pind].gui[p.root].add{name=p.name,type=p.type,style=p.style}
			p.anchor=game.players[pind].gui[p.root].add{name=p.name,type=p.type,style=p.style}
			me.data[pind][name]=gui.new(p)
			if p.update then table.insert(me.updatable,me.data[pind][name]) end
			return me.data[pind][name]
		end
	end,
}
