extends Control

signal back_pressed


func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_sound_pressed() -> void:
    if $Margin/HBoxContainer/Sub/Sounds.visible:
        $Margin/HBoxContainer/Sub/Sounds.hide()
    else:
        $Margin/HBoxContainer/Sub/Sounds.show()
    $Margin/HBoxContainer/Sub/Controls.hide()


func _on_control_pressed() -> void:
    if $Margin/HBoxContainer/Sub/Controls.visible:
        $Margin/HBoxContainer/Sub/Controls.hide()
    else:
        $Margin/HBoxContainer/Sub/Controls.show()
    $Margin/HBoxContainer/Sub/Sounds.hide()
