extends Control

@onready var lobby_player_container_scene = preload("res://lobby_player_container.tscn")

var not_ready_color = Color("a22300")
var ready_color = Color("009100")

func _ready():
	Events.lobby_players_updated.connect(_on_lobby_players_updated)
	# TODO Events.server_disconnected.connect(_on_server_disconnected)
	$HostMenu/VBoxContainer/PlayerNameContainer/LineEdit.text = Lobby.player_info["name"]
	$JoinMenu/VBoxContainer/PlayerNameContainer/LineEdit.text = Lobby.player_info["name"]
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
	Lobby.join_game($JoinMenu/VBoxContainer/IPAddressContainer/LineEdit.text)
	$JoinMenu.visible = false
	$LobbyMenu.visible = true


func get_or_add_player_container(player_id: int):
	var node_name = "Player%dContainer" % player_id
	var parent_node = $LobbyMenu/HBoxContainer/PlayersContainer
	if parent_node.has_node(node_name):
		return parent_node.get_node(node_name)
	var player_node = lobby_player_container_scene.instantiate()
	player_node.name = "Player%dContainer" % player_id
	player_node.get_node("Label").text = Lobby.players[player_id]["name"]
	player_node.get_node("ColorRect").color = not_ready_color
	parent_node.add_child(player_node)
	return player_node


func _on_player_name_changed(new_text):
	if len(new_text) == 0:
		return
	Lobby.player_info["name"] = new_text


func _on_ready_button_pressed():
	var info = Lobby.players[multiplayer.get_unique_id()]
	info["is_ready"] = !info.get("is_ready", false)
	Lobby.update_my_player_info(info)

func _on_lobby_players_updated(players: Dictionary):
	for player_id in players:
		var info = players[player_id]
		var player_node = get_or_add_player_container(player_id)
		player_node.get_node("Label").text = info["name"]
		var color_rect = player_node.get_node("ColorRect")
		if info.get("is_ready", false):
			color_rect.color = ready_color
		else:
			color_rect.color = not_ready_color


