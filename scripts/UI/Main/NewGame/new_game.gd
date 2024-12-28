extends Control

signal back_pressed

@onready var difficulty_options: OptionButton = $MarginContainer/VBoxContainer/Difficulty/OptionButton
@onready var gamemode_options: OptionButton = $MarginContainer/VBoxContainer/GameMode/OptionButton
@onready var size_options: OptionButton = $MarginContainer/VBoxContainer/Size/OptionButton

func _ready() -> void:
    for diff in GameController.Difficulties:
        difficulty_options.add_item(GameController.DifficultiesNames[GameController.Difficulties.get(diff)], GameController.Difficulties.get(diff))
    for gm in GameController.GameModes:
        gamemode_options.add_item(GameController.GameModesNames[GameController.GameModes.get(gm)], GameController.GameModes.get(gm))
    for so in GameController.MapSizes:
        size_options.add_item(GameController.MapSizesNames[GameController.MapSizes.get(so)], GameController.MapSizes.get(so))
    
func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_new_pressed() -> void:
    var new_button: Button = $MarginContainer/VBoxContainer/New
    var save_name: LineEdit = $MarginContainer/VBoxContainer/SaveName/LineEdit
    if new_button.disabled == false:
        GameController.new_game(
            save_name.text, 
            difficulty_options.get_item_id(difficulty_options.selected), 
            size_options.get_item_id(size_options.selected), 
            gamemode_options.get_item_id(gamemode_options.selected)
        )


func _on_line_edit_text_changed(new_text: String) -> void:
    var new_button: Button = $MarginContainer/VBoxContainer/New
    var error_text: Label = $MarginContainer/VBoxContainer/Error
    if new_text.length() > 0:
        # check if save name already exists
        if not SaveController.is_save_name(new_text):
            new_button.disabled = false
            error_text.text = ""
            return
        else:
            error_text.text = "Une sauvegarde existe déjà sous ce nom!"
    else:
        error_text.text = "La partie requiert un nom!"
    
    new_button.disabled = true
    
    
