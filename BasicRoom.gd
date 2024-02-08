@tool
extends Node3D
class_name BasicRoom

var room_id: int
var timed_out = false
var current_players = {}

var hallways = {}

func _get_wall_door_node(dir: Vector3) -> Node3D:
	if roundi(dir.x) > 0.5:
		return $wall_positive_x
	elif roundi(dir.x) < -0.5:
		return $wall_negative_x
	elif roundi(dir.z) > 0.5:
		return $wall_positive_z
	elif roundi(dir.z) < -0.5:
		return $wall_negative_z
	return null

func connect_hallway(hallway: Hallway):
	hallways[hallway.hallway_id] = hallway
	var door_node = _get_wall_door_node(hallway.position - position)
	door_node.visible = false
	# E 0:00:23:0626   BasicRoom.gd:20 @ set_door(): Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
  #<C++ Error>    Condition "body->get_space() && flushing_queries" is true.
  #<C++ Source>   servers/physics_3d/godot_physics_server_3d.cpp:540 @ body_set_shape_disabled()
  #<Stack Trace>  BasicRoom.gd:20 @ set_door()
				 #Game.gd:61 @ add_rooms()
				 #Game.gd:196 @ on_hallway_entered()
				 #Events.gd:27 @ _emit_signal()
				 #Events.gd:18 @ emit()
				 #Hallway.gd:11 @ _on_area_3d_body_entered()

	door_node.get_node("wall/StaticBody3D/CollisionShape3D").disabled = false
	door_node.position.y = 4


func players_nearby(rooms_away: int) -> bool:
	if len(current_players) > 0:
		return true
	if rooms_away == 0:
		return false
	for hallway in hallways.values():
		if len(hallway.current_players) > 0:
			return true
		var other_room = hallway.room_a if hallway.room_b == self else hallway.room_b
		if other_room.players_nearby(rooms_away - 1):
			return true
	return false
	


func disconnect_hallway(hallway: Hallway):
	if not hallways.erase(hallway.hallway_id):
		print("hallway ", hallway.hallway_id, " not attatched to room ", room_id)
		return
	var door_node = _get_wall_door_node(hallway.position - position)
	door_node.visible = true

	door_node.get_node("wall/StaticBody3D/CollisionShape3D").disabled = true
	door_node.position.y = 0

var distance_from_center: float

# Called when the node enters the scene tree for the first time.
func _ready():
	distance_from_center = position.length()


func door_count() -> int:
	var c = 0
	if $wall_negative_x.position.y > 0:
		c += 1
	if $wall_negative_z.position.y > 0:
		c += 1
	if $wall_positive_x.position.y > 0:
		c += 1
	if $wall_positive_z.position.y > 0:
		c += 1
	return c


func _on_area_3d_body_entered(body):
	if body is Barbarian:
		
		current_players[body.player_id] = null
		$Timer.stop()
		timed_out = false
		
		Events.emit("player_entered_room", {
			"player_id": body.player_id,
			"room_id": room_id,
			"distance": distance_from_center,
		})


func _on_area_3d_body_exited(body):
	if body is Barbarian:
		
		current_players.erase(body.player_id)
		$Timer.start()
		
		Events.emit("player_exited_room", {
			"player_id": body.player_id,
			"room_id": room_id,
		})


func _on_timer_timeout():
	print("timed out ", room_id)
	timed_out = true
