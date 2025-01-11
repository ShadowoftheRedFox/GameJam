class_name GlobalJumping
extends State

func enter(_previous_state_path: String, _data := {}) -> void:
    entity.velocity.y = -entity.jump_impulse
    entity.animation_player.play("jump")

func physics_update(delta: float) -> void:
    var input_direction_x := Input.get_axis("move_left", "move_right")
    entity.velocity.x = entity.speed * input_direction_x
    entity.velocity.y += entity.gravity * delta
    entity.move_and_slide()

    if entity.velocity.y >= 0:
        finished.emit("Falling")
