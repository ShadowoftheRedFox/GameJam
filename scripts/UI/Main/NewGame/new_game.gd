extends Control

signal back_pressed

func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_new_pressed() -> void:
    var generator = NewGame.new()
    generator.new_game()
