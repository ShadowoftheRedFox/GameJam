class_name GlobalDamaged
extends State

func enter(_previous_state_path: String, data := {"damages": 0}) -> void:
    var damages = data.get_or_add("damages", 0)
    if damages <= 0:
        finished.emit("Idle")
        return
    
    entity.hp -= damages
    
    if entity.hp <= 0:
        finished.emit("Death")
        return

    entity.animate.emit("hurt")
    entity.info = "Handling damages"

func physics_update(_delta: float) -> void:
    if entity.animation_sprite and !entity.animation_sprite.is_playing():
        finished.emit("Idle")
    if entity.animation_player and !entity.animation_player.is_playing():
        finished.emit("Idle")
