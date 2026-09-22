## This is used so save manager doesn't care about cloud
## TODO Decouple cloud operations to a CloudSaveSyncService
class_name NullCloudSaveBackend
extends CloudSaveBackend


func is_available() -> bool:
	return true


func upload(_remote_name: String, _local_path: String) -> bool:
	return false


func download(_remote_name: String, _local_path: String) -> bool:
	return false


func delete(_remote_name: String) -> bool:
	return false


func remote_is_newer(_remote_name: String, _local_path: String) -> bool:
	return false
