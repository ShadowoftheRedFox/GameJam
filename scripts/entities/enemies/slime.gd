class_name  EnemieSlime
extends GlobalEnemy

@export var texture_gradient_center: Vector2 = Vector2(0.5, 0.5):
    set(value):
        texture_gradient_center = value
        move_texture()

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
    $AnimationPlayer.play("idle")
    info = "Idle"

func move_texture() -> void:
    if !is_node_ready():
        return
    var gradient = sprite.texture as GradientTexture2D
    gradient.fill_from = texture_gradient_center
