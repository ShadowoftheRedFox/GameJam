class_name EnemieSlime
extends GlobalEnemy

func _ready() -> void:
    animation_sprite = $AnimatedSprite2D
    attack_box = $AttackBox
    state_machine = $StateMachine
    body_collider = $CollisionShape2D
    dmg_spawn = $DmgSpawn
    hp_label = $HP
    
    HP_MAX = int(40 * Config.difficulty.hp_mult)
    hp = HP_MAX
    atk = int(2 * Config.difficulty.atk_mult)
    atk_speed = 1
    
    CRIT_RATE = 0.1 * Config.difficulty.crit_rate_mult
    CRIT_MULT = int(2 * Config.difficulty.crit_damage_mult)
    
    info = "Idle"
     
    animate.connect(handle_animation)
    super()

func handle_animation(animation: String) -> void:
    match animation:
        "jump", "idle", "fall":
            animation_sprite.play("idle")
        "walk":
            animation_sprite.play("walk")
        "death":
            animation_sprite.play("death")
        "hurt":
            animation_sprite.play("damage")
        "attack1", "attack2":
            animation_sprite.play("attack")
        _:
            pass
