extends CharacterBody3D
class_name Barbarian

# https://github.com/finepointcgi/Godot-4-Multiplayer-Lan-Tutorial/blob/main/player.gd

@export var speed = 10.0
@export var acceleration = 10.0
@export var rotation_speed = 12.0
@export var mouse_sensitivity = 0.0015

@export var jump_height: float = 2.4
@export var jump_time_to_peak: float = 0.35
@export var jump_time_to_descent: float = 0.25

@onready var jump_velocity: float = (2*jump_height) / jump_time_to_peak
@onready var jump_gravity: float = (2*jump_height) / (jump_time_to_peak * jump_time_to_peak)
@onready var fall_gravity: float = (2*jump_height) / (jump_time_to_descent * jump_time_to_descent)

func get_player_gravity():
	return jump_gravity if velocity.y > 0 else fall_gravity

var id: int = 1
var current_room_id: int = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var jumping = false
var last_floor = true
var attacks = [
	"1H_Melee_Attack_Slice_Diagonal",
	"1H_Melee_Attack_Slice_Horizontal",
	"1H_Melee_Attack_Chop",
]

@onready var spring_arm = $SpringArm3D
@onready var model = $Rig
@onready var anim_tree = $AnimationTree
@onready var anim_state = $AnimationTree.get("parameters/playback")

func _ready():
	if Lobby.is_host():
		Events.player_entered_room.connect(on_player_entered_room)
	Events.player_attacked.connect(_on_player_attacked)
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		$SpringArm3D/Camera3D.current = true

func on_player_entered_room(d: Dictionary):
	if d["player_id"] == id:
		current_room_id = d["room_id"]

func _physics_process(delta: float):
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		return
	
	velocity.y -= get_player_gravity() * delta
	get_move_input(delta)
	
	move_and_slide()
	if velocity.length() > 1.0:
		model.rotation.y = lerp_angle(model.rotation.y, spring_arm.rotation.y, rotation_speed * delta)
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		jumping = true
		anim_tree.set("parameters/conditions/jumping", true)
		anim_tree.set("parameters/conditions/grounded", false)
	if is_on_floor() and not last_floor:
		jumping = true
		anim_tree.set("parameters/conditions/jumping", false)
		anim_tree.set("parameters/conditions/grounded", true)
	if not is_on_floor() and not jumping:
		anim_tree.set("parameters/conditions/jumping", true)
		anim_tree.set("parameters/conditions/grounded", false)
	last_floor = is_on_floor()

func get_move_input(delta: float):
	# temp zero out y velocity so we can mroe easily do vector math from input
	var vy = velocity.y
	velocity.y = 0
	
	var input = Input.get_vector("left", "right", "forward", "back")
	var dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, spring_arm.rotation.y)
	velocity = lerp(velocity, dir * speed, acceleration * delta)
	var vl = velocity * model.transform.basis
	anim_tree.set("parameters/IdleWalkRun/blend_position", Vector2(vl.x, -vl.z) / speed)
	velocity.y = vy

func _unhandled_input(event):
	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -90, 30)
		spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
	if event.is_action_pressed("attack"):
		Events.emit("player_attacked", {
			"player_id": Lobby.get_my_id(),
			"move": attacks.pick_random(),
		})
		

func _on_player_attacked(d: Dictionary):
	if d["player_id"] == id:
		anim_state.travel(d["move"])
