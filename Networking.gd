extends Node

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 6

var server = null
var client = null

var ip_address = ""
var current_player_username = ""

var client_connected_to_server = false
var networked_object_name_index = 0 : set = networked_object_name_index_set

@onready var client_connection_timeout_timer = Timer.new()

func _ready() -> void:
	multiplayer.connection_failed.connect(self._connection_failed)
	multiplayer.server_disconnected.connect(self._server_disconnected)
	multiplayer.connected_to_server.connect(self._connected_to_server)

	add_child(client_connection_timeout_timer)
	client_connection_timeout_timer.wait_time = 10
	client_connection_timeout_timer.one_shot = true
	
	client_connection_timeout_timer.connect("timeout",Callable(self,"_client_connection_timeout"))
	
	if OS.get_name() == "Windows":
		ip_address = IP.get_local_addresses()[3]
	elif OS.get_name() == "Android":
		ip_address = IP.get_local_addresses()[0]
	else:
		ip_address = IP.get_local_addresses()[3]
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			ip_address = ip


func create_server() -> void:
	server = ENetMultiplayerPeer.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	multiplayer.set_multiplayer_peer(server)


func join_server() -> void:
	client = ENetMultiplayerPeer.new()
	client.create_client(ip_address, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(client)
	client_connection_timeout_timer.start()

func reset_network_connection() -> void:
	if multiplayer.has_multiplayer_peer():
		#if Persistent_nodes.get_child_count() > 1:
			#for node in Persistent_nodes.get_children():
					#node.queue_free()

		multiplayer.multiplayer_peer = null

func _connected_to_server() -> void:
	print("Successfully connected to the server")
	client_connected_to_server = true

func _server_disconnected() -> void:
	print("Disconnected from the server")
	
	#for child in Persistent_nodes.get_children():
		#if child.is_in_group("Net"):
			#child.queue_free()
	
	reset_network_connection()
	

func _client_connection_timeout():
	if client_connected_to_server == false:
		print("Client has been timed out")
		reset_network_connection()


func _connection_failed():
	#for child in Persistent_nodes.get_children():
		#if child.is_in_group("Net"):
			#child.queue_free()
	reset_network_connection()
	

@rpc("any_peer")
func peer_networked_object_name_index_set(new_value):
	networked_object_name_index = new_value

func networked_object_name_index_set(new_value):
	networked_object_name_index = new_value
	
	if get_tree().is_server():
		rpc("peer_networked_object_name_index_set", networked_object_name_index)
