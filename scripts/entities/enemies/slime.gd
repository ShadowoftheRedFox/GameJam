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
    info = "Idle"
    move_texture()
    # change the color of the slime to one in the array
    var texture := sprite.texture as GradientTexture2D
    texture.gradient.set_color(0, Color(ColorVariations[randi_range(0, ColorVariations.size() - 1)]))

func move_texture() -> void:
    if !is_node_ready():
        return
    var texture = sprite.texture as GradientTexture2D
    texture.fill_from = texture_gradient_center
