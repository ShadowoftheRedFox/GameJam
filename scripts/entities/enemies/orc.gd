class_name EnemiesOrc
extends GlobalEnemy

func _ready() -> void:
    attack_box = $AttackBox
    state_machine = $StateMachine
    animation_sprite = $AnimatedSprite2D
    body_collider = $CollisionShape2D
    dmg_spawn = $DmgSpawn
    hp_label = $HP
    
    HP_MAX = int(30 * Config.difficulty.hp_mult)
    hp = HP_MAX
    atk = int(4 * Config.difficulty.atk_mult)
    atk_speed = 1
    
    CRIT_RATE = 0.1 * Config.difficulty.crit_rate_mult
    CRIT_MULT = int(2 * Config.difficulty.crit_damage_mult)
    
    animate.connect(handle_animation)
    super()
    
func handle_animation(animation: String) -> void:
    match animation:
        "jump":
            $AnimatedSprite2D.play("jump")
        "idle":
            $AnimatedSprite2D.play("idle")
        "walk":
            $AnimatedSprite2D.play("walk")
        "death":
            $AnimatedSprite2D.play("death")
        "hurt":
            $AnimatedSprite2D.play("hurt")
        "attack1":
            $AnimatedSprite2D.play("attack1")
        _:
            pass
