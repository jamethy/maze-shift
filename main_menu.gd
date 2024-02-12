extends Control

@onready var lobby_player_container_scene = preload("res://lobby_player_container.tscn")

func _ready():
	Events.player_connected.connect(_on_player_connected)
	
	# just used for design
	$LobbyMenu/HBoxContainer/PlayersContainer/LobbyPlayerContainer.queue_free()


# GameLaunchMenu buttons

func _on_game_launch_host_button_pressed():
	$HostMenu.visible = true
	$GameLaunchMenu.visible = false


func _on_game_launched_join_button_pressed():
	$JoinMenu.visible = true
	$GameLaunchMenu.visible = false


func _on_exit_button_pressed():
	get_tree().quit()

# HostMenu Buttons

func _on_host_host_button_pressed():
	Lobby.start_server()
	$HostMenu.visible = false
	$LobbyMenu.visible = true


func _on_host_back_button_pressed():
	$HostMenu.visible = false
	$GameLaunchMenu.visible = true


# JoinMenu Buttons

func _on_join_back_button_pressed():
	$JoinMenu.visible = false
	$GameLaunchMenu.visible = true


func _on_join_join_button_pressed():
	pass # Replace with function body.


func _on_player_connected(d):
	# player_id, player_info
	var player_node = lobby_player_container_scene.instantiate()
	player_node.name = "Player%dContainer" % d["player_id"]
	player_node.get_node("Label").text = d["player_info"]["name"]
	player_node.get_node("ColorRect").color = Color("a22300")
	$LobbyMenu/HBoxContainer/PlayersContainer.add_child(player_node)


func _on_player_name_changed(new_text):
	if len(new_text) == 0:
		return
	Lobby.player_info["name"] = new_text


func _on_ready_button_pressed():
	var color_rect = get_node("LobbyMenu/HBoxContainer/PlayersContainer/Player%dContainer/ColorRect" % multiplayer.get_unique_id())
	if color_rect.color == Color("a22300"):
		color_rect.color = Color("009100")
	else:
		color_rect.color = Color("a22300")
