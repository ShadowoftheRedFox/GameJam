extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# grab the keyboard focus on specific button
	$Main/MarginContainer/VBoxContainer/New.grab_focus()


##### Main menu #####

func _on_new_pressed() -> void:
	#TODO unload scene
	pass


func _on_continue_pressed() -> void:
	pass # Replace with function body.
	

func _on_multiplayer_pressed() -> void:
	# Hide all menu and show host
	$Main.hide()
	$Multiplayer.show()
	$Multiplayer/MarginContainer/Main/VBoxContainer/Join.grab_focus()


func _on_options_pressed() -> void:
	# Hide all menu and show options
	$Main.hide()
	$Options.show()
	$Options/HBoxContainer/Main/VBoxContainer/Sound.grab_focus()


func _on_back_pressed() -> void:
	# Hide all menu and show main
	$Options.hide()
	$Multiplayer.hide()
	$NewGame.hide()
	$Continue.hide()
	$Main.show()
	$Main/MarginContainer/VBoxContainer/New.grab_focus()
	pass


func _on_quit_pressed() -> void:
	# quit game
	get_tree().quit()
	

##### Sub menu of new game #####


##### Sub menu of continue game #####


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
