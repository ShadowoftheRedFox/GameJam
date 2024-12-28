class_name BasePlayer
extends CharacterBody2D

#### Schmovements ####
var input_vector: Vector2 = Vector2.ZERO

@export var SPEED_CAP_GROUND: float = 200.0
@export var SPEED_CAP_AIR: float = 300.0

@export var DASH_MULT: float = 4.0
@export var DASH_DURATION: float = 0.2
var dash_direction = 0
var dash_timer: float = 0.0

@export var DRAG_GROUND: float = 0.1
@export var DRAG_AIR: float = 0.1


#### Graphic ####
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var display_name: Label = $DisplayName
# TODO bind camera to scene
@onready var camera: Camera2D = $Camera2D

#### Physic ####
@onready var collider: CollisionShape2D = $CollisionShape2D

#### Multiplayer ####
#@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
# the authority controlling this player (peer id)
var multiplayer_authority_id: int = 0
# room where the player is into
# get set since we want to do change when the synchornizer changes it
var skip_next_player_room: bool = false
var player_room: Vector2 = Vector2(0, 0)

# to know if we must render the player
var player_disabled: bool = false

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

func disable_player() -> void:
    if player_disabled:
        return
    if self == GameController.player_node:
        printerr("trying to disable our own player!")
        return
    player_disabled = true
    self.hide()
    collider.set_deferred("disabled", true)

func enable_player() -> void:
    if !player_disabled:
        return
    player_disabled = false
    self.show()
    collider.set_deferred("disabled", false)

func _physics_process(delta: float) -> void:
    # Return early if the player is queued for deletion or disabled
    if self.is_queued_for_deletion() or player_disabled:
        return

    # Handle animations
    # TODO: Make this a more flexible system
    if velocity.x == 0:
        anim_sprite_2d.play("idle")
    else:
        anim_sprite_2d.play("walk")

    # Physics updates go here.
    # Check if this instance has multiplayer authority
    if multiplayer_authority_id == multiplayer.get_unique_id() or Server.solo_active:
        # Handle pause functionality
        if Input.is_action_just_pressed("Pause"):
            GameController.pause()
            return

        # Get player input for movement
        input_vector = Input.get_vector("Left", "Right", "Up", "Down")
        var hor_direction = 0

        if input_vector.x > 0:
            hor_direction = 1
        elif input_vector.x < 0:
            hor_direction = -1
        else:
            hor_direction = 0

        # Determine the horizontal direction of the velocity
        # There HAS to be a better way to do this, so...
        # HACK
        var vel_direction = 0
        if velocity.x != 0:
            vel_direction = velocity.x / abs(velocity.x)

        # Grounded movement
        if is_on_floor():
            if dash_timer > 0:
                dash_timer -= delta
                velocity.x = dash_direction * SPEED_CAP_GROUND * DASH_MULT
            else:
                # First, set vertical velocity to 0
                velocity.y = 0.0

                # If moving above a bit more than the cap, or if holding a direction
                # different from the current movement, set speed to the speed cap.
                # Otherwise, apply exponential slowdown depending on the current speed.
                # Merde.
                if abs(velocity.x) <= SPEED_CAP_GROUND * 1.3 or \
                (hor_direction != vel_direction and hor_direction != 0 and vel_direction != 0):
                    velocity.x = hor_direction * SPEED_CAP_GROUND
                else:
                    var speed_diff = abs(velocity.x) - SPEED_CAP_GROUND
                    var drag_force = speed_diff * DRAG_GROUND
                    velocity.x -= vel_direction * drag_force

                # Handle le ebin dashes
                if Input.is_action_just_pressed("Dash") and hor_direction != 0:
                    dash_timer = DASH_DURATION
                    dash_direction = hor_direction

                # Flip the sprite based on movement direction
                if hor_direction == 1:
                    sprite_2d.flip_h = false
                    anim_sprite_2d.flip_h = false
                elif hor_direction == -1:
                    sprite_2d.flip_h = true
                    anim_sprite_2d.flip_h = true

        # Air movement
        else:
            # Apply gravity
            velocity.y = 100.0

        # Move the player and handle collisions
        move_and_slide()
