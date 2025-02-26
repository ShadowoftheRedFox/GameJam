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
@onready var player_ui: PlayerUI = $Camera/CanvasLayer/Ui
@onready var dmg_spawn: Marker2D = $DmgSpawn

#### Physic ####
@onready var collider: CollisionShape2D = $CollisionShape2D

#### Interractions ####
@export_category("Stats")
@export var HP_MAX: int = 20
## exported for the player sync
@export var hp: int = HP_MAX:
    set(value):
        hp = value
        if is_node_ready() and player_ui:
            player_ui.hp = "HP : " + str(int(hp))

@export var ATK: int = 3
@export_range(0, 1) var CRIT_RATE: float = 0.1
@export var CRIT_MULT: int = 2

@onready var attack_box: Area2D = $AttackBox
@onready var attack_box_collider: CollisionShape2D = $AttackBox/CollisionShape2D

## in seconds
var DEATH_TIME: int = 5

# FIXME handle with a state
var attacking = false
var damaging = false

@onready var damage_handler: BasePlayerAttack = $AttackBox

signal damaged(attacker: Node2D, dmg: int, crit: bool)
signal respawn()
signal room_changed()

#### Multiplayer ####
# the authority controlling this player (peer id)
var multiplayer_authority_id: int = 0
# room where the player is into
var player_spawn: Vector2i = Vector2i()
var player_room: Vector2i = Vector2i():
    set(value):
        player_room = value
        room_changed.emit()

# to know if we must render the player
var player_disabled: bool = false

var buffs: Dictionary = {}

#### Upgrades ####
var speed_upgrades: int = 0

func set_player_name(player_name: String) -> void:
    $DisplayName.text = player_name

func set_authority(id: int) -> void:
    $MultiplayerSynchronizer.set_multiplayer_authority(id, true)
    multiplayer_authority_id = id

func disable_others_camera(id: int) -> void:
    # disable camera of player instance if it's not our player
    # and delete all ui elements
    if id != multiplayer.get_unique_id():
        camera.disable_camera()
        camera.get_node("CanvasLayer").queue_free()
        player_ui = null

func change_room(room: Vector2) -> void:
    var old_room: Vector2i = player_room
    player_room = room
    # snap camera
    camera.snap()
    camera.set_limits(Game.current_room.Map)
    if player_ui:
        player_ui.pos = str(room)
    
    # enable/disable entities in old room if no one there
    var found = false
    for player: BasePlayer in Game.PlayerNodes.get_children():
        if player.player_room == old_room:
            found = true
            break

    if !found:
        Game.current_map[old_room.y][old_room.x].disable_entities()

    # enable entities in current room
    Game.current_map[player_room.y][player_room.x].enable_entities()


func update_score(type: ScoreData.Type, value: int) -> void:
    Game.Players.get_player(multiplayer_authority_id).score.update_score(multiplayer_authority_id, type, value)

func _ready():
    camera.snap()
    
    # disable namwe tag when solo
    if Server.solo_active:
        display_name.hide()
    
    # connect signals
    damaged.connect(damage_handler.handle_damaged)
    respawn.connect(damage_handler.handle_respawn)
    
    if DEBUG:
        # handle debug mode of this player instance
        # try to setup camera limits
        if get_parent() != null and get_parent().has_node("Map"):
            camera.set_limits(get_parent().get_node("Map"))
            # add room (so parent) as current_room
            # must have the room script attached
            Game.current_room = get_parent()
        else:
            push_warning("Couldn't find map, make sure the map is a brother of this node, and that the node called Map is a TileMapLayer")
        # makes himself the main instance
        Game.main_player_instance = self
        Server.solo_active = true
        # add himself to the player list
        var data = PlayerData.new()
        data.id = 0
        name = str(data.id)
        data.name = "DebugPlayer"
        Game.Players.list.append(data)
        reparent.call_deferred(Game.PlayerNodes, true)
    else:
        camera.set_limits(Game.current_room.Map)
        
    hp = HP_MAX

