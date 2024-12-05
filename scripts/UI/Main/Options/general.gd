extends Control

@onready var NameEdit: TextEdit = $Sound/PlayerName/HBoxContainer/TextEdit

func _on_text_edit_text_changed() -> void:
    if NameEdit.text.length() > 0:
        SaveController.parameters.Multiplayer.name = NameEdit.text
        SaveController.save_parameters()


func _on_color_picker_color_changed(color: Color) -> void:
    SaveController.parameters.Multiplayer.color = color.to_html(false)
    SaveController.save_parameters()
