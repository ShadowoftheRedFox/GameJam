extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # grab the keyboard focus on specific button
    $Main/MarginContainer/MarginContainer/VBoxContainer/New.grab_focus()

func _on_new_pressed() -> void:
    $Main.hide()
    $NewGame.show()
    $NewGame/MarginContainer/VBoxContainer/Back.grab_focus()

func _on_continue_pressed() -> void:
    $Main.hide()
    $Continue.show()
    $Continue/MarginContainer/VBoxContainer/Back.grab_focus()
    

func _on_multiplayer_pressed() -> void:
    # Hide all menu and show host
    $Main.hide()
    $Multiplayer.show()
    $Multiplayer/Margin/HBoxContainer/Main/VBoxContainer/Join.grab_focus()

func _on_options_pressed() -> void:
    # Hide all menu and show options
    $Main.hide()
    $Options.show()
    $Options/Margin/HBoxContainer/Main/VBoxContainer/Sound.grab_focus()

func _on_quit_pressed() -> void:
    # quit game
    get_tree().quit()

func generic_back_pressed() -> void:
    $Main.show()
    $Main/MarginContainer/MarginContainer/VBoxContainer/New.grab_focus()

func _on_multiplayer_back_pressed() -> void:
    $Multiplayer.hide()
    generic_back_pressed()


func _on_options_back_pressed() -> void:
    $Options.hide()
    generic_back_pressed()


func _on_new_game_back_pressed() -> void:
    $NewGame.hide()
    generic_back_pressed()


func _on_continue_back_pressed() -> void:
    $Continue.hide()
    generic_back_pressed()
