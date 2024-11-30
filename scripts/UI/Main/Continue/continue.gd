extends Control

signal back_pressed

func _ready() -> void:
    # TODO load available save and add them into the option button
    pass

func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_delete_pressed() -> void:
    pass # Replace with function body.


func _on_edit_pressed() -> void:
    pass # Replace with function body.


func _on_new_pressed() -> void:
    pass # Replace with function body.


func _on_option_button_item_selected(index: int) -> void:
    pass # Replace with function body.
