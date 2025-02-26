class_name GlobalAttacking
extends State

var attack_cooldown: float = 0

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
    
    attack_cooldown = 1.0 / float(entity.atk_speed)
    entity.animate.emit("attack1")
    entity.info = "Attacking target"

func physics_update(delta: float) -> void:
    if entity.target_player == null:
        finished.emit("Idle")
        return
    
    attack_cooldown -= delta
    if attack_cooldown <= 0:
        finished.emit("Idle")
        
func exit() -> void:
    attack_cooldown = 0
    entity.attack_box.get_child(0).set_deferred("disabled", true)
    Game.Utils.remove_signal_listener(entity.attack_box.body_entered)

func attacking(body: Node2D) -> void:
    var crit_mult = (entity.CRIT_MULT) if (randf() <= entity.CRIT_RATE) else 1
    if body is GlobalEnemy and entity.friendly_fire:
        (body as GlobalEnemy).damaged.emit(body, entity.atk * crit_mult, crit_mult != 1)
    if body is BasePlayer:
        (body as BasePlayer).damaged.emit(body, entity.atk * crit_mult, crit_mult != 1)
    # TODO destroy some projectiles?
