class_name BasePlayer
extends CharacterBody2D

#### Movement ####
@export var WALK_SPEED: float = 300.0
@export var AIR_SPEED: float = 300.0
@export var WALL_SPEED: float = 300.0
@export var JUMP_FORCE: float = 300.0
@export var AIR_JUMP_FORCE: float = 300.0
@export var WALL_JUMP_FORCE: float = 300.0
@export var AIR_JUMP_AMOUNT: int = 2;
@export var MAX_INERTIA_X: float = 1000.0
@export var MAX_INERTIA_Y: float = 1000.0
var air_jump_remaining: int = AIR_JUMP_AMOUNT

var direction: Vector2 = Vector2.ZERO
var ground_direction: float = 0.0

#### Graphic ####
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#### Multiplayer Data ####
var multiplayer_authority_id: int = 0

#func _ready() -> void:
    ## set ratio for pause menu and label
    #$DisplayName.scale = Vector2(1 / self.scale.x, 1 / self.scale.y)
    #$Camera2D/Pause.scale = Vector2(1 / self.scale.x, 1 / self.scale.y)
    
func set_player_name(player_name: String) -> void:
    $DisplayName.text = player_name

func set_authority(id: int) -> void:
    $MultiplayerSynchronizer.set_multiplayer_authority(id, true)
    multiplayer_authority_id = id
    #print("Current id: ", multiplayer.get_unique_id(), " Target id: ", id)

func disable_others_camera(id: int) -> void:
    # disable camera of player instance if it's not our player   
    if id != multiplayer.get_unique_id():
        $Camera2D.enabled = false

func _physics_process(delta: float) -> void:
    # is_multiplayer_authority() should do it, but on debug multiple instance, create weird things
    if multiplayer_authority_id == multiplayer.get_unique_id() or Server.solo_active == true:
        if Input.is_action_just_pressed("Pause"):
            GameController.pause()
            return
        
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
            velocity.x = ground_direction * WALK_SPEED
            
            # flip the sprite 
            if ground_direction >= 0:
                sprite_2d.flip_h = false
                anim_sprite_2d.flip_h = false
            else:
                sprite_2d.flip_h = true
                anim_sprite_2d.flip_h = true
        else:
            velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
        
        # jump
        if is_on_floor():
            air_jump_remaining = AIR_JUMP_AMOUNT
            if Input.is_action_just_pressed("Jump"):
                velocity.y = -JUMP_FORCE
        else:
            if Input.is_action_just_pressed("Jump") and air_jump_remaining > 0:
                velocity.y = -JUMP_FORCE
                air_jump_remaining-=1
    else: 
        # manage animation for player that aren't ours
        if velocity.x == 0:
            # idle
            anim_sprite_2d.play("idle")
        else:
            # walk
            anim_sprite_2d.play("walk")
        
    if not is_on_floor():
        velocity += get_gravity() * delta
    
    # clamp speed
    velocity = velocity.clamp(Vector2(-MAX_INERTIA_X, -MAX_INERTIA_Y),Vector2(MAX_INERTIA_X, MAX_INERTIA_Y))
    
    move_and_slide()
