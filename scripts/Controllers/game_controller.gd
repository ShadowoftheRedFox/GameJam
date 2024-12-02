extends Node

func new_game(save_name: String, difficulty: int, map_size: int):
    # TODO create save
    SaveController.create_new_save(save_name, JSON.stringify({
        "difficulty": difficulty,
        "map_size": map_size
    }))
    GeneratorController.generate_map(map_size)
