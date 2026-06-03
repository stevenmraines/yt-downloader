class_name ConfigLoader extends Node

var config : Dictionary:
	get():
		if ! loaded:
			_load_config()
		return config
var loaded := false
var console_signal_bus : ConsoleSignalBus

const DEFAULT_CONFIG_PATH := "res://config.cfg"
const CONFIG_PATH := "user://config.cfg"


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]


func _load_config() -> void:
	console_signal_bus.add_line("Loading config")
	
	loaded = true
	
	config = {
		"paths": [],
		"channels": [],
		"playlists": []
	}
	
	# Copy default config to user:// if it doesn't exist yet
	# TODO Turn this back on when app is ready
	#if ! FileAccess.file_exists(CONFIG_PATH):
	console_signal_bus.add_line("Copying config to " + OS.get_user_data_dir() + "/config.cfg")
	DirAccess.copy_absolute(DEFAULT_CONFIG_PATH, CONFIG_PATH)
	
	var config_file = ConfigFile.new()
	var err = config_file.load(CONFIG_PATH)
	
	if err != OK:
		console_signal_bus.add_error("Failed to parse config file, error code: %d" % err)
		return
	
	for section in config_file.get_sections():
		if section.begins_with("path"):
			var path_name = config_file.get_value(section, "name")
			var path = config_file.get_value(section, "path")
			console_signal_bus.add_line("Adding path " + path_name + ": " + path)
			config["paths"].append({
				"name": path_name,
				"path": path
			})
		elif section.begins_with("channel"):
			var channel_name = config_file.get_value(section, "name")
			var start_collapsed = str_to_var(config_file.get_value(section, "start_collapsed", "false"))
			console_signal_bus.add_line("Adding channel " + channel_name)
			config["channels"].append({
				"name" : channel_name,
				"start_collapsed" : start_collapsed,
			})
		elif section.begins_with("playlist"):
			var channel = config_file.get_value(section, "channel")
			var playlist_name = config_file.get_value(section, "name")
			var url = config_file.get_value(section, "url")
			var download_path = config_file.get_value(section, "download_path")
			var backup_upload_path = config_file.get_value(section, "backup_upload_path")
			var remote_upload_path = config_file.get_value(section, "remote_upload_path")
			var download_archive_file_name = config_file.get_value(section, "download_archive_file_name")
			var cookies_from_browser = config_file.get_value(section, "cookies_from_browser", "firefox")
			console_signal_bus.add_line("Adding playlist " + playlist_name + " to channel " + channel)
			config["playlists"].append({
				"channel": channel,
				"name": playlist_name,
				"url": url,
				"download_path": download_path,
				"backup_upload_path": backup_upload_path,
				"remote_upload_path": remote_upload_path,
				"download_archive_file_name": download_archive_file_name,
				"cookies_from_browser": cookies_from_browser
			})
		else:
			console_signal_bus.add_warning("Unrecognized config section found: " + section)
	
	console_signal_bus.add_line("Config loaded")
