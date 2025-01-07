class_name PlayerScoreMenu
extends Control

var player_data: PlayerData = PlayerData.new():
    set(value):
        player_data = value
        if is_node_ready():
            update()

func _ready() -> void:
    MultiplayerController.player_infos_update.connect(infos_update)
    update()
    
func infos_update(data: PlayerData) -> void:
    if data != null and data.id == player_data.id:
        player_data = data 

func update() -> void:
    $Main/Name.text = player_data.name
    $Main/Score.text = "Score : " + str(player_data.score.global)
