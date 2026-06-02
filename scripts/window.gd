extends PanelContainer

@export var yt_dlp_path := ""

@onready var yt_dlp_path_input := $MarginContainer/VSplitContainer/YtDlpConfig/HBoxContainer/MarginContainer/YtDlpPathInput
@onready var yt_dlp_input_timer := $YtDlpInputTimer
@onready var channel_container := $MarginContainer/VSplitContainer/ChannelContainer
@onready var console_text_input := $MarginContainer/VSplitContainer/MarginContainer/Console/MarginContainer/ConsoleTextInput
@onready var console_signal_bus := $ConsoleSignalBus
@onready var config_loader := $ConfigLoader
@onready var channel_scene := load("res://scenes/channel.tscn")

var config : Dictionary
var typing := false


func _ready() -> void:
	config = config_loader.config
	for config_path in config["paths"]:
		if config_path.name == "yt-dlp":
			yt_dlp_path = config_path.path
			yt_dlp_path_input.text = yt_dlp_path
	_populate_channels()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		get_viewport().set_input_as_handled()
		get_tree().quit(0)
	
	
	if event is InputEventKey:
		if yt_dlp_path_input.has_focus():
			yt_dlp_path = yt_dlp_path_input.text
			get_viewport().set_input_as_handled()
			typing = true
			yt_dlp_input_timer.start()
			return
		
		# FIXME Gotta be a better way to do this
		for channel in channel_container.get_children():
			for playlist in channel.playlist_container.get_children():
				if playlist.backup_upload_path_input.has_focus():
					console_signal_bus.add_line(playlist.backup_upload_path_input.text)
					get_viewport().set_input_as_handled()
				elif playlist.remote_upload_path_input.has_focus():
					console_signal_bus.add_line(playlist.remote_upload_path_input.text)
					get_viewport().set_input_as_handled()


func _on_yt_dlp_input_timer_timeout() -> void:
	console_signal_bus.add_line("write to file " + yt_dlp_path)


func _populate_channels() -> void:
	for channel in config["channels"]:
		var channel_node = channel_scene.instantiate()
		channel_container.add_child(channel_node)
		channel_node.channel_name = channel
		channel_node.playlists = config["playlists"]
