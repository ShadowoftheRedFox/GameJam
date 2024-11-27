extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# grab the keyboard focus on specific button
	$Online.grab_focus()

func _on_online_pressed() -> void:
	pass # Replace with function body.


func _on_local_pressed() -> void:
	pass # Replace with function body.


func _on_back_pressed() -> void:
	Global.goto_scene("res://scenes/UI/MainMenu.tscn")
