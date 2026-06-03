extends PanelContainer

@export var yt_dlp_path := "":
	set(value):
		yt_dlp_path = value
		yt_dlp_path_input.text = yt_dlp_path
		yt_dlp_wrapper.yt_dlp_path = yt_dlp_path
		console_signal_bus.add_line("yt-dlp path set to " + yt_dlp_path)
		# TODO Update config if value there is different

@onready var yt_dlp_path_input := $MarginContainer/VSplitContainer/YtDlpConfig/HBoxContainer/MarginContainer/HBoxContainer/YtDlpPathInput
@onready var yt_dlp_path_file_dialog := $MarginContainer/VSplitContainer/YtDlpConfig/HBoxContainer/MarginContainer/HBoxContainer/YtDlpPathFileDialog
@onready var channel_container := $MarginContainer/VSplitContainer/ChannelContainer
@onready var console_text_input := $MarginContainer/VSplitContainer/MarginContainer/Console/MarginContainer/ConsoleTextInput
@onready var console_signal_bus := $ConsoleSignalBus
@onready var config_loader := $ConfigLoader
@onready var yt_dlp_wrapper := $YtDlpWrapper
@onready var channel_scene := load("res://scenes/channel.tscn")

var config : Dictionary
var typing := false


func _ready() -> void:
	config = config_loader.config
	for config_path in config["paths"]:
		if config_path.name == "yt-dlp":
			yt_dlp_path = config_path.path
	_populate_channels()
	_create_archive_files()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		get_viewport().set_input_as_handled()
		get_tree().quit(0)
	
	if event is InputEventKey:
		# FIXME Gotta be a better way to do this
		for channel in channel_container.get_children():
			for playlist in channel.playlist_container.get_children():
				if playlist.backup_upload_path_input.has_focus():
					console_signal_bus.add_line(playlist.backup_upload_path_input.text)
					get_viewport().set_input_as_handled()
				elif playlist.remote_upload_path_input.has_focus():
					console_signal_bus.add_line(playlist.remote_upload_path_input.text)
					get_viewport().set_input_as_handled()


func _populate_channels() -> void:
	for channel in config["channels"]:
		var channel_node = channel_scene.instantiate()
		channel_container.add_child(channel_node)
		channel_node.channel_name = channel
		channel_node.playlists = config["playlists"]
		channel_node.playlist_marked_as_archived.connect(_on_playlist_marked_as_archived)
		channel_node.playlist_single_video_downloaded.connect(_on_playlist_single_video_downloaded)


func _create_archive_files() -> void:
	for playlist in config["playlists"]:
		var archive_dir = OS.get_user_data_dir() + "/archived"
		var channel_archive_dir = archive_dir + "/" + playlist.channel
		
		if ! DirAccess.dir_exists_absolute(archive_dir):
			console_signal_bus.add_line("Creating archive directory " + archive_dir)
			DirAccess.make_dir_absolute(archive_dir)
		
		if ! DirAccess.dir_exists_absolute(channel_archive_dir):
			console_signal_bus.add_line("Creating channel archive directory " + channel_archive_dir)
			DirAccess.make_dir_absolute(channel_archive_dir)
		
		var archive_file_path = channel_archive_dir + "/" + playlist.download_archive_file_name
		
		if ! FileAccess.file_exists(archive_file_path):
			console_signal_bus.add_line("Creating archive file " + archive_file_path)
			var archive_file = FileAccess.open(archive_file_path, FileAccess.WRITE)
			archive_file.close()


func _on_update_yt_dlp_button_button_up():
	yt_dlp_wrapper.update()


func _on_playlist_marked_as_archived(playlist : Dictionary) -> void:
	yt_dlp_wrapper.mark_playlist_as_archived(playlist)


func _on_playlist_single_video_downloaded(url : String, playlist : Dictionary) -> void:
	yt_dlp_wrapper.download_single_video(url, playlist)


func _on_yt_dlp_browse_files_button_button_up() -> void:
	yt_dlp_path_file_dialog.visible = true


func _on_yt_dlp_path_file_dialog_file_selected(path: String) -> void:
	yt_dlp_path = path
