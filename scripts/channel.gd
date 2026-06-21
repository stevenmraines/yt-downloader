extends FoldableContainer

signal playlist_marked_as_archived(list : Dictionary)
signal playlist_unarchived_videos_downloaded(list : Dictionary, start_index : int, end_index : int)
signal playlist_single_video_downloaded(url : String, list : Dictionary, copy_to_backup : bool, copy_to_remote : bool, delete_download : bool)

@export var channel_name := "":
	set(value):
		channel_name = value
		title = channel_name

@export var playlists : Array:
	set(value):
		playlists = value
		_populate_playlists()

@onready var playlist_container := $ScrollContainer/PlaylistContainer
@onready var playlist_scene := load("res://scenes/playlist.tscn")

var yt_dlp_wrapper : YtDlpWrapper


func _populate_playlists() -> void:
	for child in playlist_container.get_children():
		child.queue_free()
	
	for playlist in playlists:
		if playlist.channel != channel_name:
			continue
		
		var playlist_node = playlist_scene.instantiate()
		playlist_container.add_child(playlist_node)
		playlist_node.playlist = playlist
		playlist_node.mark_as_archived_clicked.connect(_on_playlist_mark_as_archived_clicked)
		playlist_node.download_unarchived_videos_button_clicked.connect(_on_download_unarchived_videos_button_clicked)
		playlist_node.download_single_video_button_clicked.connect(_on_download_single_video_button_clicked)
		playlist_node.yt_dlp_wrapper = yt_dlp_wrapper
		playlist_node.populate_preview_queue()


func _on_playlist_mark_as_archived_clicked(list : Dictionary) -> void:
	playlist_marked_as_archived.emit(list)


func _on_download_unarchived_videos_button_clicked(list : Dictionary, start_index : int, end_index : int) -> void:
	playlist_unarchived_videos_downloaded.emit(list, start_index, end_index)


func _on_download_single_video_button_clicked(url : String, list : Dictionary, copy_to_backup : bool, copy_to_remote : bool, delete_download : bool) -> void:
	playlist_single_video_downloaded.emit(url, list, copy_to_backup, copy_to_remote, delete_download)


func get_playlist_nodes() -> Array[Node]:
	return playlist_container.get_children()
