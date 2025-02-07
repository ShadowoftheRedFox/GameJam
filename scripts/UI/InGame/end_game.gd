extends MarginContainer

@onready var winner_label: Label = $MarginContainer/VBoxContainer/Winner

func _ready() -> void:
    Game.game_end.connect(show_winner)

func _on_quit_pressed() -> void:
    Game.stop_game()

func show_winner(id: int) -> void:
    winner_label.text = "Vous avez perdu!" if id != Server.multiplayer.get_unique_id() else "Vous avez gagné!"
