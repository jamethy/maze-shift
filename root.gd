extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var err = $Hallway/Area3D.area_entered.connect(on_hallway_entered)
	print(err)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func on_hallway_entered():
	print("hallway enetered")
	#var hallway = get_map_at(hallway_node.position.x, hallway_node.position.z)
