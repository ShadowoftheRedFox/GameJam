class_name GlobalFalling
extends State

func enter(_previous_state_path: String, _data := {}) -> void:
    entity.animation_player.play("fall")

func physics_update(_delta: float) -> void:
    entity.velocity.y += entity.gravity * _delta
    entity.move_and_slide()

    if entity.is_on_floor():
        finished.emit("Idle")
