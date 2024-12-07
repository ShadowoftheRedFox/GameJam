extends Control

func _on_text_edit_text_changed(new_text: String) -> void:
    if new_text.length() > 0:
        SaveController.parameters.Multiplayer.name = new_text
        SaveController.save_parameters()


func _on_color_picker_color_changed(color: Color) -> void:
    SaveController.parameters.Multiplayer.color = color.to_html(false)
    SaveController.save_parameters()
