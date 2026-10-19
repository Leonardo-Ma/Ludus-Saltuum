## Steam implementation of CloudSaveBackend
class_name SteamCloudSaveBackend
extends CloudSaveBackend


func is_available() -> bool:
	return SteamWorks.steam_enabled


func upload(cloud_filename: String, local_path: String) -> bool:
	if not is_available():
		return false
	assert(FileAccess.file_exists(local_path), "SteamCloudSaveBackend: local file missing " + local_path)
	return SteamWorks.cloud_file_write(cloud_filename, FileAccess.get_file_as_bytes(local_path))


func download(cloud_filename: String, local_path: String) -> bool:
	if not is_available() or not SteamWorks.cloud_file_exists(cloud_filename):
		push_warning("Steam cloud download failed")
		return false
	var size: int = SteamWorks.cloud_file_size(cloud_filename)
	var result: Dictionary = SteamWorks.cloud_file_read(cloud_filename, size)
	if not result.get("ret", false):
		push_warning("Steam cloud download failed")
		return false
	var file: FileAccess = FileAccess.open(local_path, FileAccess.WRITE)
	assert(file != null, "SteamCloudSaveBackend: cannot open local file for write " + local_path)
	file.store_buffer(result.get("buf", PackedByteArray()))
	file.close()
	return true


func delete(cloud_filename: String) -> bool:
	if not is_available():
		return false
	if not SteamWorks.cloud_file_exists(cloud_filename):
		return true
	return SteamWorks.cloud_file_delete(cloud_filename)


func remote_is_newer(cloud_filename: String, local_path: String) -> bool:
	if not is_available() or not SteamWorks.cloud_file_exists(cloud_filename):
		return false
	if not FileAccess.file_exists(local_path):
		return true
	return SteamWorks.cloud_file_timestamp(cloud_filename) > FileAccess.get_modified_time(local_path)
