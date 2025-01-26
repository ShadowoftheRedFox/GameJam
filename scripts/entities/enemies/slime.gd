class_name EnemieSlime
extends GlobalEnemy

const ColorVariations = [
    "20ff0097", # green
    "ff000097", # red
    "000aff97", # blue
    "fff50097", # yellow
]

@export var texture_gradient_center: Vector2 = Vector2(0.5, 0.5):
    set(value):
        texture_gradient_center = value
        move_texture()

@onready var sprite = $Sprite2D

func _ready() -> void:
    animation_player = $AnimationPlayer
    attack_box = $AttackBox
    state_machine = $StateMachine
    body_collider = $CollisionShape2D
    
    info = "Idle"
    move_texture()
    # change the color of the slime to one in the array
    var texture := sprite.texture as GradientTexture2D
    texture.gradient.set_color(0, Color(ColorVariations[randi_range(0, ColorVariations.size() - 1)]))
    
    animate.connect(handle_animation)
    super()

func handle_animation(animation: String) -> void:
    match animation:
        "jump":
            $AnimationPlayer.play("jump")
        "idle":
            $AnimationPlayer.play("idle")
        "walk":
            $AnimationPlayer.play("move")
        "death":
            $AnimationPlayer.play("death")
        "hurt":
            $AnimationPlayer.play("hurt")
        "attack1":
            $AnimationPlayer.play("attack1")
        _:
            pass


func move_texture() -> void:
    if !is_node_ready():
        return
    var texture = sprite.texture as GradientTexture2D
    texture.fill_from = texture_gradient_center
