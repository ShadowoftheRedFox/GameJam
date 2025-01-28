extends Control

func _on_text_edit_text_changed(new_text: String) -> void:
    if new_text.length() > 0:
        Save.parameters.Multiplayer.name = new_text
        Save.save_parameters()


func _on_color_picker_color_changed(color: Color) -> void:
    Save.parameters.Multiplayer.color = color.to_html(false)
    Save.save_parameters()
