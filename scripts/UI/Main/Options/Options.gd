extends Control

signal back_pressed


func _on_back_pressed() -> void:
    back_pressed.emit()

func hide_all() -> void:
    $Margin/HBoxContainer/Sub/Controls.hide()
    $Margin/HBoxContainer/Sub/Sounds.hide()
    $Margin/HBoxContainer/Sub/Sounds.hide()

func _on_sound_pressed() -> void:
    hide_all()
    if $Margin/HBoxContainer/Sub/Sounds.visible:
        $Margin/HBoxContainer/Sub/Sounds.hide()
    else:
        $Margin/HBoxContainer/Sub/Sounds.show()


func _on_control_pressed() -> void:
    hide_all()
    if $Margin/HBoxContainer/Sub/Controls.visible:
        $Margin/HBoxContainer/Sub/Controls.hide()
    else:
        $Margin/HBoxContainer/Sub/Controls.show()


func _on_general_pressed() -> void:
    hide_all()
    if $Margin/HBoxContainer/Sub/General.visible:
        $Margin/HBoxContainer/Sub/General.hide()
    else:
        $Margin/HBoxContainer/Sub/General.show()
