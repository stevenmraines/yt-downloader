extends FoldableContainer

signal playlist_marked_as_archived(list : Dictionary)

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
		#playlist_node.populate_download_queue()


func _on_playlist_mark_as_archived_clicked(list : Dictionary) -> void:
	playlist_marked_as_archived.emit(list)
