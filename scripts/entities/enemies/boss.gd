class_name EnemiesBoss
extends GlobalEnemy

func _ready() -> void:
    attack_box = $AttackBox
    state_machine = $StateMachine
    animation_sprite = $AnimatedSprite2D
    body_collider = $CollisionShape2D
    dmg_spawn = $DmgSpawn
    hp_label = $HP
    
    HP_MAX = int(150 * Config.difficulty.hp_mult)
    hp = HP_MAX
    atk = int(8 * Config.difficulty.atk_mult)
    atk_speed = 1
    
    CRIT_RATE = 0.1 * Config.difficulty.crit_rate_mult
    CRIT_MULT = int(2 * Config.difficulty.crit_damage_mult)
    
    speed = 20.0
    target_range = 100000.0
    jump_impulse = 200.0
    disappear_on_death = false
    is_boss = true
    
    animate.connect(handle_animation)
    ondeath.connect(handle_end_game)
    super()
    
func handle_end_game(killer: Node2D) -> void:
    var id = 0
    if killer is BasePlayer:
        id = killer.multiplayer_authority_id
    
    Multi.end_game.rpc(id)

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
