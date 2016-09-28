script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.players[event.player_index]
  player.print("-== Welcome to [EU] /r/factorio MMO. Grievers WILL be banned.")
  player.print("See the official rules on /r/factorioMMO for more details.")
  player.print("")
  player.print("There are currently " .. #game.players .. " players online.")

  game.write_file("statjes/test.txt", "There are currently " .. #game.players .. " players online.")
end)


function setup_player_inventory(player)
  local character = player.character

  character.insert{name = "burner-mining-drill", count = 1}
  character.insert{name = "stone-furnace", count = 1}
  character.insert{name = "iron-plate", count = 8}
  character.insert{name = "steel-axe", count = 1}
end

script.on_event(defines.events.on_player_created, function(event)
  local player = game.players[event.player_index]

  -- player.minimap_enabled = false
  setup_player_inventory(player)
end)

script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local player = game.players[event.player_index]
    game.write_file("statjes/test.txt", "inventory changed of p" .. event.player_index)
end)


remote.add_interface("rconstats", {
    dumpstats = function()
        print("##STATS: player-count=" .. #game.players)
    end,
    printstats = function(somedata)
        game.print("Remote stats: " .. somedata)
    end
})
