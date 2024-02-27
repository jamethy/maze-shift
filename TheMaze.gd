extends Node3D


var maze_map = {}

var basic_room_scene = preload("res://BasicRoom.tscn")
var hallway_scene = preload("res://Hallway.tscn")
var barbarian_scene = preload("res://barbarian.tscn")
var room_w = 12
var room_id_counter: int = 1
var hallway_id_counter: int = 1

var starting_room: BasicRoom

func _ready():
	
	
	add_room(room_id_counter, 0, 0)
	room_id_counter += 1
	
	if multiplayer.is_server():
		Events.player_entered_hallway.connect(on_player_entered_hallway)
		Events.player_entered_room.connect(on_player_entered_room)
		Events.all_players_loaded_game.connect(_on_all_players_loaded_game)
	else:
		Events.room_added.connect(_on_server_added_room)
		Events.hallway_added.connect(_on_server_added_hallway)
	Events.lobby_players_updated.connect(_on_lobby_players_updated)
	
	var initial_distance = 5
	starting_room = add_room(room_id_counter, initial_distance * room_w, initial_distance * room_w)
	room_id_counter += 1
	for player_id in Lobby.players:
		add_player(player_id, Lobby.players[player_id])
	
	Events.emit("loaded_into_game", { "player_id": multiplayer.get_unique_id() })
	
	$SubViewportContainer/SubViewport.world_3d = get_viewport().world_3d

func start_game():
	add_rooms(starting_room)

func _on_all_players_loaded_game(_d: Dictionary):
	start_game()

func _on_lobby_players_updated(players: Dictionary):
	for player_id in players:
		var node_name = "Player%d" % player_id
		var exists = has_node(node_name)
		var connected = players[player_id]["status"] != "disconnected"
		if not exists and connected:
			add_player(player_id, Lobby.players[player_id])
		elif exists and not connected:
			remove_child(get_node(node_name))


func add_player(id: int, _player_info: Dictionary):
	var b = barbarian_scene.instantiate()
	b.name = "Player%d" % id
	b.id = id
	b.position = starting_room.position  # TODO add random
	b.position.x += randf() * room_w / 3
	b.position.z += randf() * room_w / 3
	b.set_multiplayer_authority(id)
	add_child(b)
	
	
# server only
func add_rooms(r: BasicRoom):
	print("adding rooms to room ", r.room_id)
	var options = []
	if can_place_hallway(r, -1, 0):
		options.append(Vector3(-1, 0, 0))
	if can_place_hallway(r, 0, -1):
		options.append(Vector3(0, 0, -1))
	if can_place_hallway(r, 1, 0):
		options.append(Vector3(1, 0, 0))
	if can_place_hallway(r, 0, 1):
		options.append(Vector3(0, 0, 1))
	
	if len(options) == 0:
		return
	
	var new_door_count = randi_range(1, len(options))
	for i in range(new_door_count):
		var out_dir = options[randi() % len(options)]
		options.erase(out_dir)

		
		var left_dir = out_dir + out_dir.rotated(Vector3.UP, PI/2)
		var right_dir = out_dir + out_dir.rotated(Vector3.UP, -PI/2)
		var can_go_left = get_map_relative_at(r, left_dir.x, left_dir.z) == null
		var can_go_right = get_map_relative_at(r, right_dir.x, right_dir.z) == null
		if can_go_left == can_go_right:
			if randi() % 2 == 0:
				can_go_left = false
				can_go_right = true
			else:
				can_go_left = true
				can_go_right = false
		
		var dir = left_dir if can_go_left else right_dir
		
		var room_id = room_id_counter
		room_id_counter += 1
		var room = add_room(
			room_id,
			r.position.x + room_w * dir.x,
			r.position.z + room_w * dir.z,
		)
		Events.emit("room_added", {
			"id": room_id,
			"x": room.position.x,
			"z": room.position.z,
		})
		
		var hallway_id = hallway_id_counter
		hallway_id_counter += 1
		var hallway = add_hallway(
			hallway_id,
			r.position.x + room_w * out_dir.x,
			r.position.z + room_w * out_dir.z,
		)
		hallway.look_at(hallway.position + out_dir) # points -Z toward point - right turn
		if can_go_left:
			hallway.rotation.y -= PI/2
		Events.emit("hallway_added", {
			"id": hallway_id,
			"x": hallway.position.x,
			"z": hallway.position.z,
			"rotation.y": hallway.rotation.y,
			"room_a_id": r.room_id,
			"room_b_id": room.room_id,
		})
		
		r.connect_hallway(hallway)
		room.connect_hallway(hallway)
		hallway.room_a = r
		hallway.room_b = room


