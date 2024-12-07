extends Control

func _ready() -> void:
    if Input.is_action_pressed("Pause"):
        if self.visible == false:
            if !Server.multiplayer_active:
                get_tree().paused = true
            self.show()
        else:
            if !Server.multiplayer_active:
                get_tree().paused = false
            self.hide()
        
