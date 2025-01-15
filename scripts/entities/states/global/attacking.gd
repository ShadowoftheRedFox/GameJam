class_name GlobalAttacking
extends State

func enter(_previous_state_path: String, _data := {}) -> void:
    if entity.animation_player:
        entity.animation_player.play("attack1")
    if entity.animation_sprite:
        entity.animation_sprite.play("attack1")
    entity.info = "Attacking target"

func physics_update(delta: float) -> void:
    if entity.target_player == null:
        finished.emit("Idle")
        return
    
    var input_direction_x := entity.global_position.direction_to(entity.target_player.global_position).x
    if entity.animation_sprite:
        entity.animation_sprite.flip_h = input_direction_x < 0
    entity.velocity.x = entity.speed * input_direction_x
    entity.velocity.y += entity.gravity * delta
    entity.move_and_slide()
    
    if entity.animation_sprite and !entity.animation_sprite.is_playing():
        finished.emit("Idle")
    if entity.animation_player and !entity.animation_player.is_playing():
        finished.emit("Idle")
        
