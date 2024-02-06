extends Node3D
class_name Hallway

var hallway_id: int
var room_a: BasicRoom
var room_b: BasicRoom


func _on_area_3d_body_entered(body: Node):
	if body is Barbarian:
		Events.emit("player_entered_hallway", {
			"player_id": 1, # TODO
			"hallway_id": hallway_id,
		})
