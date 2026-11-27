@tool
class_name ChunkHistoryTree
extends Tree

## Applies scene-defined column settings that Tree exposes through methods

@export var column_titles: PackedStringArray:
	set(value):
		column_titles = value
		if is_node_ready():
			_apply_column_layout()
## Zero lets a column expand into remaining space
@export var fixed_column_widths: PackedInt32Array:
	set(value):
		fixed_column_widths = value
		if is_node_ready():
			_apply_column_layout()


func _ready() -> void:
	_apply_column_layout()


func _apply_column_layout() -> void:
	columns = maxi(1, column_titles.size())
	for column: int in columns:
		var title: String = column_titles[column] if column < column_titles.size() else ""
		var width: int = fixed_column_widths[column] if column < fixed_column_widths.size() else 0
		set_column_title(column, title)
		set_column_expand(column, width == 0)
		set_column_clip_content(column, true)
		set_column_custom_minimum_width(column, width)
