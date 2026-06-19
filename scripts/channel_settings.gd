extends FoldableContainer

signal channel_deleted(channel : Dictionary)
signal playlist_added(channel : Dictionary)
signal playlist_deleted(playlist : Dictionary)

@onready var channel_name_input := %ChannelNameInput
@onready var playlists_container := %PlaylistsContainer
@onready var delete_button := %DeleteButton
@onready var new_playlist_button := %NewPlaylistButton
@onready var delete_channel_confirmation_dialog := $DeleteChannelConfirmationDialog
@onready var playlist_settings_scene := load("res://scenes/playlist_settings.tscn")

var channel : Dictionary:
	set(value):
		channel = value
		title = channel.name
		channel_name_input.text = channel.name
		delete_button.text = "Delete Channel %s" % channel.name

var playlists : Array[Dictionary]:
	set(value):
		playlists = value
		
		for playlist in playlists:
			var playlist_node = playlist_settings_scene.instantiate()
			playlists_container.add_child(playlist_node)
			playlist_node.playlist = playlist
			playlist_node.playlist_deleted.connect(_on_playlist_deleted)


func _on_channel_name_input_text_changed(new_text: String) -> void:
	channel.name = new_text
	title = new_text
	delete_button.text = "Delete Channel %s" % new_text
	
	for playlist in playlists:
		playlist.channel = new_text
	
	for child in playlists_container.get_children():
		child.playlist.channel = new_text


func _on_delete_button_button_up():
	delete_channel_confirmation_dialog.dialog_text = "Are you sure you want to delete the %s channel?" % channel.name
	delete_channel_confirmation_dialog.visible = true


func _on_new_playlist_button_button_up() -> void:
	playlist_added.emit(channel)


func _on_playlist_deleted(playlist : Dictionary) -> void:
	playlist_deleted.emit(playlist)


func _on_delete_channel_confirmation_dialog_confirmed():
	channel_deleted.emit(channel)
