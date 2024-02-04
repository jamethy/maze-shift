@tool
extends Node3D
class_name BasicRoom

@export var door_negative_x = false : set = set_door_negative_x
@export var door_negative_z = false : set = set_door_negative_z
@export var door_positive_x = false : set = set_door_positive_x
@export var door_positive_z = false : set = set_door_positive_z

var room_id: int

# Called when the node enters the scene tree for the first time.
func _ready():
	$wall_negative_x.visible = !door_negative_x
	$wall_negative_z.visible = !door_negative_z
	$wall_positive_x.visible = !door_positive_x
	$wall_positive_z.visible = !door_positive_z


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
	if door_negative_x:
		c += 1
	if door_negative_z:
		c += 1
	if door_positive_x:
		c += 1
	if door_positive_z:
		c += 1
	return c
