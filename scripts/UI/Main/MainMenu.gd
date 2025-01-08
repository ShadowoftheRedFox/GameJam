class_name  MainMenu
extends Control
@onready var buff: Buff = $CenterContainer/Buff
var credits = preload("res://scenes/UI/Main/credits.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # grab the keyboard focus on specific button
    $Main/MarginContainer/MarginContainer/VBoxContainer/New.grab_focus()
    
    # enable the button if any save is available
    update_continue_state()
    SaveController.saves_changed.connect(update_continue_state)

func update_continue_state() -> void:
    # enable or disable the continue button
    $Main/MarginContainer/MarginContainer/VBoxContainer/Continue.disabled = len(SaveController.save_names) == 0

func _on_new_pressed() -> void:
    $Main.hide()
    $NewGame.show()
    $NewGame/MarginContainer/VBoxContainer/Back.grab_focus()
    buff.particle_color = Color.DARK_SLATE_BLUE

func _on_continue_pressed() -> void:
    $Main.hide()
    $Continue.show()
    $Continue/Main/MarginContainer/VBoxContainer/Back.grab_focus()
    buff.particle_color = Color.DARK_ORANGE
    

func _on_multiplayer_pressed() -> void:
    # Hide all menu and show host
    $Main.hide()
    $Multiplayer.show()
    $Multiplayer/Margin/HBoxContainer/Main/VBoxContainer/Join.grab_focus()
    buff.particle_color = Color.YELLOW

func _on_options_pressed() -> void:
    # Hide all menu and show options
    $Main.hide()
    $Options.show()
    $Options/Margin/HBoxContainer/Main/VBoxContainer/Sound.grab_focus()
    buff.particle_color = Color.DARK_BLUE

func _on_quit_pressed() -> void:
    # quit game
    get_tree().quit()

func generic_back_pressed() -> void:
    $Main.show()
    $Main/MarginContainer/MarginContainer/VBoxContainer/New.grab_focus()
    buff.particle_color = Color.CRIMSON

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
    TransitionController.current_scene = self
    TransitionController.message = ""
    TransitionController._deferred_change_scene("res://scenes/UI/Main/credits.tscn")
