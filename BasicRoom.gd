@tool
extends Node3D
class_name BasicRoom

var room_id: int
var timed_out = false

func set_door(dir: Vector3, open: bool):
	var door_node: Node
	
	if roundi(dir.x) > 0.5:
		door_node = $wall_positive_x
	elif roundi(dir.x) < -0.5:
		door_node = $wall_negative_x
	elif roundi(dir.z) > 0.5:
		door_node = $wall_positive_z
	elif roundi(dir.z) < -0.5:
		door_node = $wall_negative_z
	door_node.visible = !open
	door_node.get_node("wall/StaticBody3D/CollisionShape3D").disabled = open
	door_node.position.y = 4 if open else 0

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
		$Timer.stop()
		Events.emit("player_entered_room", {
			"player_id": 1, # TODO
			"room_id": room_id,
			"distance": distance_from_center,
		})


func _on_area_3d_body_exited(body):
	if body is Barbarian:
		$Timer.start()
		Events.emit("player_exited_room", {
			"player_id": 1, # TODO
			"room_id": room_id,
		})


func _on_timer_timeout():
	timed_out = true
	#Events.emit("room_timed_out", {
		#"room_id": room_id,
	#})
