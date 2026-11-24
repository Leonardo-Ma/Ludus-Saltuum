class_name SteamCloudSaveBackend
extends CloudSaveBackend

## Steam implementation of CloudSaveBackend


func is_available() -> bool:
	return SteamWorks.steam_enabled


func upload(cloud_filename: String, local_path: String) -> bool:
	if not is_available():
		return false
	assert(FileAccess.file_exists(local_path), "Upload source missing in SteamCloudSaveBackend: " + local_path)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(local_path)
	return not bytes.is_empty() and SteamWorks.cloud_file_write(cloud_filename, bytes)


func download(cloud_filename: String, local_path: String) -> bool:
	if not has_remote_save(cloud_filename):
		return false
	var size: int = SteamWorks.cloud_file_size(cloud_filename)
	if size <= 0:
		return false
	var result: Dictionary = SteamWorks.cloud_file_read(cloud_filename, size)
	var bytes: PackedByteArray = result.get("buf", PackedByteArray())
	if not result.get("ret", false) or bytes.size() != size:
		return false
	var file: FileAccess = FileAccess.open(local_path, FileAccess.WRITE)
	if file == null or not file.store_buffer(bytes):
		return false
	file.flush()
	return file.get_error() == OK and file.get_length() == size


func delete(cloud_filename: String) -> bool:
	if not is_available():
		return false
	if not SteamWorks.cloud_file_exists(cloud_filename):
		return true
	return SteamWorks.cloud_file_delete(cloud_filename)


func has_remote_save(cloud_filename: String) -> bool:
	return is_available() and SteamWorks.cloud_file_exists(cloud_filename)
