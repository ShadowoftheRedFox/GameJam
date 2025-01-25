class_name BasePlayerAttack
extends Area2D

@onready var player: BasePlayer = get_parent()

func _ready() -> void:
    assert(player != null or player is not BasePlayer, "Must have a player linked")

func _on_body_entered(body: Node2D) -> void:
    var crit_mult = (player.CRIT_MULT) if (randf() <= player.CRIT_RATE) else 1
    if body is GlobalEnemy:
        body.damaged.emit(player.ATK * crit_mult)
    if body is BasePlayer and body != player and !(body as BasePlayer).player_disabled:
        (body as BasePlayer).damaged.emit(player.ATK * crit_mult)
    # TODO destroy some projectiles?

func handle_damaged(dmg: int):
    if dmg <= 0 or player.player_disabled:
        return
    
    player.anim_sprite_2d.play("hurt")
    player.damaging = true
    player.hp -= dmg
    if player.hp <= 0:
        player.hp = 0
        player.anim_sprite_2d.play("death")
        player.collider.set_deferred("disabled", true)
        player.player_ui.start_counter.emit(player.DEATH_TIME)
        
func handle_respawn() -> void:
    if player.hp > 0:
        push_error("trying to respawn " + player.name + " while he's not dead")
        return
    
    player.hp = player.HP_MAX
    player.damaging = false
    player.collider.set_deferred("disabled", false)
    player.player_room = player.player_spawn
    
    if player.DEBUG:
        player.global_position = GameController.current_room.get_node("Spawn").global_position
    else:
        GameController.current_room = GameController.current_map[player.player_room.y][player.player_room.x]
        player.global_position = GameController.current_room.PlayerSpawn.global_position
