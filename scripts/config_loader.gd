class_name ConfigLoader

static var loaded := false
static var config_path := "user://config.cfg"
static var default_config_path := "res://config.cfg"
static var config : Dictionary:
	get():
		if ! loaded:
			_load_config()
		return config


static func _load_config() -> void:
	loaded = true
	
	config = {
		"paths": [],
		"channels": [],
		"playlists": []
	}
	
	# Copy default config to user:// if it doesn't exist yet
	#if ! FileAccess.file_exists(config_path):
	DirAccess.copy_absolute(default_config_path, config_path)
	
	var config_file = ConfigFile.new()
	var err = config_file.load(config_path)
	# TODO Should print this to the console
	print(OS.get_user_data_dir())
	
	if err != OK:
		# TODO Print an error message or something
		push_error("Failed to parse config file, error code: %d" % err)
		return
	
	# FIXME Still getting some weird parse errors
	for section in config_file.get_sections():
		if section.begins_with("path"):
			config["paths"].append({
				"name": config_file.get_value(section, "name"),
				"path": config_file.get_value(section, "path")
			})
		elif section.begins_with("channel"):
			config["channels"].append(config_file.get_value(section, "name"))
		elif section.begins_with("playlist"):
			config["playlists"].append({
				"channel": config_file.get_value(section, "channel"),
				"name": config_file.get_value(section, "name"),
				"url": config_file.get_value(section, "url"),
				"download_path": config_file.get_value(section, "download_path"),
				"backup_upload_path": config_file.get_value(section, "backup_upload_path"),
				"remote_upload_path": config_file.get_value(section, "remote_upload_path"),
				"download_archive_file_path": config_file.get_value(section, "download_archive_file_path")
			})
