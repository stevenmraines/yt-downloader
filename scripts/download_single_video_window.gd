extends Window

signal download_single_video_form_submitted(options : Dictionary)

@onready var single_video_url_input := %SingleVideoUrlInput
@onready var use_archive_file_input := %UseArchiveFileInput
@onready var copy_to_backup_input := %CopyToBackupInput
@onready var copy_to_remote_input := %CopyToRemoteInput
@onready var delete_single_download_input := %DeleteSingleDownloadInput

var options = {
	"url": "",
	"use_archive_file": true,
	"copy_to_backup": true,
	"copy_to_remote": true,
	"delete_download": true,
}

var playlist : Dictionary:
	set(value):
		playlist = value
		_reset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Escape"):
		get_viewport().set_input_as_handled()
		visible = false


func _reset() -> void:
	use_archive_file_input.button_pressed = true
	copy_to_backup_input.button_pressed = playlist.backup_upload_path != ""
	copy_to_remote_input.button_pressed = playlist.remote_upload_path != ""
	delete_single_download_input.button_pressed = playlist.delete_download
	options.url = ""
	options.use_archive_file = true
	options.copy_to_backup = true
	options.copy_to_remote = true
	options.delete_download = true


func _submit_form() -> void:
	options.url = single_video_url_input.text
	options.use_archive_file = use_archive_file_input.button_pressed
	options.copy_to_backup = copy_to_backup_input.button_pressed
	options.copy_to_remote = copy_to_remote_input.button_pressed
	options.delete_download = delete_single_download_input.button_pressed
	download_single_video_form_submitted.emit(options)


func _on_single_video_url_input_text_submitted(_new_text: String) -> void:
	_submit_form()


func _on_download_single_video_confirm_button_button_up() -> void:
	_submit_form()


func _on_visibility_changed():
	if visible:
		single_video_url_input.grab_focus.call_deferred()
		_reset()
