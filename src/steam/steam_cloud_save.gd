## Syncs save slot files to Steam Cloud when Steam is running and cloud is enabled
extends Node


func is_available() -> bool:
	if !Steam.isSteamRunning():
		return false
	return Steam.isCloudEnabledForApp() and Steam.isCloudEnabledForAccount()


func upload(cloud_filename: String, local_path: String) -> bool:
	if not is_available():
		return false
	assert(FileAccess.file_exists(local_path), "SteamCloudSave: local file missing " + local_path)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(local_path)
	return Steam.fileWrite(cloud_filename, bytes)


func download(cloud_filename: String, local_path: String) -> bool:
	if not is_available() or not Steam.fileExists(cloud_filename):
		return false
	var size: int = Steam.getFileSize(cloud_filename)
	var result: Dictionary = Steam.fileRead(cloud_filename, size)
	if not result.get("ret", false):
		return false
	var file: FileAccess = FileAccess.open(local_path, FileAccess.WRITE)
	assert(file != null, "SteamCloudSave: cannot open local file for write " + local_path)
	file.store_buffer(result.get("buf", PackedByteArray()))
	file.close()
	return true


func remote_is_newer(cloud_filename: String, local_path: String) -> bool:
	if not is_available() or not Steam.fileExists(cloud_filename):
		return false
	if not FileAccess.file_exists(local_path):
		return true
	return Steam.getFileTimestamp(cloud_filename) > FileAccess.get_modified_time(local_path)
