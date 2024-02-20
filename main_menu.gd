extends Control

@onready var lobby_player_container_scene = preload("res://lobby_player_container.tscn")

var not_ready_color = Color("a22300")
var ready_color = Color("009100")

func _ready():
	Events.lobby_players_updated.connect(_on_lobby_players_updated)
	# just used for design
	$LobbyMenu/HBoxContainer/PlayersContainer/LobbyPlayerContainer.queue_free()


func _hide_all():
	for c in get_children():
		c.visible = false


func show_game_launch_menu():
	_hide_all()
	$GameLaunchMenu.visible = true


func show_host_menu():
	_hide_all()
	$HostMenu/VBoxContainer/PlayerNameContainer/LineEdit.text = Lobby.player_info["name"]
	$HostMenu.visible = true


func show_join_menu():
	_hide_all()
	$JoinMenu/VBoxContainer/PlayerNameContainer/LineEdit.text = Lobby.player_info["name"]
	$JoinMenu.visible = true


func show_lobby_menu():
	_hide_all()
	$LobbyMenu.visible = true


# GameLaunchMenu buttons

func _on_game_launch_host_button_pressed():
	show_host_menu()


func _on_game_launched_join_button_pressed():
	show_join_menu()


func _on_game_launched_local_button_pressed():
	Lobby.players[multiplayer.get_unique_id()] = Lobby.player_info
	Events.emit("started_game_from_lobby")

func _on_exit_button_pressed():
	get_tree().quit()

# HostMenu Buttons

func _on_host_host_button_pressed():
	Lobby.start_server()
	show_lobby_menu()


func _on_host_back_button_pressed():
	show_game_launch_menu()


# JoinMenu Buttons

func _on_join_back_button_pressed():
	show_game_launch_menu()


func _on_join_join_button_pressed():
	Lobby.join_game($JoinMenu/VBoxContainer/IPAddressContainer/LineEdit.text)
	show_lobby_menu()
	
# LobbyMenu

func get_player_container_or_null(player_id: int):
	var node_name = "Player%dContainer" % player_id
	var parent_node = $LobbyMenu/HBoxContainer/PlayersContainer
	return parent_node.get_node_or_null(node_name)

func get_or_add_player_container(player_id: int):
	var player_node = get_player_container_or_null(player_id)
	if player_node != null:
		return player_node
	player_node = lobby_player_container_scene.instantiate()
	player_node.name = "Player%dContainer" % player_id
	player_node.get_node("Label").text = Lobby.players[player_id]["name"]
	player_node.get_node("ColorRect").color = not_ready_color
	$LobbyMenu/HBoxContainer/PlayersContainer.add_child(player_node)
	return player_node


func _on_player_name_changed(new_text):
	if len(new_text) == 0:
		return
	Lobby.player_info["name"] = new_text


func _on_ready_button_pressed():
	var info = Lobby.players[multiplayer.get_unique_id()]
	if info.get("status") == "ready":
		info["status"] = "not_ready"
	else:
		info["status"] = "ready"
	Lobby.update_my_player_info(info)

func _on_lobby_players_updated(players: Dictionary):
	for player_id in players:
		var info = players[player_id]
		if info.get("status") == "disconnected":
			var dc_player_node = get_player_container_or_null(player_id)
			if dc_player_node != null:
				$LobbyMenu/HBoxContainer/PlayersContainer.remove_child(dc_player_node)
			continue
		var player_node = get_or_add_player_container(player_id)
		player_node.get_node("Label").text = info["name"]
		var color_rect = player_node.get_node("ColorRect")
		if info.get("status") == "ready":
			color_rect.color = ready_color
		else:
			color_rect.color = not_ready_color


func _on_lobby_back_button_pressed():
	if multiplayer.is_server():
		show_host_menu()
	else:
		show_join_menu()
	Lobby.disconnect_from_server()


func _on_lobby_start_button_pressed():
	Events.emit("started_game_from_lobby")
