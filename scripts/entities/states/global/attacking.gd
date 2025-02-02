class_name GlobalAttacking
extends State

func enter(_previous_state_path: String, _data := {}) -> void:
    var input_direction_x := entity.global_position.direction_to(entity.target_player.global_position).x
    # enable hitbox
    entity.attack_box.get_child(0).set_deferred("disabled", false)
    # change side of the attack hitbox
    if input_direction_x > 0:
        entity.attack_box.rotation = deg_to_rad(0.0)
    else:
        entity.attack_box.rotation = deg_to_rad(180.0)
    
    entity.attack_box.body_entered.connect(attacking)

    entity.animate.emit("attack1")
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
    
    if entity.global_position.distance_squared_to(entity.target_player.global_position) > 1000 * entity.scale.x:
        finished.emit("Idle")
    if entity.animation_sprite and !entity.animation_sprite.is_playing():
        finished.emit("Idle")
    if entity.animation_player and !entity.animation_player.is_playing():
        finished.emit("Idle")
        
func exit() -> void:
    entity.attack_box.get_child(0).set_deferred("disabled", true)
    Game.Utils.remove_signal_listener(entity.attack_box.body_entered)

func attacking(body: Node2D) -> void:
    var crit_mult = (entity.CRIT_MULT) if (randf() <= entity.CRIT_RATE) else 1
    if body is GlobalEnemy and entity.friendly_fire:
        (body as GlobalEnemy).damaged.emit(entity.atk * crit_mult, crit_mult != 1)
    if body is BasePlayer:
        (body as BasePlayer).damaged.emit(entity.atk * crit_mult, crit_mult != 1)
    # TODO destroy some projectiles?
