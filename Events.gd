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

signal lobby_start_game(dict)

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
	print("signal(%s): %s " % [type, signal_name], args)

