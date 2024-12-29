class_name CameraController
extends Camera2D

func set_limits(tile_map: TileMapLayer) -> void:
    var tile_rect = tile_map.get_used_rect()
    var cell_size = tile_map.tile_set.tile_size
    self.limit_left = tile_rect.position.x * cell_size.x
    self.limit_top = tile_rect.position.y * cell_size.y
    self.limit_right = tile_rect.end.x * cell_size.x
    self.limit_bottom = tile_rect.end.y * cell_size.y

func disable_camera() -> void:
    self.enabled = false

func snap() -> void:
    self.position_smoothing_enabled = false
    
func _physics_process(_delta: float) -> void:
    if !self.position_smoothing_enabled:
        self.position_smoothing_enabled = true
