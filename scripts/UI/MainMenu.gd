extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# grab the keyboard focus on specific button
	$New.grab_focus()

func _on_new_pressed() -> void:
	pass # Replace with function body.


func _on_continue_pressed() -> void:
	pass # Replace with function body.


func _on_host_pressed() -> void:
	Global.goto_scene("res://scenes/UI/HostMenu.tscn")


func _on_options_pressed() -> void:
	Global.goto_scene("res://scenes/UI/OptionsMenu.tscn")


func _on_quit_pressed() -> void:
	# quit game
	get_tree().quit()
