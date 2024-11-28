extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# grab the keyboard focus on specific button
	$Main/MarginContainer/VBoxContainer/New.grab_focus()


##### Main menu #####

func _on_new_pressed() -> void:
	pass # Replace with function body.


func _on_continue_pressed() -> void:
	pass # Replace with function body.
	

func _on_host_pressed() -> void:
	# Hide all menu and show host
	$Main.hide()
	$Host.show()


func _on_options_pressed() -> void:
	# Hide all menu and show options
	$Main.hide()
	$Options.show()


func _on_back_pressed() -> void:
	# Hide all menu and show main
	$Options.hide()
	$Host.hide()
	$Main.show()
	pass


func _on_quit_pressed() -> void:
	# quit game
	get_tree().quit()
	

##### Sub menu of options #####
func _on_control_pressed() -> void:
	$Options/HBoxContainer/Sub/Sound.hide()
	if $Options/HBoxContainer/Sub/Controls.visible:
		$Options/HBoxContainer/Sub/Controls.hide()
	else:
		$Options/HBoxContainer/Sub/Controls.show()


func _on_sound_pressed() -> void:
	$Options/HBoxContainer/Sub/Controls.hide()
	if $Options/HBoxContainer/Sub/Sound.visible:
		$Options/HBoxContainer/Sub/Sound.hide()
	else:
		$Options/HBoxContainer/Sub/Sound.show()


##### Sub menu of host #####
