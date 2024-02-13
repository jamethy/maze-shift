extends Node

# Autoload named Lobby

# copied from https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html

const PORT = 7000
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

var players_loaded_into_game = 0



func _ready():
	#multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	Events.lobby_players_updated.connect(_on_lobby_players_updated)

# both

func _on_lobby_players_updated(player_infos):
	players = player_infos

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
# TODO probably only server
#func _on_player_connected(id):
	#if multiplayer.is_server():
		#_register_player.rpc_id(id, player_info)

	

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()

func _on_player_disconnected(id):
	players.erase(id)
	Events.local_emit("player_disconnected", {"player_id": id})

# client

func join_game(address = ""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer


# Every peer will call this when they have loaded the game scene.
# do Lobby.player_loaded_into_game.rpc()
@rpc("any_peer", "call_local", "reliable")
func player_loaded_into_game():
	if multiplayer.is_server():
		players_loaded_into_game += 1
		if players_loaded_into_game == players.size():
			$/root/Game.start_game()
			players_loaded_into_game = 0


func _on_connected_to_server_ok():
	update_my_player_info(player_info)
	
func update_my_player_info(player_info):
	if multiplayer.is_server():
		players[1] = player_info
		Events.emit("lobby_players_updated", players)
	else:
		_update_my_player_info.rpc_id(1, player_info)

@rpc("any_peer", "reliable")
func _update_my_player_info(player_info):
	players[multiplayer.get_remote_sender_id()] = player_info
	Events.emit("lobby_players_updated", players)


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
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
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


