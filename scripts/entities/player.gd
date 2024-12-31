class_name BasePlayer
extends CharacterBody2D

#### STATE MACHINE
enum PlayerState {GROUNDED, AIRBORNE}
var current_state = PlayerState.GROUNDED

#### Schmovements ####

## To make the player move in debug scenes
@export var DEBUG: bool = false
var input_vector: Vector2 = Vector2.ZERO

@export var SPEED_CAP_GROUND: float = 200.0
@export var SPEED_CAP_AIR: float = 300.0

@export var DASH_MULT: float = 8.0
@export var DASH_DURATION: float = 0.2
var dash_direction = 0
var dash_timer: float = 0.0
@export var DASH_COUNT_MAX: int = 1
var dash_count: int = DASH_COUNT_MAX

@export var DRAG_GROUND: float = 0.1
@export var DRAG_AIR: float = 0.1

@export var JUMP_IMPULSE: float = 1000
@export var JUMP_COUNT_MAX: int = 2
var jump_count: int = JUMP_COUNT_MAX

#### Graphic ####
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var anim_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var display_name: Label = $DisplayName
@onready var camera: CameraController = $Camera
@onready var pause: Control = $Camera/CanvasLayer/Pause

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

#### Upgrades ####
var speed_upgrades: int = 0

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
        camera.disable_camera()

func disable_player() -> void:
    if player_disabled:
        return
    if self == GameController.main_player_instance:
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

func _ready():
    dash_count = DASH_COUNT_MAX
    jump_count = JUMP_COUNT_MAX
    
    camera.snap()
    camera.set_limits(GameController.current_room.room.get_node("Map"))
    
    # disable name tag when solo
    if Server.solo_active:
        display_name.hide()

func update_buff(buff_data: Dictionary) -> void:
    # TODO handle buff update
    Server.peer_print(Server.MessageType.PRINT, str(buff_data))
    pass

func _physics_process(delta: float) -> void:
    # Return early if the player is queued for deletion or disabled
    if self.is_queued_for_deletion() or player_disabled:
        return

    # Handle animations
    if velocity.x == 0:
        anim_sprite_2d.play("idle")
    else:
        anim_sprite_2d.play("walk")

    if multiplayer_authority_id == multiplayer.get_unique_id() or Server.solo_active or DEBUG:
        # Handle pause functionality
        if Input.is_action_just_pressed("Pause"):
            GameController.pause()
            return

        # Get player input for movement
        input_vector = Input.get_vector("Left", "Right", "Up", "Down")
        var hor_direction = sign(input_vector.x)

        # Determine the horizontal direction of the velocity
        var vel_direction = sign(velocity.x)

        # State machine handling
        match current_state:
            PlayerState.GROUNDED:
                handle_grounded_state(delta, hor_direction, vel_direction, input_vector)
            PlayerState.AIRBORNE:
                handle_airborne_state(delta, hor_direction, vel_direction, input_vector)

       # Calculate the snap vector for slopes
        @warning_ignore("unused_variable")
        var snap_vector = Vector2(0, 32)  # Adjust the snap length based on your needs

        # Move the player and handle collisions
        set_floor_snap_length(10)
        move_and_slide()

@warning_ignore("shadowed_variable")
func handle_grounded_state(delta, hor_direction, vel_direction, input_vector):
    if is_on_floor() == false:
        change_state(PlayerState.AIRBORNE)
        return

    if dash_timer < DASH_DURATION * 0.7:
        dash_count = DASH_COUNT_MAX

    if Input.is_action_just_pressed("Jump") and jump_count > 0:
        velocity.y = -JUMP_IMPULSE
        dash_timer = -100
        jump_count -= 1
        change_state(PlayerState.AIRBORNE)
        return

    if dash_timer > 0:
        dash_timer -= delta
        velocity = dash_direction * SPEED_CAP_GROUND * DASH_MULT
    else:
        if abs(velocity.x) <= SPEED_CAP_GROUND * 1.3 or hor_direction != vel_direction:
            velocity.x = hor_direction * SPEED_CAP_GROUND
        else:
            var speed_diff = abs(velocity.x) - SPEED_CAP_GROUND
            var drag_force = speed_diff * DRAG_GROUND
            velocity.x -= vel_direction * drag_force

        if Input.is_action_just_pressed("Dash") and sign(input_vector.y) >= 0 and dash_count > 0:
            dash_timer = DASH_DURATION
            dash_direction = input_vector
            dash_count -= 1

        if hor_direction == 1:
            sprite_2d.flip_h = false
            anim_sprite_2d.flip_h = false
        elif hor_direction == -1:
            sprite_2d.flip_h = true
            anim_sprite_2d.flip_h = true

@warning_ignore("shadowed_variable")
func handle_airborne_state(delta, hor_direction, vel_direction, input_vector):
    if is_on_floor():
        change_state(PlayerState.GROUNDED)
        return

    velocity.y += 60.0

    if Input.is_action_just_pressed("Jump") and jump_count > 0:
        velocity.y = -JUMP_IMPULSE
        dash_timer = -100
        jump_count -= 1
        return

    if dash_timer > 0:
        dash_timer -= delta
        velocity = dash_direction * SPEED_CAP_GROUND * DASH_MULT

    else:
        if abs(velocity.x) <= SPEED_CAP_GROUND * 1.3 or hor_direction != vel_direction:
            velocity.x = hor_direction * SPEED_CAP_GROUND
        else:
            var speed_diff = abs(velocity.x) - SPEED_CAP_AIR
            var drag_force = speed_diff * DRAG_AIR
            velocity.x -= vel_direction * drag_force

        if Input.is_action_just_pressed("Dash") and sign(input_vector.y) >= 0 and dash_count > 0:
            dash_timer = DASH_DURATION
            dash_direction = input_vector
            dash_count -= 1

        if hor_direction == 1:
            sprite_2d.flip_h = false
            anim_sprite_2d.flip_h = false
        elif hor_direction == -1:
            sprite_2d.flip_h = true
            anim_sprite_2d.flip_h = true

func change_state(new_state):
    if current_state == new_state:
        return

    # Handle state exit actions
    match current_state:
        PlayerState.GROUNDED:
            on_exit_grounded()
        PlayerState.AIRBORNE:
            on_exit_airborne()

    current_state = new_state

    # Handle state enter actions
    match new_state:
        PlayerState.GROUNDED:
            on_enter_grounded()
        PlayerState.AIRBORNE:
            on_enter_airborne()

func on_enter_grounded():
    # Actions to be executed when entering the grounded state
    dash_count = DASH_COUNT_MAX
    jump_count = JUMP_COUNT_MAX

func on_exit_grounded():
    # Actions to be executed when exiting the grounded state
    pass

func on_enter_airborne():
    # Actions to be executed when entering the airborne state
    pass

func on_exit_airborne():
    # Actions to be executed when exiting the airborne state
    pass
