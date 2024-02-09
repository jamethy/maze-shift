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


func door_count() -> int:
	var c = 0
	if !$wall_negative_x.visible:
		c += 1
	if !$wall_negative_z.visible:
		c += 1
	if !$wall_positive_x.visible:
		c += 1
	if !$wall_positive_z.visible:
		c += 1
	return c
	
	
func set_door_open(dir: Vector3, open: bool):
	var door_node = _get_wall_door_node(dir)
	# cannot directly set disabled because shrug
	door_node.get_node("wall/StaticBody3D/CollisionShape3D").set_deferred("disabled", open)
	door_node.visible = !open


func connect_hallway(hallway: Hallway):
	hallways[hallway.hallway_id] = hallway
	set_door_open(hallway.position - position, true)


func disconnect_hallway(hallway: Hallway):
	if not hallways.erase(hallway.hallway_id):
		print("hallway ", hallway.hallway_id, " not attatched to room ", room_id)
		return
	set_door_open(hallway.position - position, false)


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


func _on_area_3d_body_entered(body):
	if body is Barbarian:
		
		current_players[body.player_id] = null
		$Timer.stop()
		timed_out = false
		
		Events.emit("player_entered_room", {
			"player_id": body.player_id,
			"room_id": room_id,
			"distance": position.length(),
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
	timed_out = true
