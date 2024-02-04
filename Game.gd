extends Node3D

class Room:
	var node: BasicRoom
	var negative_x: Hallway
	var negative_z: Hallway
	var positive_x: Hallway
	var positive_z: Hallway
	
class Hallway:
	var node: Node
	var a: Room
	var b: Room
	

var maze_map = {}

var basic_room = preload("res://BasicRoom.tscn")
var hallway_scene = preload("res://Hallway.tscn")
var room_w = 12
var room_id_counter: int = 1


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var r = add_room(5, 5)
	
	add_rooms(r)
	
	$Barbarian.position = r.node.position


func add_rooms(r: Room):
	print("adding rooms to room ", r.node.room_id)
	var options = []
	if not r.negative_x and can_place_hallway(r, -1, 0):
		options.append(1)
	if not r.negative_z and can_place_hallway(r, 0, -1):
		options.append(2)
	if not r.positive_x and can_place_hallway(r, 1, 0):
		options.append(3)
	if not r.positive_z and can_place_hallway(r, 0, 1):
		options.append(4)
	
	if len(options) == 0:
		return
	
	var new_door_count = randi_range(1, len(options))
	for i in range(new_door_count):
		var o = options[randi() % len(options)]
		options.erase(o)
		
		if o == 1: # out of -x
			var hallway = add_hallway(
				r.node.position.x - room_w,
				r.node.position.z,
			)
			connect_hallyway_to_on_entered(hallway)
			hallway.a = r
			r.negative_x = hallway
			r.node.set_door_negative_x(true)
			var can_go_left = get_map_relative_at(r, -1, 1) == null
			var can_go_right = get_map_relative_at(r, -1, -1) == null
			if can_go_left and can_go_right:
				if randi() % 2 == 0:
					can_go_left = false
				else:
					can_go_right = false
			if can_go_left:
				# door facing positive x
				# door facing positive z
				# do no rotation
				var room = add_room(
					r.node.position.x - room_w,
					r.node.position.z + room_w,
				)
				room.negative_z = hallway
				room.node.set_door_negative_z(true)
				hallway.b = room
			else:
				hallway.node.rotation_degrees.y = 90
				var room = add_room(
					r.node.position.x - room_w,
					r.node.position.z - room_w,
				)
				room.positive_z = hallway
				room.node.set_door_positive_z(true)
				hallway.a = r
				hallway.b = room
		elif o == 2: # out of -z
			var hallway = add_hallway(
				r.node.position.x,
				r.node.position.z - room_w,
			)
			connect_hallyway_to_on_entered(hallway)
			hallway.a = r
			r.negative_z = hallway
			r.node.set_door_negative_z(true)
			var can_go_left = get_map_relative_at(r, -1, -1) == null
			var can_go_right = get_map_relative_at(r, 1, -1) == null
			if can_go_left and can_go_right:
				if randi() % 2 == 0:
					can_go_left = false
				else:
					can_go_right = false
			if can_go_left:
				hallway.node.rotation_degrees.y = -90
				
				var room = add_room(
					r.node.position.x - room_w,
					r.node.position.z - room_w,
				)
				room.positive_x = hallway
				room.node.set_door_positive_x(true)
				hallway.b = room
			else:
				# no rotation
				var room = add_room(
					r.node.position.x + room_w,
					r.node.position.z - room_w,
				)
				
				room.negative_x = hallway
				room.node.set_door_negative_x(true)
				hallway.a = r
				hallway.b = room
		elif o == 3: # out of +x
			var hallway = add_hallway(
				r.node.position.x + room_w,
				r.node.position.z,
			)
			connect_hallyway_to_on_entered(hallway)
			hallway.a = r
			r.positive_x = hallway
			r.node.set_door_positive_x(true)
			var can_go_left = get_map_relative_at(r, 1, -1) == null
			var can_go_right = get_map_relative_at(r, 1, 1) == null
			if can_go_left and can_go_right:
				if randi() % 2 == 0:
					can_go_left = false
				else:
					can_go_right = false
			if can_go_left:
				# door facing negative x
				# door facing positive z
				hallway.node.rotation_degrees.y = -180
				
				var room = add_room(
					r.node.position.x + room_w,
					r.node.position.z - room_w,
				)
				room.positive_z = hallway
				room.node.set_door_positive_z(true)
				hallway.b = room
			else:
				hallway.node.rotation_degrees.y = -90
				var room = add_room(
					r.node.position.x + room_w,
					r.node.position.z + room_w,
				)
				
				room.negative_z = hallway
				room.node.set_door_negative_z(true)
				hallway.a = r
				hallway.b = room
		elif o == 4: # out of +z
			var hallway = add_hallway(
				r.node.position.x,
				r.node.position.z + room_w,
			)
			connect_hallyway_to_on_entered(hallway)
			hallway.a = r
			r.positive_z = hallway
			r.node.set_door_positive_z(true)
			var can_go_left = get_map_relative_at(r, 1, 1) == null
			var can_go_right = get_map_relative_at(r, 1, -1) == null
			if can_go_left and can_go_right:
				if randi() % 2 == 0:
					can_go_left = false
				else:
					can_go_right = false
			if can_go_left:
				# door facing negative x
				# door facing positive z
				hallway.node.rotation_degrees.y = 90
				
				var room = add_room(
					r.node.position.x + room_w,
					r.node.position.z + room_w,
				)
				room.negative_x = hallway
				room.node.set_door_negative_x(true)
				hallway.b = room
			else:
				hallway.node.rotation_degrees.y = 180
				var room = add_room(
					r.node.position.x - room_w,
					r.node.position.z + room_w,
				)
				
				room.positive_x = hallway
				room.node.set_door_positive_x(true)
				hallway.a = r
				hallway.b = room



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
	return get_map_at(r.node.position.x + dx*room_w, r.node.position.z + dz*room_w)

