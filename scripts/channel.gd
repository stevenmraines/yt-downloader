extends FoldableContainer

@export var channel_name := "":
	set(value):
		channel_name = value
		title = channel_name

@export var playlists : Array

@onready var playlist_container := $ScrollContainer/PlaylistContainer
@onready var playlist_scene := load("res://scenes/playlist.tscn")


func _ready() -> void:
	for playlist in playlists:
		var scene = playlist_scene.instantiate()
		playlist_container.add_child(scene)
		scene.playlist_name = playlist


func populate_playlists(config_playlists : Array) -> void:
	playlists = config_playlists
	for playlist in playlists:
		if playlist.channel != channel_name:
			continue
		
		var playlist_node = playlist_scene.instantiate()
		playlist_container.add_child(playlist_node)
		playlist_node.channel = channel_name
		playlist_node.playlist = playlist.name
		playlist_node.url = playlist.url
		playlist_node.download_path = playlist.download_path
		playlist_node.backup_upload_path = playlist.backup_upload_path
		playlist_node.remote_upload_path = playlist.remote_upload_path
		playlist_node.download_archive_file_path = playlist.download_archive_file_path
		playlist_node.populate_download_queue(channel_name, playlist.name)
