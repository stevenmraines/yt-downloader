extends Control

@export var channel_name := "":
	set(value):
		channel_name = value
		if label:
			label.text = channel_name

@export var playlists := ["Astrogoblin Comment Shops"]:
	set(value):
		playlists = value
		for playlist_node in playlist_container.get_children():
			playlist_node.queue_free()
		for playlist in playlists:
			var scene = playlist_scene.instantiate()
			playlist_container.add_child(scene)
			scene.playlist_title = playlist

@onready var label := $VBoxContainer/Label
@onready var playlist_container := $VBoxContainer/PlaylistContainer
@onready var playlist_scene := load("res://scenes/playlist.tscn")


func _ready() -> void:
	label.text = channel_name
	for playlist in playlists:
		var scene = playlist_scene.instantiate()
		playlist_container.add_child(scene)
		scene.playlist_name = playlist