func get_map_at(x, z):
	if x not in maze_map or z not in maze_map[x]:
		return null
	return maze_map[x][z]


func add_room(x, z):
	if x not in maze_map:
		maze_map[x] = {}
	
	if z in maze_map[x]:
		print("already a room here ", x, ", ", z)
		return maze_map[x][z]
	
	var room_obj = basic_room.instantiate()
	room_obj.name = 'Room%d' % room_id_counter
	room_obj.room_id = room_id_counter
	room_id_counter += 1
	room_obj.position.x = x
	room_obj.position.z = z
	var room = Room.new()
	room.node = room_obj
	room_obj.get_node("Area3D").body_entered.connect(on_room_entered.bind(room))
	maze_map[x][z] = room
	add_child(room.node)
	return room

func add_hallway(x, z):
	if x not in maze_map:
		maze_map[x] = {}
	
	if z in maze_map[x]:
		print("already a something here ", x, ", ", z)
		return
	
	var hallway_obj = hallway_scene.instantiate()
	hallway_obj.position.x = x
	hallway_obj.position.z = z
	var h = Hallway.new()
	h.node = hallway_obj
	maze_map[x][z] = h
	add_child(h.node)
	return h


func connect_hallyway_to_on_entered(hallway: Hallway):
	hallway.node.get_node("Area3D").body_entered.connect(on_hallway_entered.bind(hallway))


func on_hallway_entered(body: Barbarian, hallway: Hallway):
	print("hallway entered")
	var room_ahead: Room
	if body.current_room_id == hallway.a.node.room_id:
		room_ahead = hallway.b
	else:
		room_ahead = hallway.a
	if room_ahead.node.door_count() == 1:
		add_rooms(room_ahead)
	else:
		print("already has doors")
	
	
func on_room_entered(body: Barbarian, room: Room):
	body.current_room_id = room.node.room_id
	
	
