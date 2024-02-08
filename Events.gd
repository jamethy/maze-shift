extends Node


# player_id, hallway_id
signal player_entered_hallway(dict)

# player_id, room_id, distance
signal player_entered_room(dict)

# player_id, room_id
signal player_exited_room(dict)

# room_id
signal room_timed_out(dict)

func emit(signal_name: String, args: Dictionary = {}):
	# TODO rpc("_emit_signal", signal_name, args)
	_emit_signal(signal_name, args)

func local_emit(signal_name: String, args: Dictionary = {}):
	log_signal(signal_name, "local", args)
	emit_signal(signal_name, args)

# TODO remotesync
func _emit_signal(signal_name: String, args: Dictionary):
	log_signal(signal_name, "remote", args)
	emit_signal(signal_name, args)

func log_signal(signal_name: String, type: String, args: Dictionary):
	print("signal(%s): %s " % [type, signal_name], args)

