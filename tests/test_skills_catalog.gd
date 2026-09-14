## Verifies all active skill resources are registered in the SkillCatalogue
extends Node

const SKILL_CATALOGUE: SkillCatalogue = preload("uid://6ygr0ieawafb")


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_test_all_skills_in_catalog()
	_test_catalog_skills_exist_on_disk()
	print("Skills catalog test completed.")
	self.queue_free()


func _test_all_skills_in_catalog() -> void:
	var catalog_defs: Array[SkillDefinition] = SKILL_CATALOGUE.definitions
	var catalog_paths: Array[String] = []
	for def: SkillDefinition in catalog_defs:
		catalog_paths.append(def.resource_path)

	var active_skills_dir: DirAccess = DirAccess.open("res://src/entities/player/skills/active_skills/")
	assert(active_skills_dir != null, "SkillsCatalogTest: active_skills directory missing")

	active_skills_dir.list_dir_begin()
	var file_name: String = active_skills_dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path: String = "res://src/entities/player/skills/active_skills/" + file_name
			assert(path in catalog_paths, "SkillsCatalogTest: '%s' not found in catalogue" % path)
		file_name = active_skills_dir.get_next()
	active_skills_dir.list_dir_end()


func _test_catalog_skills_exist_on_disk() -> void:
	var active_skills_dir: DirAccess = DirAccess.open("res://src/entities/player/skills/active_skills/")
	assert(active_skills_dir != null, "SkillsCatalogTest: active_skills directory missing")

	var catalog_paths: PackedStringArray = _get_catalog_skill_paths()
	var disk_files: PackedStringArray = _list_tres_files(active_skills_dir)

	for catalog_path: String in catalog_paths:
		var file_name: String = catalog_path.get_file()
		assert(file_name in disk_files, "SkillsCatalogTest: catalogue entry '%s' has no corresponding file on disk" % catalog_path)


func _get_catalog_skill_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	for def: SkillDefinition in SKILL_CATALOGUE.definitions:
		paths.append(def.resource_path)
	return paths


func _list_tres_files(dir: DirAccess) -> PackedStringArray:
	var files: PackedStringArray = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return files
