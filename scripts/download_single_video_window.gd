extends Window

signal download_single_video_form_submitted(options : Dictionary)

# TODO Add option to download w/o checking archive file
@onready var single_video_url_input := %SingleVideoUrlInput
@onready var copy_to_backup_input := %CopyToBackupInput
@onready var copy_to_remote_input := %CopyToRemoteInput
@onready var delete_single_download_input := %DeleteSingleDownloadInput

var options = {
	"url": "",
	"copy_to_backup": true,
	"copy_to_remote": true,
	"delete_download": true,
}

var playlist : Dictionary:
	set(value):
		playlist = value
		copy_to_backup_input.button_pressed = playlist.backup_upload_path != ""
		copy_to_remote_input.button_pressed = playlist.remote_upload_path != ""
		delete_single_download_input.button_pressed = playlist.delete_download


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Escape"):
		get_viewport().set_input_as_handled()
		visible = false


func _on_single_video_url_input_text_changed(new_text: String) -> void:
	options.url = new_text


func _on_single_video_url_input_text_submitted(new_text: String) -> void:
	options.url = new_text
	download_single_video_form_submitted.emit(options)


func _on_copy_to_backup_input_toggled(toggled_on: bool) -> void:
	options.copy_to_backup = toggled_on


func _on_copy_to_remote_input_toggled(toggled_on: bool) -> void:
	options.copy_to_remote = toggled_on


func _on_delete_single_download_input_toggled(toggled_on: bool) -> void:
	options.delete_download = toggled_on


func _on_download_single_video_confirm_button_button_up() -> void:
	download_single_video_form_submitted.emit(options)
