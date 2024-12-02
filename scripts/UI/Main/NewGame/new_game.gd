extends Control

signal back_pressed

func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_new_pressed() -> void:
    var new_button: Button = $MarginContainer/VBoxContainer/New
    var save_name: LineEdit = $MarginContainer/VBoxContainer/SaveName/LineEdit
    var difficulty: OptionButton = $MarginContainer/VBoxContainer/Difficulty/OptionButton
    var size: OptionButton = $MarginContainer/VBoxContainer/Size/OptionButton
    if new_button.disabled == false:
        GameController.new_game(save_name.text, difficulty.selected, size.selected)


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
    
    
