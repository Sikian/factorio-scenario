function formattime(ticks)
  local seconds = ticks / 60
  local minutes = math.floor((seconds)/60)
  local seconds = math.floor(seconds - 60*minutes)
  return string.format("%d:%02d", minutes, seconds)
end

-- filter(function, table)
-- e.g: filter(is_even, {1,2,3,4}) -> {2,4}
function filter(func, tbl)
    local newtbl= {}
    for i,v in pairs(tbl) do
        if func(v) then
            newtbl[i]=v
        end
    end
    return newtbl
end

function second_to_tick(seconds)
    return seconds * 60 * game.speed
end

function minute_to_tick(minutes)
    return second_to_tick(minutes*60)
end

function tick_to_second(ticks)
    return math.floor(ticks / 60 / game.speed)
end


function number_to_readable(num)
    num = tonumber(num)
    if (num > 10000) then
        return math.floor(num / 1000) .. "k"
    end
    if (num > 1000) then
        return math.floor(num / 1000) .. "." .. math.floor((num % 1000) / 100) .. "k"
    end
    return num
end


function get_player_online_count()
    local counter = 0
    for i, x in pairs(game.players) do
        if x.connected then
            counter = counter + 1
        end
    end
    return counter
end


function create_gui(player)
    if (player.gui.top.factoriommo_frame ~= nil) then
        player.gui.top.factoriommo_frame.destroy()
    end

    local frame = player.gui.top.add{type="frame", name="factoriommo_frame", caption = "/r/factorio MMO", direction="vertical"}

    local table = frame.add{type="table", name="table", colspan=2}

    table.add{type="label", caption="Local server", style="caption_label_style"}
    table.add{type="label", caption= "", name="local_statistics"}

    table.add{type="label", caption="Players online", style="bold_label_style"}
    table.add{type="label", caption= "?", name="local_players"}
    table.add{type="label", caption="Science pack 1", style="bold_label_style"}
    table.add{type="label", caption= "?", name="local_science_1"}
    table.add{type="label", caption="Science pack 2", style="bold_label_style"}
    table.add{type="label", caption= "?", name="local_science_2"}
    table.add{type="label", caption="Science pack 3", style="bold_label_style"}
    table.add{type="label", caption= "?", name="local_science_3"}
    table.add{type="label", caption="Alien science", style="bold_label_style"}
    table.add{type="label", caption= "?", name="local_alien_science"}


    table.add{type="label", caption="Other server", style="caption_label_style"}
    table.add{type="label", caption= "", name="remote_statistics"}

    table.add{type="label", caption="Players online", style="bold_label_style"}
    table.add{type="label", caption= "?", name="remote_players"}
    table.add{type="label", caption="Science pack 1", style="bold_label_style"}
    table.add{type="label", caption= "?", name="remote_science_1"}
    table.add{type="label", caption="Science pack 2", style="bold_label_style"}
    table.add{type="label", caption= "?", name="remote_science_2"}
    table.add{type="label", caption="Science pack 3", style="bold_label_style"}
    table.add{type="label", caption= "?", name="remote_science_3"}
    table.add{type="label", caption="Alien science", style="bold_label_style"}
    table.add{type="label", caption= "?", name="remote_alien_science"}

    table.add{type="label", caption="Time played", style="caption_label_style"}
    table.add{type="label", caption= "?", name="time_played"}
end

function update_gui()
    for _,p in pairs(game.players) do
        if (p.gui.top.factoriommo_frame == nil) then
            create_gui(p)
        end

        local table = p.gui.top.factoriommo_frame.table
        table.time_played.caption = formattime(game.tick)

        table.local_players.caption = global.local_players
        table.local_science_1.caption = number_to_readable(global.local_science_1)
        table.local_science_2.caption = number_to_readable(global.local_science_2)
        table.local_science_3.caption = number_to_readable(global.local_science_3)
        table.local_alien_science.caption =  number_to_readable(global.local_alien_science)

        table.remote_players.caption = global.remote_players
        table.remote_science_1.caption = number_to_readable(global.remote_science_1)
        table.remote_science_2.caption = number_to_readable(global.remote_science_2)
        table.remote_science_3.caption = number_to_readable(global.remote_science_3)
        table.remote_alien_science.caption = number_to_readable(global.remote_alien_science)
    end
end


function update_stats()
    global.local_science_1 = game.forces['player'].item_production_statistics.get_output_count('science-pack-1')
    global.local_science_2 = game.forces['player'].item_production_statistics.get_output_count('science-pack-2')
    global.local_science_3 = game.forces['player'].item_production_statistics.get_output_count('science-pack-3')
    global.local_alien_science = game.forces['player'].item_production_statistics.get_output_count('alien-science-pack')

    print("##FMC::player-count::" .. #game.players)
    print("##FMC::player-online-count::" .. global.local_players)
    print("##FMC::science-pack-1::" .. global.local_science_1)
    print("##FMC::science-pack-2::" .. global.local_science_2)
    print("##FMC::science-pack-3::" .. global.local_science_3)
    print("##FMC::alien-science-pack::" .. global.local_alien_science)
end


function setup_player_inventory(player)
    local character = player.character

    character.insert{name = "burner-mining-drill", count = 1}
    character.insert{name = "stone-furnace", count = 1}
    character.insert{name = "iron-plate", count = 8}
    character.insert{name = "steel-axe", count = 1}

    character.insert{name = "pistol", count = 1}
    character.insert{name = "firearm-magazine", count = 10}
end

script.on_event(defines.events.on_player_created, function(event)
    local player = game.players[event.player_index]

    -- player.minimap_enabled = false
    setup_player_inventory(player)
end)


script.on_event(defines.events.on_tick, function(event)
    local tick = game.tick

    if (global.remaining_until_update < 1) then
        global.remaining_until_update = second_to_tick(1) -- TODO: Change to 10 for live! ;)
        update_stats()
    else
        global.remaining_until_update = global.remaining_until_update - 1
    end

    update_gui()
end)


script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    print("##FMC::player_joined::" .. player.name)

    player.print("-== TEST Welcome to [EU] /r/factorio MMO. Grievers WILL be banned.")
    player.print("See the official rules on /r/factorioMMO for more details.")
    player.print("")
    global.local_players = get_player_online_count()
    player.print("There are currently " .. global.local_players .. " players online.")
end)


script.on_event(defines.events.on_player_left_game, function(event)
    local player = game.players[event.player_index]
    print("##FMC::player_left::" .. player.name)

    global.local_players = get_player_online_count()
end)


script.on_init(function()
    game.disable_replay()

    global.remaining_until_update = 0
    global.local_players = 0
    global.local_science_1 = 0
    global.local_science_2 = 0
    global.local_science_3 = 0
    global.local_alien_science = 0
    global.remote_players = 0
    global.remote_science_1 = 0
    global.remote_science_2 = 0
    global.remote_science_3 = 0
    global.remote_alien_science = 0

end)

remote.add_interface("rconstats", {
    dumpstats = function()
        update_stats()
    end,
    updatestats = function(statname, value)
        if (statname == "player-online-count") then
            global.remote_players = value
            return
        end
        if (statname == "science-pack-1") then
            global.remote_science_1 = value
            return
        end
        if (statname == "science-pack-2") then
            global.remote_science_2 = value
            return
        end
        if (statname == "science-pack-3") then
            global.remote_science_3 = value
            return
        end
        if (statname == "alien-science-pack") then
            global.remote_alien_science = value
            return
        end
    end,
    callvictory = function(is_winner) 
        if (is_winner) then
            game.print("YOU WON!")
        else
            game.print("YOU LOSE :(")
        end
    end
})