func can_place_hallway(r, dx, dz):
	if get_map_relative_at(r, dx, dz) != null:
		return false

	var possibilities = []
	if dx == 0:
		possibilities = [[-1, dz],  [1, dz]]
	else:
		possibilities = [[dx, -1], [dx, 1]]
	for p in possibilities:
		if get_map_relative_at(r, dx, dz) == null:
			return true
	return false


func get_map_relative_at(r, dx, dz):
	return get_map_at(r.position.x + dx*room_w, r.position.z + dz*room_w)

func get_map_at(x, z):
	var xi = roundi(x)
	var zi = roundi(z)
	if xi not in maze_map or zi not in maze_map[xi]:
		return null
	return maze_map[xi][zi]

func _on_server_added_room(d):
	add_room(d["id"], d["x"], d["z"])

func add_room(id: int, x: float, z: float):
	var xi = roundi(x)
	var zi = roundi(z)
	if xi not in maze_map:
		maze_map[xi] = {}
	
	if zi in maze_map[xi]:
		var existing = maze_map[xi][zi]
		print("already a something here ", {
			"x": xi,
			"z": zi,
			"name": existing.name,
		})
		return existing  # hope it's a room
	
	var room = basic_room_scene.instantiate()
	room.name = 'Room%d' % id
	room.room_id = id
	room.position.x = x
	room.position.z = z
	maze_map[xi][zi] = room
	add_child(room)
	return room

func remove_room(room: BasicRoom):
	for x in maze_map.values():
		for n in x.values():
			if n is Hallway and (n.room_a == room or n.room_b == room):
				n.room_a.disconnect_hallway(n)
				n.room_b.disconnect_hallway(n)
				remove_from_maze_map(n.position.x, n.position.z)
				remove_child(n)
	remove_child(room)


func remove_from_maze_map(x, z):
	var xi = roundi(x)
	var zi = roundi(z)
	if xi not in maze_map:
		return
	maze_map[xi].erase(zi)
	
func _on_server_added_hallway(d):
	var hallway = add_hallway(d["id"], d["x"], d["z"])
	hallway.rotation.y = d["rotation.y"]
	var room_a = get_node("Room%d" % d["room_a_id"])
	var room_b = get_node("Room%d" % d["room_b_id"])
	room_a.connect_hallway(hallway)
	room_b.connect_hallway(hallway)
	hallway.room_a = room_a
	hallway.room_b = room_b
	

func add_hallway(id: int, x: float, z: float):
	var xi = roundi(x)
	var zi = roundi(z)
	if xi not in maze_map:
		maze_map[xi] = {}
	
	if zi in maze_map[xi]:
		var existing = maze_map[xi][zi]
		print("already a something here ", {
			"x": xi,
			"z": zi,
			"name": existing.name,
		})
		return existing  # hope it's a hallway
	
	var hallway = hallway_scene.instantiate()
	hallway.hallway_id = id
	hallway.name = "Hallway%d" % hallway.hallway_id
	hallway.position.x = x
	hallway.position.z = z
	maze_map[xi][zi] = hallway
	add_child(hallway)
	return hallway


func on_player_entered_hallway(d: Dictionary):
	var hallway = get_node('Hallway%d' % d["hallway_id"])
	if not hallway:
		print("didn't find hallway")
		return
	var player = get_node("Player%d" % d["player_id"])
	
	var room_ahead: BasicRoom
	if player.current_room_id == hallway.room_a.room_id:
		room_ahead = hallway.room_b
	else:
		room_ahead = hallway.room_a
	if room_ahead.door_count() == 1 or room_ahead.timed_out:
		add_rooms(room_ahead)


func on_player_entered_room(_d: Dictionary):
	# clear old rooms
	for c in get_children():
		var room = c as BasicRoom
		if not room:
			continue
		
		if not room.timed_out:
			continue
		
		if len(room.hallways) == 0:
			remove_room(room)

		if not room.players_nearby(1):
			remove_room(room)


func _unhandled_input(event):
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		return
	if event.is_action_pressed("minimap"):
		$SubViewportContainer.visible = not $SubViewportContainer.visible
