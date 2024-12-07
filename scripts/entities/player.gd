class_name BasePlayer
extends CharacterBody2D

#### Multiplayer ####
var is_multiplayer: bool = false

#### Movement ####
@export var walk_speed: float = 300.0
@export var air_speed: float = 300.0
@export var wall_speed: float = 300.0
@export var jump_force: float = 300.0
@export var air_jump_force: float = 300.0
@export var wall_jump_force: float = 300.0
@export var air_jump_amount: int = 2;
var air_jump_remaining: int = air_jump_amount

var direction: Vector2 = Vector2.ZERO
var ground_direction: float = 0.0

#### Graphic ####
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
    
func set_player_name(player_name: String) -> void:
    $DisplayName.text = player_name

func set_authority(id: int) -> void:
    $MultiplayerSynchronizer.set_multiplayer_authority(id, true)
    #print("Current id: ", multiplayer.get_unique_id(), " Target id: ", id)

func disable_others_camera(id: int) -> void:
    # disable camera of player instance if it's not our player   
    if id != multiplayer.get_unique_id():
        $Camera2D.enabled = false

func _physics_process(delta: float) -> void:
    var multi_auth = int($DisplayName.text)
    if multi_auth == multiplayer.get_unique_id() or is_multiplayer == false:
        direction = Input.get_vector("Left", "Right", "Up", "Down")
        ground_direction = Input.get_axis("Left", "Right")
        
        # idle
        if ground_direction == 0:
            anim_sprite_2d.play("idle")
        else:
            # walk
            anim_sprite_2d.play("walk")
        
        # TODO differentiate on player position and buffs
        
        # use below only if can fly
        #velocity = direction * air_speed
        
        if ground_direction:
            velocity.x = ground_direction * walk_speed
            
            # flip the sprite 
            if ground_direction >= 0:
                sprite_2d.flip_h = false
                anim_sprite_2d.flip_h = false
            else:
                sprite_2d.flip_h = true
                anim_sprite_2d.flip_h = true
        else:
            velocity.x = move_toward(velocity.x, 0, walk_speed)
        
        # jump
        if is_on_floor():
            air_jump_remaining = air_jump_amount
            if Input.is_action_just_pressed("Jump"):
                velocity.y = -jump_force
        else:
            if Input.is_action_just_pressed("Jump") and air_jump_remaining > 0:
                velocity.y = -jump_force
                air_jump_remaining-=1
    
    if not is_on_floor():
        velocity += get_gravity() * delta
    
    move_and_slide()
