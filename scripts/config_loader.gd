class_name ConfigLoader extends Node

var _config_file : ConfigFile:
	get():
		if ! _config_file:
			_load_config()
		return _config_file

var console_signal_bus : ConsoleSignalBus

var paths : Array[Dictionary]
var servers : Array[Dictionary]
var channels : Array[Dictionary]
var playlists : Array[Dictionary]
var paths_loaded := false
var servers_loaded := false
var channels_loaded := false
var playlists_loaded := false

const DEFAULT_CONFIG_PATH := "res://config.cfg"
const CONFIG_PATH := "user://config.cfg"


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]


func _load_config() -> void:
	paths = []
	servers = []
	channels = []
	playlists = []
	paths_loaded = false
	servers_loaded = false
	channels_loaded = false
	playlists_loaded = false
	
	console_signal_bus.add_line("Loading config")
	
	# Copy default config to user:// if it doesn't exist yet
	if ! FileAccess.file_exists(CONFIG_PATH):
		console_signal_bus.add_line("Copying config to " + OS.get_user_data_dir() + "/config.cfg")
		DirAccess.copy_absolute(DEFAULT_CONFIG_PATH, CONFIG_PATH)
	
	_config_file = ConfigFile.new()
	var err = _config_file.load(CONFIG_PATH)
	
	if err != OK:
		console_signal_bus.add_error("Failed to parse config file, error code: %d" % err)
		return
	
	console_signal_bus.add_line("Config loaded")


func get_paths() -> Array[Dictionary]:
	if ! paths_loaded:
		for section in _config_file.get_sections():
			if section.begins_with("path"):
				paths.append({
					"id": Util.get_uid(),
					"section": section,
					"name": _config_file.get_value(section, "name"),
					"path": _config_file.get_value(section, "path")
				})
		paths_loaded = true
	
	return paths


func get_empty_path() -> Dictionary:
	return {
		"id": Util.get_uid(),
		"section": "",
		"name": "",
		"path": "",
	}


func get_servers() -> Array[Dictionary]:
	if ! servers_loaded:
		for section in _config_file.get_sections():
			if section.begins_with("server"):
				servers.append({
					"id": Util.get_uid(),
					"section": section,
					"name": _config_file.get_value(section, "name"),
					"ip": _config_file.get_value(section, "ip"),
					"user": _config_file.get_value(section, "user"),
					"ssh_key_path": _config_file.get_value(section, "ssh_key_path", "~/.ssh/id_rsa"),
					"is_default": _config_file.get_value(section, "is_default", false),
				})
		servers_loaded = true
	
	return servers


func get_empty_server() -> Dictionary:
	return {
		"id": Util.get_uid(),
		"section": "",
		"name": "",
		"ip": "",
		"user": "",
		"ssh_key_path": "",
		"is_default": false,
	}


func get_channels() -> Array[Dictionary]:
	if ! channels_loaded:
		for section in _config_file.get_sections():
			if section.begins_with("channel"):
				channels.append({
					"id": Util.get_uid(),
					"section": section,
					"name" : _config_file.get_value(section, "name"),
					"start_collapsed" : _config_file.get_value(section, "start_collapsed", false),
				})
		channels_loaded = true
	
	return channels


func get_empty_channel() -> Dictionary:
	return {
		"id": Util.get_uid(),
		"section": "",
		"name": "",
		"start_collapsed": false,
	}


func get_playlists() -> Array[Dictionary]:
	if ! playlists_loaded:
		for section in _config_file.get_sections():
			if section.begins_with("playlist"):
				playlists.append({
					"id": Util.get_uid(),
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
		playlists_loaded = true
	
	return playlists


func get_empty_playlist() -> Dictionary:
	return {
		"id": Util.get_uid(),
		"section": "",
		"channel": "",
		"name": "",
		"url": "",
		"download_path": "",
		"backup_upload_path": "",
		"remote_upload_path": "",
		"download_archive_file_name": "",
		"cookies_from_browser": "firefox",
		"delete_download" : true,
		"preview_unarchived_on_startup" : false,
	}


func save_changes(settings : Dictionary) -> void:
	_config_file.clear()
	
	var config_section_names = {
		"paths": "path_",
		"servers": "server_",
		"channels": "channel_",
		"playlists": "playlist_",
	}
	
	for key in settings.keys():
		var section_count = 1
		
		for config_entry in settings[key]:
			var section = config_section_names[key] + str(section_count)
			
			for entry_var in config_entry.keys():
				if entry_var == "id" or entry_var == "section":
					continue
				
				var value = config_entry[entry_var]
				_config_file.set_value(section, entry_var, value)
			
			section_count += 1
	
	_config_file.save(CONFIG_PATH)
	
	console_signal_bus.add_line("Config changes saved")
	
	_load_config()
