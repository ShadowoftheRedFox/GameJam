extends Control

signal back_pressed

enum PreviousMenu {
    Join,
    Host,
    None
}

var previous_menu = PreviousMenu.None

func _on_back_pressed() -> void:
    back_pressed.emit()


func _on_host_pressed() -> void:
    if $Margin/HBoxContainer/Sub/Host.visible == true:
        $Margin/HBoxContainer/Sub/Host.hide()
        previous_menu = PreviousMenu.None
    else:
        $Margin/HBoxContainer/Sub/Host.show()
        previous_menu = PreviousMenu.Host
    $Margin/HBoxContainer/Sub/Join.hide()

func _on_join_pressed() -> void:
    if $Margin/HBoxContainer/Sub/Join.visible == true:
        $Margin/HBoxContainer/Sub/Join.hide()
        previous_menu = PreviousMenu.None
    else:
        $Margin/HBoxContainer/Sub/Join.show()
        previous_menu = PreviousMenu.Join
    $Margin/HBoxContainer/Sub/Host.hide()


func _on_waiting_back_pressed() -> void:
    $Margin/HBoxContainer/Sub/Waiting.hide()
    $Margin/HBoxContainer/Main.show()
    match  previous_menu:
        PreviousMenu.None: pass
        PreviousMenu.Join: $Margin/HBoxContainer/Sub/Join.show()
        PreviousMenu.Host: $Margin/HBoxContainer/Sub/Host.show()


func _on_join_multiplayer_pressed() -> void:
    $Margin/HBoxContainer/Sub/Waiting.show()
    $Margin/HBoxContainer/Main.hide()


func _on_host_multiplayer_pressed() -> void:
    $Margin/HBoxContainer/Sub/Waiting.show()
    $Margin/HBoxContainer/Main.hide()
