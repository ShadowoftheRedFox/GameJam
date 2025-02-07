class_name GlobalDeath
extends State

func enter(_previous_state_path: String, data := {"killer": null}) -> void:
    entity.animate.emit("death")
    entity.info = "Dead"
    
    entity.ondeath.emit(data.get("killer", null))
    
    if data.get("killer", null) == Game.main_player_instance:
        if entity.is_boss:
            Game.main_player_instance.update_score(ScoreData.Type.BKILL, 1)
        elif entity.is_mini_boss:
            Game.main_player_instance.update_score(ScoreData.Type.MBKILL, 1)
        else:
            Game.main_player_instance.update_score(ScoreData.Type.MKILL, 1)
        
    if entity.body_collider:
        entity.body_collider.set_deferred("disabled", true)

func physics_update(delta: float) -> void:
    if is_queued_for_deletion():
        return

    entity.disappearance_timer -= delta
    
    if entity.disappear_on_death and entity.disappearance_timer <= 0:
        entity.queue_free()
