extends Node3D


var maze_map = {}

var basic_room_scene = preload("res://BasicRoom.tscn")
var hallway_scene = preload("res://Hallway.tscn")
var room_w = 12
var room_id_counter: int = 1
var hallway_id_counter: int = 1

var is_server = true

@onready 
var players = {
	1: $Barbarian,
}

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var r = add_room(5 * room_w, 5 * room_w)
	
	add_rooms(r)
	
	$Barbarian.position = r.position
	
	if is_server:
		Events.player_entered_hallway.connect(on_hallway_entered)


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
		
		var hallway = add_hallway(
			r.position.x + room_w * out_dir.x,
			r.position.z + room_w * out_dir.z,
		)
		hallway.room_a = r
		hallway.look_at(hallway.position + out_dir) # points -Z toward point - right turn
		r.set_door(out_dir, true)
		
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
		if can_go_left:
			var room = add_room(
				r.position.x + room_w * left_dir.x,
				r.position.z + room_w * left_dir.z,
			)
			var reverse_in_dir = out_dir.rotated(Vector3.UP, -PI/2)
			room.set_door(reverse_in_dir, true)
			hallway.room_b = room
			hallway.rotation.y -= PI/2
		elif can_go_right:
			var room = add_room(
				r.position.x + room_w * right_dir.x,
				r.position.z + room_w * right_dir.z,
			)
			var reverse_in_dir = out_dir.rotated(Vector3.UP, PI/2)
			room.set_door(reverse_in_dir, true)
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


func add_room(x, z):
	var xi = roundi(x)
	var zi = roundi(z)
	if xi not in maze_map:
		maze_map[xi] = {}
	
	if zi in maze_map[xi]:
		print("already a room here ", x, ", ", z)
		return maze_map[xi][zi]
	
	var room = basic_room_scene.instantiate()
	room.name = 'Room%d' % room_id_counter
	room.room_id = room_id_counter
	room_id_counter += 1
	room.position.x = x
	room.position.z = z
	maze_map[xi][zi] = room
	add_child(room)
	return room

func add_hallway(x, z):
	var xi = roundi(x)
	var zi = roundi(z)
	if xi not in maze_map:
		maze_map[xi] = {}
	
	if zi in maze_map[xi]:
		print("already a something here ", x, ", ", z)
		return
	
	var hallway = hallway_scene.instantiate()
	hallway.hallway_id = hallway_id_counter
	hallway_id_counter += 1
	hallway.name = "Hallway%d" % hallway.hallway_id
	hallway.position.x = x
	hallway.position.z = z
	maze_map[xi][zi] = hallway
	add_child(hallway)
	return hallway


func on_hallway_entered(d: Dictionary):
	var hallway = get_node('Hallway%d' % d["hallway_id"])
	if not hallway:
		print("didn't find hallway")
		return
	var player = players[d["player_id"]]
	
	var room_ahead: BasicRoom
	if player.current_room_id == hallway.room_a.room_id:
		room_ahead = hallway.room_b
	else:
		room_ahead = hallway.room_a
	if room_ahead.door_count() == 1:
		add_rooms(room_ahead)
	
	
func on_room_entered(body: Barbarian, room: BasicRoom):
	body.current_room_id = room.room_id
	
	
