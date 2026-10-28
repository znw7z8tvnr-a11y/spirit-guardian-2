extends RefCounted
const PATH := "user://sg_m2_build.json"
func save_build(data: Dictionary) -> bool:
 var file := FileAccess.open(PATH+".tmp", FileAccess.WRITE)
 if file==null:return false
 file.store_string(JSON.stringify(data))
 file.flush()
 file.close()
 return DirAccess.rename_absolute(PATH+".tmp",PATH)==OK
func load_build() -> Variant:
 if not FileAccess.file_exists(PATH):return null
 if FileAccess.get_file_as_string(PATH).length()>350000:return null
 return JSON.parse_string(FileAccess.get_file_as_string(PATH))
