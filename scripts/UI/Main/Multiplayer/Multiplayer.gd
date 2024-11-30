extends Control

signal back_pressed

func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_host_pressed() -> void:
    if $Margin/HBoxContainer/Sub/Host.visible == true:
        $Margin/HBoxContainer/Sub/Host.hide()
    else:
        $Margin/HBoxContainer/Sub/Host.show()
    $Margin/HBoxContainer/Sub/Join.hide()

func _on_join_pressed() -> void:
    if $Margin/HBoxContainer/Sub/Join.visible == true:
        $Margin/HBoxContainer/Sub/Join.hide()
    else:
        $Margin/HBoxContainer/Sub/Join.show()
    $Margin/HBoxContainer/Sub/Host.hide()
