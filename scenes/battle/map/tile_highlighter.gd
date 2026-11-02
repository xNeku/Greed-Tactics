class_name TileHighlighter
extends Node3D
## Coloured overlays on top of cells (GDD §11): blue = movement, yellow/orange
## = targets and area, green = hovered cell. Each layer is a child
## MultiMeshInstance3D with its own material, so colours are tuned in the scene.

enum Layer { MOVE, PATH, TARGET, AREA, CURSOR }

## Height above the surface, to avoid z-fighting with the terrain.
const SURFACE_OFFSET := 0.02

@onready var _layers: Dictionary[Layer, MultiMeshInstance3D] = {
	Layer.MOVE: $Move,
	Layer.PATH: $Path,
	Layer.TARGET: $Target,
	Layer.AREA: $Area,
	Layer.CURSOR: $Cursor,
}

var _map: BattleMapView


func setup(map_view: BattleMapView) -> void:
	_map = map_view


func show_cells(layer: Layer, cells: Array[Vector2i]) -> void:
	var multimesh := _layers[layer].multimesh
	multimesh.instance_count = cells.size()
	for i in cells.size():
		var world_pos := _map.cell_to_world(cells[i]) + Vector3.UP * (SURFACE_OFFSET + layer * 0.002)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, to_local(world_pos)))


func show_cell(layer: Layer, cell: Vector2i) -> void:
	if cell == BattleMapView.INVALID_CELL:
		clear(layer)
	else:
		show_cells(layer, [cell])


func clear(layer: Layer) -> void:
	_layers[layer].multimesh.instance_count = 0


func clear_all() -> void:
	for layer in _layers:
		clear(layer)
