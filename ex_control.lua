require "gui_dispatch"--get lib
script.on_init(function()
	--[[define the storage for gui stuff]]
	global.gui={}
	gui_dispatch.init(global.gui)
	--[[If you feel fancy:]]
	--global.gui=gui_dispatch.init{}
end)
script.on_load(function()
	gui_dispatch.restore(global.gui)--restore metatables
end)

--[[Event handler registration]]
script.on_event(
	gui_dispatch.tracked_events,--[[this is table that contains indices of gui related events, last time checked:
	 {defines.events.on_gui_checked_state_changed, defines.events.on_gui_click, defines.events.on_gui_text_changed,}]]
	function(e)--[[this form allows you to call any other functions you need at the same events ]]
		gui_dispatch.on_gui_event(e) 
	end)
--[[or you could simply register it this way if nothing ele is needed:]]
--script.on_event(gui_dispatch.tracked_events,gui_dispatch.on_gui_event)

--[[This is example for on tick update handler, if your guis dont change over time, you dont even need this]]
script.on_event(defines.events.on_tick,function(e)
	if e.tick%10==0 then
		gui_dispatch.on_tick(e)
	end
end)

--[[This is just an example for demonstration]]
script.on_event(defines.events.on_player_created,function(e) example(e.player_index)  end)

example=function(pind)
	local g=gui_dispatch.open{
		player_index=pind,
		name='my_example_gui',
		root='center',
		type='frame',
		caption='Hey there',
		
		--[[You can also use the returned reference to set the fields below]]
		data={ch=game.players[pind].character,ind=pind},--[[just anything]]
		elements={--[[A simple gui can be squeezed completely in declaration]]
			{type='button',name='Hi',caption='Hi',
			handler=function(me)
			--[[I could put another call to gui_dispatch.open right here]]
				another_example(me.data)--GLOBAL FUNCTION
				me:destroy()
			end
			},
			{type='button',name='no',caption="Just no", handler=function(me) me:destroy() end,}
		}
	}--[Just keep track of braces and commas
	--[[another way to add buttons and stuff]]
	g:add{type='button',name='banana',caption="I do nothing"}
end

another_example=function(data)
	gui_dispatch.open{
		player_index=data.ind,
		name='my_another_example_gui',
		root='center',
		type='frame',
		caption='What is your name?',
		
		data=data,
		elements={--[[A complicated gui can be squeezed completely in declaration to, you just need to push harder]]
			{type='textfield',name='name'},
			{type='button',name='Hi',caption='Enter',
			handler=function(me)
			--[[I could put another call to gui_dispatch.open right here]]
				local d=me.data
				d.name=me.elements.name.text
				if d.name=="" then
					--[[and I will]]
					local g=gui_dispatch.open{
						player_index=data.ind,
						name='yet_another_gui',
						root='center',
						type='frame',
						data={i_block=me},
						caption='But that is not a name!',
						elements={{type='button',name='ok',caption="You got me",
						handler=function(me) me.data.i_block:unhide() me:destroy() end,
						}}
					}
					me.block_by(g)--[[until g is valid, other gui is inactive]]
					me:hide()
					return 
				end
				me:destroy()
				final_gui_example(d)
			end
			},
			--[[This is button for `my_another_example_gui`]]
			{type='button',name='no',caption="Just no", handler=function(me) me:destroy() end,}
		}
	}
end
final_gui_example=function(data)
	local g=gui_dispatch.open{
		player_index=data.ind,
		name='last_gui',
		root='center',
		type='frame',
		caption='Hi, '..data.name..'!',
		data=data,
		elements={
			{type='button',name='ok',caption="I beep",handler=function(me) game.players[me.data.ind].print("Beep") end,}
		},
		children={
			{type='frame',name='subgui',caption="Want some fish?",
			data={--[[You can save functions as long as they're not closures]]
				ch=data.ch,
				fu=function(me,button) local n=tonumber(button.name) me.data.ch.insert{name='raw-fish',count=n} me:close_all() end,
				},
			elements={
				{type='button',name='no',caption="No thanks", handler=function(me) me:get_top():destroy() end,}
			},
			}
		}
	}
	local sg=g.children.subgui
	--A bunch of keys programmatically can be added like this:
	for i=1,10,2 do
		sg:add{type='button', name=tostring(i), caption=tostring(i), handler=sg.data.fu}
	end
end
