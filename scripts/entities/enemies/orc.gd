class_name EnemiesOrc
extends GlobalEnemy

func _ready() -> void:
    attack_box = $AttackBox
    state_machine = $StateMachine
    animation_sprite = $AnimatedSprite2D
    body_collider = $CollisionShape2D
    
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
