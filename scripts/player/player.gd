class_name BasePlayer
extends CharacterBody2D

@export var walk_speed:float = 300.0
@export var air_speed:float = 300.0
@export var wall_speed:float = 300.0
@export var jump_force:float = 300.0
@export var air_jump_force:float = 300.0
@export var wall_jump_force:float = 300.0

var direction:Vector2 = Vector2.ZERO

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		direction = Input.get_vector("Left", "Right", "Up", "Down")
		# TODO differentiate on player position and buffs
		velocity = direction * walk_speed
	move_and_slide()
