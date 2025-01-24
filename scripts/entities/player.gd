class_name BasePlayer
extends CharacterBody2D

#### STATE MACHINE
enum PlayerState {GROUNDED, AIRBORNE}
var current_state = PlayerState.GROUNDED

#### Schmovements ####

## To make the player move in debug scenes
@export var DEBUG: bool = false
var input_vector: Vector2 = Vector2.ZERO

@export_category("Schmovements")
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

#### Interractions ####
@export_category("Stats")
@export var HP_MAX: int = 100
var hp: int = HP_MAX

@export var atk: int = 3
@export_range(0, 1) var CRIT_RATE: float = 0.1

@onready var attack_box: Area2D = $AttackBox
@onready var attack_box_collider: CollisionShape2D = $AttackBox/CollisionShape2D


# FIXME handle with a state
var attacking = false
var damaging = false


signal damaged(dmg: int)

#### Multiplayer ####
#@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
# the authority controlling this player (peer id)
var multiplayer_authority_id: int = 0
# room where the player is into
var player_room: Vector2 = Vector2(0, 0)

# to know if we must render the player
var player_disabled: bool = false

var buffs: Dictionary = {}

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

func disable_player(disabling: bool) -> void:
    if self == GameController.main_player_instance:
        printerr("trying to disable our own player!")
        return
        
    #Server.peer_print(Server.MessageType.PRINT ,("disabling " if disabling else "enabling ") + name)
    # FIXME doesn't show when it should (after instance changed room then goes back in)
    visible = disabling
    collider.set_deferred("disabled", disabling)
    player_disabled = disabling

func _ready():
    dash_count = DASH_COUNT_MAX
    jump_count = JUMP_COUNT_MAX
    
    camera.snap()
    
    # disable name tag when solo
    if Server.solo_active:
        display_name.hide()
    
    # connect signals
    damaged.connect(handle_damaged_state)
    
    if DEBUG:
        # handle debug mode of this player instance
        # try to setup camera limits
        if get_parent() != null and get_parent().has_node("Map"):
            camera.set_limits(get_parent().get_node("Map"))
            # add room (so parent) as current_room
            # must have the room script attached
            GameController.current_room = get_parent()
        else:
            push_warning("Couldn't find map, make sure the map is a brother of this node, and that the node called Map is a TileMapLayer")
        # makes himself the main instance
        GameController.main_player_instance = self
        Server.solo_active = true
        # add himself to the player list
        var data = PlayerData.new()
        data.id = 0
        name = str(data.id)
        data.name = "DebugPlayer"
        GameController.Players.list.append(data)
        reparent.call_deferred(get_tree().root, true)
        display_name.text = str(hp)
        display_name.show()
    else:
        camera.set_limits(GameController.current_room.room.get_node("Map"))

func update_buff(data: PlayerData) -> void:
    # TODO handle buff update
    Server.peer_print(Server.MessageType.PRINT, str(data))
    if data.has_buff(Buff.BuffPreset.JUMP_UPGRADER):
        JUMP_COUNT_MAX = 2 + data.get_buff(Buff.BuffPreset.JUMP_UPGRADER).buff_amount 
    if data.has_buff(Buff.BuffPreset.DASH_UPGRADER):
        DASH_COUNT_MAX = 1 + data.get_buff(Buff.BuffPreset.DASH_UPGRADER).buff_amount

func _physics_process(delta: float) -> void:
    # Return early if the player is queued for deletion or disabled
    if is_queued_for_deletion() or player_disabled:
        return

    # Handle animations
    if !anim_sprite_2d.is_playing() or (!attacking and !damaging):
        attacking = false
        damaging = false
        if velocity.x == 0:
            anim_sprite_2d.play("idle")
        else:
            anim_sprite_2d.play("walk")

    if multiplayer_authority_id == multiplayer.get_unique_id() or Server.solo_active or DEBUG:
        # Handle pause functionality
        if Input.is_action_just_pressed("Pause"):
            GameController.pause()
            return
            
        if Input.is_action_just_pressed("SmallAttack"):
            anim_sprite_2d.play("attack1")
            attacking = true

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
        
        # attack
        # FIXME if outside "if attacking", is spamming left right, hit box goes left right (so hitting multiple times?)
        if !anim_sprite_2d.flip_h:
            attack_box.rotation = deg_to_rad(0.0)
        else:
            attack_box.rotation = deg_to_rad(180.0)
        if attacking and attack_box_collider.disabled:
            attack_box_collider.set_deferred("disabled", false)
        elif !attacking and !attack_box_collider.disabled:
            attack_box_collider.set_deferred("disabled", true)

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
        
        if hor_direction == 1 and anim_sprite_2d.flip_h:
            sprite_2d.flip_h = false
            anim_sprite_2d.flip_h = false
        elif hor_direction == -1 and !anim_sprite_2d.flip_h:
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

        if hor_direction == 1 and anim_sprite_2d.flip_h:
            sprite_2d.flip_h = false
            anim_sprite_2d.flip_h = false
        elif hor_direction == -1 and !anim_sprite_2d.flip_h:
            sprite_2d.flip_h = true
            anim_sprite_2d.flip_h = true

func handle_damaged_state(dmg: int):
    if dmg <= 0:
        return
    anim_sprite_2d.play("hurt")
    damaging = true
    hp -= dmg
    display_name.text = str(hp)
    if hp <= 0:
        # TODO death
        pass

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

func _on_attack_box_body_entered(body: Node2D) -> void:
    if body is GlobalEnemy:
        body.damaged.emit(atk)
    if body is BasePlayer and body != self:
        (body as BasePlayer).damaged.emit(atk)
    # TODO destroy some projectiles?
