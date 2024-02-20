extends Node


# player_id, hallway_id
signal player_entered_hallway(dict)

# player_id, room_id, distance
signal player_entered_room(dict)

# player_id, room_id
signal player_exited_room(dict)

# player_info by player_id
signal lobby_players_updated(dict)

signal server_disconnected(dict)

signal started_game_from_lobby(dict)

# player_id
signal loaded_into_game(dict)

signal all_players_loaded_game(dict)

# player_id, move
signal player_attacked(dict)

signal room_added(dict)

signal hallway_added(dict)

func emit(signal_name: String, args: Dictionary = {}):
	if multiplayer.has_multiplayer_peer():
		_emit_signal.rpc(signal_name, args)
	else:
		local_emit(signal_name, args)

func local_emit(signal_name: String, args: Dictionary = {}):
	log_signal(signal_name, "local", args)
	emit_signal(signal_name, args)

@rpc("any_peer", "call_local", "reliable", 0)
func _emit_signal(signal_name: String, args: Dictionary):
	log_signal(signal_name, "remote", args)
	emit_signal(signal_name, args)

func log_signal(signal_name: String, type: String, args: Dictionary):
	var player_id = "%9d" % multiplayer.get_unique_id()
	print("signal(%s,%s): %s " % [type, player_id, signal_name], args)

