class_name BasePlayerAttack
extends Area2D

@onready var player: BasePlayer = get_parent()

func _ready() -> void:
    assert(player != null or player is not BasePlayer, "Must have a player linked")

func _on_body_entered(body: Node2D) -> void:
    var crit_mult = (player.CRIT_MULT) if (randf() <= player.CRIT_RATE) else 1
    if body is GlobalEnemy:
        body.damaged.emit(player, player.ATK * crit_mult, crit_mult != 1)
    if body is BasePlayer and body != player:
        (body as BasePlayer).damaged.emit(player, player.ATK * crit_mult, crit_mult != 1)
    # TODO destroy some projectiles?
    if player == Game.main_player_instance:
        Game.main_player_instance.update_score(ScoreData.Type.DMGD, player.ATK * crit_mult)

func handle_damaged(attacker: Node2D, dmg: int, crit: bool):
    if player.player_disabled:
        return
    
    Game.DmgNumber.display_number(
        dmg, 
        player.dmg_spawn.global_position, 
        DamageNumber.DamageType.DAMAGE,
        crit
    )
    
    if dmg <= 0:
        return
        
    if player == Game.main_player_instance:
        Game.main_player_instance.update_score(ScoreData.Type.DMGR, dmg)
        
    player.anim_sprite_2d.play("hurt")
    player.damaging = true
    player.hp -= dmg
    if player.hp <= 0:
        player.hp = 0
        player.anim_sprite_2d.play("death")
        player.collider.set_deferred("disabled", true)
        player.player_ui.start_counter.emit(player.DEATH_TIME)
        if attacker is BasePlayer:
            attacker.update_score(ScoreData.Type.MKILL, 1)
        
func handle_respawn() -> void:
    if player.hp > 0:
        push_error("trying to respawn " + player.name + " while he's not dead")
        return
        
    if player == Game.main_player_instance:
        Game.main_player_instance.update_score(ScoreData.Type.DEATH, 1)
    
    player.damaging = false
    player.attacking = false
    
    if player.DEBUG:
        player.global_position = Game.current_room.get_node("Spawn").global_position
    else:
        Game.current_room = Game.current_map[player.player_spawn.y][player.player_spawn.x]
        player.global_position = Game.current_room.PlayerSpawn.global_position
        player.change_room(player.player_spawn)
    
    player.collider.set_deferred("disabled", false)
    player.hp = player.HP_MAX
