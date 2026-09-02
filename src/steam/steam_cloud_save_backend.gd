## Steam implementation of CloudSaveBackend
class_name SteamCloudSaveBackend
extends CloudSaveBackend


func is_available() -> bool:
	if !Steam.isSteamRunning():
		return false
	return Steam.isCloudEnabledForApp() and Steam.isCloudEnabledForAccount()


func upload(cloud_filename: String, local_path: String) -> bool:
	if not is_available():
		return false
	assert(FileAccess.file_exists(local_path), "SteamCloudSaveBackend: local file missing " + local_path)
	return Steam.fileWrite(cloud_filename, FileAccess.get_file_as_bytes(local_path))


func download(cloud_filename: String, local_path: String) -> bool:
	if not is_available() or not Steam.fileExists(cloud_filename):
		push_warning("Steam cloud download failed")
		return false
	var size: int = Steam.getFileSize(cloud_filename)
	var result: Dictionary = Steam.fileRead(cloud_filename, size)
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
	if not Steam.fileExists(cloud_filename):
		return true
	return Steam.fileDelete(cloud_filename)


func remote_is_newer(cloud_filename: String, local_path: String) -> bool:
	if not is_available() or not Steam.fileExists(cloud_filename):
		return false
	if not FileAccess.file_exists(local_path):
		return true
	return Steam.getFileTimestamp(cloud_filename) > FileAccess.get_modified_time(local_path)
