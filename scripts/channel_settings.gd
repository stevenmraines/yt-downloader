extends FoldableContainer

@onready var playlists_container := %PlaylistsContainer
@onready var new_playlist_button := %NewPlaylistButton
@onready var playlist_settings_scene := load("res://scenes/playlist_settings.tscn")

var channel : Dictionary:
	set(value):
		channel = value
		title = channel.name

var playlists : Array[Dictionary]:
	set(value):
		playlists = value
		
		for playlist in playlists:
			var playlist_node = playlist_settings_scene.instantiate()
			playlists_container.add_child(playlist_node)
			playlist_node.playlist = playlist
