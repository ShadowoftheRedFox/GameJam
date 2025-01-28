class_name EditMenu
extends Control

signal back_pressed
signal get_save(display_name: String, data: Dictionary)

var true_save_name: String = ""
var display_save_name: String = ""
var save_data: Dictionary = {}

@onready var difficulty_options: OptionButton = $MarginContainer/VBoxContainer/Difficulty/OptionButton
@onready var gamemode_options: OptionButton = $MarginContainer/VBoxContainer/GameMode/OptionButton
@onready var save_name_label: Label = $VBoxContainer/SaveName
@onready var save_name_edit: LineEdit = $MarginContainer/VBoxContainer/SaveName/LineEdit

func _ready() -> void:
    get_save.connect(load_get_save)
    for diff in Game.Difficulties:
        difficulty_options.add_item(Game.DifficultiesNames[Game.Difficulties.get(diff)], Game.Difficulties.get(diff))
    for gm in Game.GameModes:
        gamemode_options.add_item(Game.GameModesNames[Game.GameModes.get(gm)], Game.GameModes.get(gm))

func load_get_save(string: String, data: Dictionary) -> void:
    save_data = data.duplicate(true)
    true_save_name = Save.get_save_name(string)
    display_save_name = string
    save_name_edit.text = string
    save_name_label.text = string
    difficulty_options.select(save_data.difficulty)
    gamemode_options.select(save_data.gamemode)

func _on_save_pressed() -> void:
    Save.update_save(true_save_name, {
        Save.UpdateActions.CHANGE_DISPLAY_NAME: display_save_name,
        Save.UpdateActions.CHANGE_SAVE_CONTENT: JSON.stringify(save_data)
    })
    back_pressed.emit()

func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_line_edit_text_changed(new_text: String) -> void:
    if new_text.length() > 0:
        save_name_label.text = new_text
        display_save_name = new_text

func _on_option_difficulty_item_selected(index: int) -> void:
    save_data.difficulty = difficulty_options.get_item_id(index)


func _on_option_gamemode_item_selected(index: int) -> void:
    save_data.gamemode = gamemode_options.get_item_id(index)
