class_name MainMenu
extends Control
@onready var buff: Buff = $CenterContainer/Buff
var credits = preload("res://scenes/UI/Main/credits.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    assert(get_parent() == get_tree().root, "MainMenu should always be in root")
    
    # grab the keyboard focus on specific button
    $Main/MarginContainer/MarginContainer/VBoxContainer/New.grab_focus()
    
    # enable the button if any save is available
    update_continue_state()
    Save.saves_changed.connect(update_continue_state)

func update_continue_state() -> void:
    # enable or disable the continue button
    $Main/MarginContainer/MarginContainer/VBoxContainer/Continue.disabled = len(Save.save_names) == 0

func _on_new_pressed() -> void:
    $Main.hide()
    $NewGame.show()
    $NewGame/MarginContainer/VBoxContainer/Back.grab_focus()
    buff.transition_to_color(2, Color.DARK_SLATE_BLUE)

func _on_continue_pressed() -> void:
    $Main.hide()
    $Continue.show()
    $Continue/Main/MarginContainer/VBoxContainer/Back.grab_focus()
    buff.transition_to_color(2, Color.DARK_ORANGE)
    

func _on_multiplayer_pressed() -> void:
    # Hide all menu and show host
    $Main.hide()
    $Multiplayer.show()
    $Multiplayer/Margin/HBoxContainer/Main/VBoxContainer/Join.grab_focus()
    buff.transition_to_color(2, Color.YELLOW)

func _on_options_pressed() -> void:
    # Hide all menu and show options
    $Main.hide()
    $Options.show()
    $Options/Margin/HBoxContainer/Main/VBoxContainer/Sound.grab_focus()
    buff.transition_to_color(2, Color.DARK_BLUE)

func _on_quit_pressed() -> void:
    # quit game
    get_tree().quit()

func generic_back_pressed() -> void:
    $Main.show()
    $Main/MarginContainer/MarginContainer/VBoxContainer/New.grab_focus()
    buff.transition_to_color(2, Color.CRIMSON)

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


func _on_credits_pressed() -> void:
    # sometimes, main is deleted, tell transition that it's himself we want to remove
    Transition.current_scene = self
    Transition.message = ""
    Transition._deferred_change_scene("res://scenes/UI/Main/credits.tscn")


func _on_test_menu_back_pressed() -> void:
    $TestMenu.hide()
    generic_back_pressed()


func _on_test_pressed() -> void:
    $TestMenu.show()
    $Main.hide()
