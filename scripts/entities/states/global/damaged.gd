class_name GlobalDamaged
extends State

func enter(_previous_state_path: String, data := {"damages": 0, "crit": false, "attacker": null}) -> void:
    var damages: int = data.get_or_add("damages", 0)
    var crit: bool = data.get_or_add("crit", false)
    var attacker: Node2D = data.get("attacker", null)
    
    Game.DmgNumber.display_number(
        damages, 
        entity.dmg_spawn.global_position, 
        DamageNumber.DamageType.DAMAGE,
        crit
    )
    
    if damages <= 0:
        finished.emit("Idle")
        return
    
    entity.hp -= damages
    
    if entity.hp <= 0:
        finished.emit("Death", {"killer": attacker})
        return

    entity.animate.emit("hurt")
    entity.info = "Handling damages"

func physics_update(_delta: float) -> void:
    if (entity.animation_sprite and !entity.animation_sprite.is_playing()) or \
       (entity.animation_player and !entity.animation_player.is_playing()):
        finished.emit("Idle")
    entity.move_and_slide()
