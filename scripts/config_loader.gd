class_name ConfigLoader extends Node

var _config_file : ConfigFile:
	get():
		if ! _config_file:
			_load_config()
		return _config_file

var console_signal_bus : ConsoleSignalBus

const DEFAULT_CONFIG_PATH := "res://config.cfg"
const CONFIG_PATH := "user://config.cfg"


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]


func _load_config() -> void:
	console_signal_bus.add_line("Loading config")
	
	# Copy default config to user:// if it doesn't exist yet
	#if ! FileAccess.file_exists(CONFIG_PATH):
	console_signal_bus.add_line("Copying config to " + OS.get_user_data_dir() + "/config.cfg")
	DirAccess.copy_absolute(DEFAULT_CONFIG_PATH, CONFIG_PATH)
	
	_config_file = ConfigFile.new()
	var err = _config_file.load(CONFIG_PATH)
	
	if err != OK:
		console_signal_bus.add_error("Failed to parse config file, error code: %d" % err)
		return
	
	console_signal_bus.add_line("Config loaded")


func get_paths() -> Array[Dictionary]:
	var paths : Array[Dictionary]
	
	for section in _config_file.get_sections():
		if section.begins_with("path"):
			paths.append({
				"section": section,
				"name": _config_file.get_value(section, "name"),
				"path": _config_file.get_value(section, "path")
			})
	
	return paths


func get_servers() -> Array[Dictionary]:
	var servers : Array[Dictionary]
	
	for section in _config_file.get_sections():
		if section.begins_with("server"):
			servers.append({
				"section": section,
				"name": _config_file.get_value(section, "name"),
				"ip": _config_file.get_value(section, "ip"),
				"user": _config_file.get_value(section, "user"),
				"ssh_key_path": _config_file.get_value(section, "ssh_key_path", "~/.ssh/id_rsa"),
				"is_default": _config_file.get_value(section, "is_default", false),
			})
	
	return servers


func get_empty_server() -> Dictionary:
	return {
		"section": "",
		"name": "",
		"ip": "",
		"user": "",
		"ssh_key_path": "",
		"is_default": false,
	}


func get_channels() -> Array[Dictionary]:
	var channels : Array[Dictionary]
	
	for section in _config_file.get_sections():
		if section.begins_with("channel"):
			channels.append({
				"section": section,
				"name" : _config_file.get_value(section, "name"),
				"start_collapsed" : _config_file.get_value(section, "start_collapsed", false),
			})
	
	return channels


func get_playlists() -> Array[Dictionary]:
	var playlists : Array[Dictionary]
	
	for section in _config_file.get_sections():
		if section.begins_with("playlist"):
			playlists.append({
				"section": section,
				"channel": _config_file.get_value(section, "channel"),
				"name": _config_file.get_value(section, "name"),
				"url": _config_file.get_value(section, "url"),
				"download_path": _config_file.get_value(section, "download_path"),
				"backup_upload_path": _config_file.get_value(section, "backup_upload_path"),
				"remote_upload_path": _config_file.get_value(section, "remote_upload_path"),
				"download_archive_file_name": _config_file.get_value(section, "download_archive_file_name"),
				"cookies_from_browser": _config_file.get_value(section, "cookies_from_browser", "firefox"),
				"delete_download" : _config_file.get_value(section, "delete_download", true),
				"preview_unarchived_on_startup" : _config_file.get_value(section, "preview_unarchived_on_startup", false)
			})
	
	return playlists


func save_changes(changes : Dictionary) -> void:
	console_signal_bus.add_line("Saving config changes")
	
	for config_path in changes.paths:
		for key in config_path.keys():
			if key == "section":
				continue
			
			var value = config_path[key]
			_config_file.set_value(config_path.section, key, value)
	
	# TODO Save servers and credentials
	
	for config_channel in changes.channels:
		for key in config_channel.keys():
			if key == "section":
				continue
			
			var value = config_channel[key]
			_config_file.set_value(config_channel.section, key, value)
	
	for config_playlist in changes.playlists:
		for key in config_playlist.keys():
			if key == "section":
				continue
			
			var value = config_playlist[key]
			_config_file.set_value(config_playlist.section, key, value)
	
	_config_file.save(CONFIG_PATH)
	
	console_signal_bus.add_line("Config changes saved")
	
	_load_config()
