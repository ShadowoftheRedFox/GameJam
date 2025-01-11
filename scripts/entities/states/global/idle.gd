class_name GlobalIdle
extends State

@warning_ignore("unused_parameter")
func enter(_previous_state_path: String, _data := {}) -> void:
    entity.velocity.x = 0.0
    entity.animation_player.play("idle")

func update(_delta: float) -> void:
    # check if entity target is within range, or find the nearest in range
    if entity.target_player == null:
        # get the nearest player
        var found = false
        for p in get_tree().root.get_children():
            if p is BasePlayer:
                var player = p as BasePlayer
                var min_dist: float = entity.target_range
                var current = entity.global_position.distance_squared_to(player.global_position) 
                if current <= min_dist:
                    found = true
                    min_dist = current
                    entity.target_player = player
        
        if found:
            entity.info = "Found target"
            finished.emit("Moving")
        else:
            entity.info = "Idle"
    else:
        if entity.global_position.distance_squared_to(entity.target_player.global_position) > entity.target_range:
            entity.info = "Idle"
            entity.target_player = null
    
func physics_update(_delta: float) -> void:
    entity.velocity.y += entity.gravity * _delta
    entity.move_and_slide()
    
    # TODO basic enemy AI

    if !entity.is_on_floor():
        finished.emit("Falling")
