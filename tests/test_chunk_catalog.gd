## Verifies all level chunk scenes in base_levels/ and skills/ are registered in the ChunkCatalog
extends Node

const CHUNK_CATALOG: ChunkCatalog = preload("uid://dwe2glcvgdfgs")


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_test_all_scenes_in_catalog()
	_test_catalog_scenes_exist_on_disk()
	print("Chunk catalog test completed.")
	self.queue_free()


func _test_all_scenes_in_catalog() -> void:
	var catalog_paths: Array[String] = []
	for chunk: PackedScene in CHUNK_CATALOG.chunks:
		catalog_paths.append(chunk.resource_path)

	var base_levels_dir: DirAccess = DirAccess.open("res://src/environment/levels/base_levels/")
	assert(base_levels_dir != null, "ChunkCatalogTest: base_levels directory missing")
	_check_directory_scenes(base_levels_dir, catalog_paths, "base_levels")

	var skills_dir: DirAccess = DirAccess.open("res://src/environment/levels/skills/")
	assert(skills_dir != null, "ChunkCatalogTest: skills directory missing")
	_check_directory_scenes(skills_dir, catalog_paths, "skills")


func _check_directory_scenes(dir: DirAccess, catalog_paths: Array[String], dir_name: String) -> void:
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			var path: String = "res://src/environment/levels/" + dir_name + "/" + file_name
			assert(path in catalog_paths, "ChunkCatalogTest: '%s' not found in catalog" % path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _test_catalog_scenes_exist_on_disk() -> void:
	var base_levels_dir: DirAccess = DirAccess.open("res://src/environment/levels/base_levels/")
	assert(base_levels_dir != null, "ChunkCatalogTest: base_levels directory missing")
	var catalog_paths: PackedStringArray = _get_catalog_scene_paths()

	var base_levels_files: PackedStringArray = _list_tscn_files(base_levels_dir)
	for catalog_path: String in catalog_paths:
		var file_name: String = catalog_path.get_file()
		assert(
			file_name in base_levels_files or file_name in _list_tscn_files(DirAccess.open("res://src/environment/levels/skills/")),
			"ChunkCatalogTest: catalog entry '%s' has no corresponding file on disk" % catalog_path,
		)


func _get_catalog_scene_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	for chunk: PackedScene in CHUNK_CATALOG.chunks:
		paths.append(chunk.resource_path)
	return paths


func _list_tscn_files(dir: DirAccess) -> PackedStringArray:
	var files: PackedStringArray = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return files
