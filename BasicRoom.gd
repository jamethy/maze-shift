@tool
extends Node3D
class_name BasicRoom

@export var door_negative_x = false : set = set_door_negative_x
@export var door_negative_z = false : set = set_door_negative_z
@export var door_positive_x = false : set = set_door_positive_x
@export var door_positive_z = false : set = set_door_positive_z

var room_id: int

func set_door(dir: Vector3, open: bool):
	var door_node: Node
	
	if roundi(dir.x) == 1:
		door_node = $wall_positive_x
	elif roundi(dir.x) == -1:
		door_node = $wall_negative_x
	elif roundi(dir.z) == 1:
		door_node = $wall_positive_z
	elif roundi(dir.z) == -1:
		door_node = $wall_negative_z
	door_node.visible = !open
	door_node.get_node("wall/StaticBody3D/CollisionShape3D").disabled = open
	door_node.position.y = 4 if open else 0

var distance_from_center: float

# Called when the node enters the scene tree for the first time.
func _ready():
	$wall_negative_x.visible = !door_negative_x
	$wall_negative_z.visible = !door_negative_z
	$wall_positive_x.visible = !door_positive_x
	$wall_positive_z.visible = !door_positive_z
	distance_from_center = position.length()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_door_negative_x(b: bool):
	door_negative_x = b
	$wall_negative_x.visible = !door_negative_x
	$wall_negative_x.get_node("wall/StaticBody3D/CollisionShape3D").disabled = door_negative_x
	$wall_negative_x.position.y += 4

func set_door_negative_z(b: bool):
	door_negative_z = b
	$wall_negative_z.visible = !door_negative_z
	$wall_negative_z.get_node("wall/StaticBody3D/CollisionShape3D").disabled = door_negative_z
	$wall_negative_z.position.y += 4

func set_door_positive_x(b: bool):
	door_positive_x = b
	$wall_positive_x.visible = !door_positive_x
	$wall_positive_x.get_node("wall/StaticBody3D/CollisionShape3D").disabled = door_positive_x
	$wall_positive_x.position.y += 4

func set_door_positive_z(b: bool):
	door_positive_z = b
	$wall_positive_z.visible = !door_positive_z
	$wall_positive_z.get_node("wall/StaticBody3D/CollisionShape3D").disabled = door_positive_z
	$wall_positive_z.position.y += 4


func door_count() -> int:
	var c = 0
	if $wall_negative_x.position.y == 4:
		c += 1
	if $wall_negative_z.position.y == 4:
		c += 1
	if $wall_positive_x.position.y == 4:
		c += 1
	if $wall_positive_z.position.y == 4:
		c += 1
	return c


func _on_area_3d_body_entered(body):
	if body is Barbarian:
		Events.emit("player_entered_room", {
			"player_id": 1, # TODO
			"room_id": room_id,
			"distance": distance_from_center,
		})
