class_name GlobalJumping
extends State

func enter(_previous_state_path: String, _data := {}) -> void:
    entity.velocity.y = -entity.jump_impulse
    entity.animation_player.play("jump")
    entity.info = "Jumping because of wall"

func update(_delta: float) -> void:
    if entity.target_player == null:
        finished.emit("Idle")
        return
        
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

    if !entity.is_on_floor():
        entity.animation_player.play("fall")
    else:
        finished.emit("Moving")