func update_buff(data: PlayerData) -> void:
#region Buff update
    #Server.peer_print(Server.MessageType.PRINT, str(data))
    if data.has_buff(Buff.JUMP_UPGRADER):
        JUMP_COUNT_MAX = 2 + data.get_buff(Buff.JUMP_UPGRADER).buff_amount
        
    if data.has_buff(Buff.DASH_UPGRADER):
        DASH_COUNT_MAX = 1 + data.get_buff(Buff.DASH_UPGRADER).buff_amount
        
    if data.has_buff(Buff.SPEED_UPGRADER):
        SPEED_CAP_GROUND = 200 * (1 + 0.2 * data.get_buff(Buff.SPEED_UPGRADER).buff_amount) # * 1.2
        SPEED_CAP_AIR = 300 * (1 + 0.2 * data.get_buff(Buff.SPEED_UPGRADER).buff_amount)
    if data.has_buff(Buff.SPEED_BOOSTER):
        SPEED_CAP_GROUND = 200 * (1 + 0.2 * data.get_buff(Buff.SPEED_BOOSTER).buff_amount)
        SPEED_CAP_AIR = 300 * (1 + 0.2 * data.get_buff(Buff.SPEED_BOOSTER).buff_amount)
    
    var old_hp_ratio: float = float(hp) / float(HP_MAX)
    if data.has_buff(Buff.HEALTH_UPGRADER):
        HP_MAX = int(20.0 * (1.0 + 0.2 * data.get_buff(Buff.HEALTH_UPGRADER).buff_amount)) # * 1.2 each
        hp = int(old_hp_ratio * HP_MAX)
    if data.has_buff(Buff.HEALTH_BOOSTER):
        HP_MAX = int(HP_MAX + 5.0 * data.get_buff(Buff.HEALTH_BOOSTER).buff_amount)
        hp = int(old_hp_ratio * HP_MAX)
#endregion

@rpc("any_peer", "call_remote")
func propagate_attack(id: int) -> void:
    if multiplayer_authority_id == id:
        attacking = true
        anim_sprite_2d.play("attack1")

func _physics_process(delta: float) -> void:
    # Return early if the player is queued for deletion or disabled
    if is_queued_for_deletion() or hp <= 0 or player_disabled:
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
        if Input.is_action_just_pressed("Pause") and !Game.game_ended:
            Game.pause()
            return
            
        if Input.is_action_just_pressed("SmallAttack"):
            anim_sprite_2d.play("attack1")
            attacking = true
            propagate_attack.rpc(multiplayer_authority_id)

        # Get player input for movement
        input_vector = Input.get_vector("Left", "Right", "Up", "Down")
        var hor_direction = sign(input_vector.x)

        # Determine the horizontal direction of the velocity
        var vel_direction = sign(velocity.x)
        update_score(ScoreData.Type.DIST, int(input_vector.distance_squared_to(Vector2.ZERO)))

        # State machine handling
        match current_state:
            PlayerState.GROUNDED:
                handle_grounded_state(delta, hor_direction, vel_direction, input_vector)
            PlayerState.AIRBORNE:
                handle_airborne_state(delta, hor_direction, vel_direction, input_vector)

        # Calculate the snap vector for slopes
        @warning_ignore("unused_variable")
        var snap_vector = Vector2(0, 32) # Adjust the snap length based on your needs
        

        # Move the player and handle collisions
        move_and_slide()
    
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
        update_score(ScoreData.Type.JMP, 1)
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
            update_score(ScoreData.Type.DASH, 1)
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
        update_score(ScoreData.Type.JMP, 1)
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
            update_score(ScoreData.Type.DASH, 1)

        if hor_direction == 1 and anim_sprite_2d.flip_h:
            sprite_2d.flip_h = false
            anim_sprite_2d.flip_h = false
        elif hor_direction == -1 and !anim_sprite_2d.flip_h:
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
