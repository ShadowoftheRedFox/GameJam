extends MarginContainer

var PlayerScorePanel = preload("res://scenes/UI/InGame/PlayerScore.tscn")

@onready var container: VBoxContainer = $ScrollContainer/MarginContainer/Container

func _ready() -> void:
    Game.player_infos_update.connect(update_score)
    update_score(null)

func update_score(_data: PlayerData) -> void:
    # remove all child except header
    for child in container.get_children():
        if !child.name.contains("Header"):
            child.queue_free()
    
    for p in Game.Players.list:
        if !p.is_spectator:
            var panel = PlayerScorePanel.instantiate()
            panel.player_data = p
            container.add_child(panel)
            container.add_child(HSeparator.new())
