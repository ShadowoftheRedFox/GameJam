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
    #if $Margin/HBoxContainer/Sub/Host.visible == true:
        #$Margin/HBoxContainer/Sub/Host.hide()
        #previous_menu = PreviousMenu.None
    #else:
        #$Margin/HBoxContainer/Sub/Host.show()
        #previous_menu = PreviousMenu.Host
    #$Margin/HBoxContainer/Sub/Join.hide()
    $Margin/HBoxContainer/Sub/HostRoom.visible = !$Margin/HBoxContainer/Sub/HostRoom.visible
    $Margin/HBoxContainer/Sub/Join.visible = false
    

func _on_join_pressed() -> void:
    #if $Margin/HBoxContainer/Sub/Join.visible == true:
        #$Margin/HBoxContainer/Sub/Join.hide()
        #previous_menu = PreviousMenu.None
    #else:
        #$Margin/HBoxContainer/Sub/Join.show()
        #previous_menu = PreviousMenu.Join
    #$Margin/HBoxContainer/Sub/Host.hide()
    $Margin/HBoxContainer/Sub/HostRoom.hide()
    $JoinRoom.show()
    $Margin.hide()

func _on_join_manually_pressed() -> void:
    $Margin/HBoxContainer/Sub/Join.visible = !$Margin/HBoxContainer/Sub/Join.visible
    $Margin/HBoxContainer/Sub/HostRoom.visible = false
    

func _on_waiting_back_pressed() -> void:
    $Margin/HBoxContainer/Sub/Waiting.hide()
    $Margin/HBoxContainer/Main.show()
    $Margin/HBoxContainer/Sub/HostRoom.hide()

func _on_join_multiplayer_pressed() -> void:
    $Margin/HBoxContainer/Sub/Waiting.show()
    $Margin/HBoxContainer/Main.hide()


func _on_host_multiplayer_pressed() -> void:
    $Margin/HBoxContainer/Sub/Waiting.show()
    $Margin/HBoxContainer/Main.hide()


func _on_join_room_back_pressed() -> void:
    $JoinRoom.hide()
    $Margin.show()


func _on_join_room_join_pressed() -> void:
    $JoinRoom.hide()
    $Margin.show()
    $Margin/HBoxContainer/Sub/Waiting.show()
    $Margin/HBoxContainer/Main.hide()
