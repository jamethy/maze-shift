extends Label


func _ready():
	Events.player_entered_room.connect(on_player_entered_room)


func on_player_entered_room(d: Dictionary):
	if d["player_id"] == multiplayer.get_unique_id():
		set_text("Dist: %0.1fm" % d["distance"])
