extends Window

signal settings_saved(settings : Dictionary)

@onready var yt_dlp_path_input := %YtDlpPathInput
@onready var yt_dlp_path_file_dialog := %YtDlpPathFileDialog
@onready var server_settings_container := %ServerSettingsContainer
@onready var channel_settings_container := %ChannelSettingsContainer
@onready var server_settings_scene := load("res://scenes/server_settings.tscn")
@onready var channel_settings_scene := load("res://scenes/channel_settings.tscn")

var yt_dlp_path : String:
	set(value):
		yt_dlp_path = value
		yt_dlp_path_input.text = yt_dlp_path

var servers : Array[Dictionary]:
	set(value):
		servers = value
		for server in servers:
			var server_node = server_settings_scene.instantiate()
			server_settings_container.add_child(server_node)
			server_node.server = server

var credentials : Array[Dictionary]:
	set(value):
		credentials = value
		for child in server_settings_container.get_children():
			for creds in credentials:
				if creds.server == child.server.name:
					child.credentials = creds

var channels : Array[Dictionary]:
	set(value):
		channels = value
		for channel in channels:
			var channel_node = channel_settings_scene.instantiate()
			channel_settings_container.add_child(channel_node)
			channel_node.channel = channel

var playlists : Array[Dictionary]:
	set(value):
		playlists = value
		var channel_playlists := {}
		
		for channel in channels:
			var x : Array[Dictionary]
			channel_playlists[channel.name] = x
		
		for playlist in playlists:
			channel_playlists[playlist.channel].append(playlist)
		
		for child in channel_settings_container.get_children():
			child.playlists = channel_playlists[child.channel.name]


func _get_all_data() -> Dictionary:
	var data = {
		"servers": [],
		"channels": [],
		"playlists": [],
	}
	
	for child in server_settings_container.get_children():
		data["servers"].append(child.get_data())
	
	for child in channel_settings_container.get_children():
		data["channels"].append(child.get_data())
		for child2 in child.playlists_container.get_children():
			data["playlists"].append(child2.get_data())
	
	return data


func _on_save_config_button_button_up() -> void:
	settings_saved.emit(_get_all_data())
