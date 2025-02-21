class_name DifficultyConfig

var hp_mult: float = 1.0:
    get:
        match Game.hosted_difficulty:
            Game.Difficulties.Easy: 
                return 0.5
            Game.Difficulties.Medium: 
                return 1.0
            Game.Difficulties.Hard: 
                return 2.0
            Game.Difficulties.Impossible: 
                return 3.0
            _:
                return 1.0

var atk_mult: float = 1.0:
    get:
        match Game.hosted_difficulty:
            Game.Difficulties.Easy: 
                return 0.5
            Game.Difficulties.Medium: 
                return 1.0
            Game.Difficulties.Hard: 
                return 2.0
            Game.Difficulties.Impossible: 
                return 3.0
            _:
                return 1.0

var crit_rate_mult: float = 1.0:
    get:
        match Game.hosted_difficulty:
            Game.Difficulties.Easy: 
                return 0.5
            Game.Difficulties.Medium: 
                return 1.0
            Game.Difficulties.Hard: 
                return 2.0
            Game.Difficulties.Impossible: 
                return 3.0
            _:
                return 1.0

var crit_damage_mult: float = 1.0:
    get:
        match Game.hosted_difficulty:
            Game.Difficulties.Easy: 
                return 0.5
            Game.Difficulties.Medium: 
                return 1.0
            Game.Difficulties.Hard: 
                return 2.0
            Game.Difficulties.Impossible: 
                return 3.0
            _:
                return 1.0
