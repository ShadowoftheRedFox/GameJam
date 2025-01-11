class_name GlobalMoving
extends State

func enter(_previous_state_path: String, _data := {}) -> void:
    entity.animation_player.play("move")

func update(_delta: float) -> void:
    # check if entity target is within range, or find the nearest in range
    if entity.target_player == null:
        # get the nearest player
        var found = false
        for p in get_tree().root.get_children():
            if p is BasePlayer:
                var player = p as BasePlayer
                var min: float = entity.target_range
                var current = entity.global_position.distance_squared_to(player.global_position) 
                if current <= min:
                    found = true
                    min = current
                    entity.target_player = player
        
        if found:
            entity.info = "Found target"
        else:
            entity.info = "Idle"
    else:
        if entity.global_position.distance_squared_to(entity.target_player.global_position) > entity.target_range:
            entity.info = "Idle"
            entity.target_player = null
            finished.emit("Idle")

func physics_update(delta: float) -> void:
    if entity.target_player == null:
        finished.emit("Idle")
        return
    
    var input_direction_x := entity.global_position.direction_to(entity.target_player.global_position).x
    entity.velocity.x = entity.speed * input_direction_x
    entity.velocity.y += entity.gravity * delta
    entity.move_and_slide()

    if not entity.is_on_floor():
        finished.emit("Falling")
    elif is_equal_approx(input_direction_x, 0.0):
        finished.emit("Idle")
