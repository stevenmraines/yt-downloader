extends MarginContainer

signal mark_as_archived_clicked(list : Dictionary)
signal download_unarchived_videos_button_clicked(list : Dictionary)
signal download_single_video_button_clicked(url : String, list : Dictionary, copy_to_backup : bool, copy_to_remote : bool, delete_download : bool)

@export var folded_minimum_height := 50.0
@export var unfolded_minimum_height := 450.0

@onready var label := %Label
@onready var preview_parent_container := %PreviewParentContainer
@onready var preview_container := %PreviewContainer
@onready var archive_confirmation_dialog := $ArchiveConfirmationDialog
@onready var download_unarchived_videos_button := %DownloadUnarchivedVideosButton
@onready var download_unarchived_videos_confirmation_dialog := $DownloadUnarchivedVideosConfirmationDialog
@onready var download_single_video_window := $DownloadSingleVideoWindow
@onready var preview_scene := load("res://scenes/preview.tscn")

var playlist : Dictionary:
	set(value):
		playlist = value
		
		# Set labels and inputs
		label.text = playlist.name
		preview_parent_container.visible = playlist.preview_unarchived_on_startup
		
		# Need to connect this here rather than in _ready because
		# playlist won't be set yet when _ready is fired.
		download_unarchived_videos_button.connect("button_up", _on_download_unarchived_videos_button_button_up.bind(playlist))

var console_signal_bus : ConsoleSignalBus
var yt_dlp_wrapper : YtDlpWrapper


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]
	custom_minimum_size = Vector2(0, folded_minimum_height)


func populate_preview_queue() -> void:
	if ! playlist.preview_unarchived_on_startup:
		return
	
	var preview_details = yt_dlp_wrapper.get_unarchived_video_details(playlist)
	for title in preview_details:
		var preview_node = preview_scene.instantiate()
		preview_container.add_child(preview_node)
		preview_node.title = title


func _on_mark_as_archived_button_button_up():
	archive_confirmation_dialog.dialog_text = "Are you sure you want to mark the " \
		+ playlist.name + " playlist as archived? This will overwrite the archive file."
	archive_confirmation_dialog.visible = true


func _on_download_single_video_button_pressed():
	download_single_video_window.single_video_url_input.text = ""
	download_single_video_window.title = "Download video using " + playlist.name + " options"
	download_single_video_window.visible = true
	download_single_video_window.single_video_url_input.grab_focus.call_deferred()


func _on_download_single_video_window_close_requested():
	download_single_video_window.visible = false


func _on_archive_confirmation_dialog_confirmed():
	mark_as_archived_clicked.emit(playlist)


func _on_download_unarchived_videos_button_button_up(list : Dictionary):
	# FIXME Changing our text after the fact like this is messing with the window positioning
	download_unarchived_videos_confirmation_dialog.dialog_text = "Are you sure you want to download unarchived videos from the " + list.name + " playlist?"
	download_unarchived_videos_confirmation_dialog.visible = true


func _on_download_unarchived_videos_confirmation_dialog_confirmed():
	download_unarchived_videos_button_clicked.emit(playlist)


func _on_foldable_container_folding_changed(is_folded: bool) -> void:
	custom_minimum_size = Vector2(0, folded_minimum_height) if is_folded \
		else Vector2(0, unfolded_minimum_height)


func _on_download_single_video_window_download_single_video_form_submitted(options: Dictionary) -> void:
	if ! options.url:
		console_signal_bus.add_error("No video URL provided")
		return
	
	download_single_video_button_clicked.emit(
		options.url,
		playlist,
		options.copy_to_backup,
		options.copy_to_remote,
		options.delete_download
	)
	
	download_single_video_window.visible = false
