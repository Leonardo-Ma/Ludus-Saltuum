## Interface for cloud save synchronization backends
@abstract class_name CloudSaveBackend
extends RefCounted

@abstract func is_available() -> bool
@abstract func upload(cloud_filename: String, local_path: String) -> bool
@abstract func download(cloud_filename: String, local_path: String) -> bool
@abstract func delete(cloud_filename: String) -> bool
@abstract func remote_is_newer(cloud_filename: String, local_path: String) -> bool
