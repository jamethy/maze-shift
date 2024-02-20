extends Node

# Autoload named Lobby

# copied from https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html

const DEFAULT_PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "", "status": "unknown"}
var game_status = "unknown"


func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Events.lobby_players_updated.connect(_on_lobby_players_updated)
	Events.started_game_from_lobby.connect(_on_started_game_from_lobby)
	Events.loaded_into_game.connect(_on_loaded_into_game)


func _on_loaded_into_game(d: Dictionary):
	players[d["player_id"]]["status"] = "in_game"
	if multiplayer.is_server():
		var all_players_in = true
		for player_id in players:
			if players[player_id]["status"] != "in_game": # TODO handle disconnected
				all_players_in = false
				break
		if all_players_in:
			Events.emit("all_players_loaded_game")


# both

func _on_player_connected(id):
	if multiplayer.is_server():
		_receive_joining_server_info.rpc_id(id, {
			"game_status": game_status,
			"players": players,
		})


@rpc("authority", "call_remote", "reliable")
func _receive_joining_server_info(info: Dictionary):
	game_status = info["game_status"]
	players = info["players"]
	Events.local_emit("lobby_players_updated", players)
	if game_status in ["loading_in", "game_started"]:
		_on_started_game_from_lobby({})


func _on_lobby_players_updated(player_infos):
	players = player_infos


func _on_player_disconnected(id):
	players[id]["status"] = "disconnected"
	Events.emit("lobby_players_updated", players)

# client

func join_game(address = ""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, DEFAULT_PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer


func _on_started_game_from_lobby(_d):
	get_tree().change_scene_to_file("res://TheMaze.tscn")
	game_status = "loading_in"


func _on_connected_to_server_ok():
	update_my_player_info(player_info)
	
func update_my_player_info(updated_player_info):
	if multiplayer.is_server():
		players[multiplayer.get_unique_id()] = updated_player_info
		Events.emit("lobby_players_updated", players)
	else:
		_update_my_player_info.rpc_id(1, updated_player_info)

@rpc("any_peer", "reliable")
func _update_my_player_info(updated_player_info):
	players[multiplayer.get_remote_sender_id()] = updated_player_info
	Events.emit("lobby_players_updated", players)


func disconnect_from_server():
	multiplayer.multiplayer_peer = null
	Events.local_emit("lobby_players_updated", {})

func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	Events.local_emit("server_disconnected")

# server only
# - new_player_connected

func start_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	Events.local_emit("lobby_players_updated", players)


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)
