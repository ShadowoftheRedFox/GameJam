class_name EnemieSlime
extends GlobalEnemy

func _ready() -> void:
    animation_sprite = $AnimatedSprite2D
    attack_box = $AttackBox
    state_machine = $StateMachine
    body_collider = $CollisionShape2D
    dmg_spawn = $DmgSpawn
    hp_label = $HP
    
    HP_MAX = 20
    atk = 1
    hp = HP_MAX
    atk_speed = 1.2
    
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
