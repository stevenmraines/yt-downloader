extends FoldableContainer

signal playlist_deleted(playlist : Dictionary)

@onready var name_input := %NameInput
@onready var url_input := %UrlInput
@onready var download_path_input := %DownloadPathInput
@onready var backup_path_input := %BackupPathInput
@onready var remote_path_input := %RemotePathInput
@onready var download_archive_file_name_input := %DownloadArchiveFileNameInput
@onready var cookies_from_browser_input := %CookiesFromBrowserInput
@onready var delete_download_input := %DeleteDownloadInput
@onready var preview_unarchived_on_startup_input := %PreviewUnarchivedOnStartupInput
@onready var delete_button := %DeleteButton
@onready var delete_playlist_confirmation_dialog := $DeletePlaylistConfirmationDialog
@onready var download_path_dialog := $DownloadPathDialog
@onready var backup_upload_path_dialog := $BackupUploadPathDialog

var playlist : Dictionary:
	set(value):
		playlist = value
		title = playlist.name
		name_input.text = playlist.name
		url_input.text = playlist.url
		download_path_input.text = playlist.download_path
		backup_path_input.text = playlist.backup_upload_path
		remote_path_input.text = playlist.remote_upload_path
		download_archive_file_name_input.text = playlist.download_archive_file_name
		delete_download_input.button_pressed = playlist.delete_download
		preview_unarchived_on_startup_input.button_pressed = playlist.preview_unarchived_on_startup
		delete_button.text = "Delete Playlist %s" % playlist.name
		
		for i in cookies_from_browser_input.get_item_count():
			var item = cookies_from_browser_input.get_item_text(i)
			if item == playlist.cookies_from_browser:
				cookies_from_browser_input.select(i)


func _on_name_input_text_changed(new_text: String) -> void:
	playlist.name = new_text
	title = new_text
	delete_button.text = "Delete Playlist %s" % new_text


func _on_delete_button_button_up():
	delete_playlist_confirmation_dialog.dialog_text = "Are you sure you want to delete the %s playlist?" % playlist.name
	delete_playlist_confirmation_dialog.visible = true


func _on_url_input_text_changed(new_text):
	playlist.url = new_text


func _on_download_path_input_text_changed(new_text):
	playlist.download_path = new_text


func _on_backup_path_input_text_changed(new_text):
	playlist.backup_upload_path = new_text


func _on_remote_path_input_text_changed(new_text):
	playlist.remote_upload_path = new_text


func _on_download_archive_file_name_input_text_changed(new_text):
	playlist.download_archive_file_name = new_text


func _on_cookies_from_browser_input_item_selected(index):
	playlist.cookies_from_browser = cookies_from_browser_input.get_item_text(index)


func _on_delete_download_input_toggled(toggled_on):
	playlist.delete_download = toggled_on


func _on_preview_unarchived_on_startup_input_toggled(toggled_on):
	playlist.preview_unarchived_on_startup = toggled_on


func _on_delete_playlist_confirmation_dialog_confirmed():
	playlist_deleted.emit(playlist)


func _on_download_path_button_button_up() -> void:
	download_path_dialog.current_dir = playlist.download_path
	download_path_dialog.visible = true


func _on_backup_path_button_button_up() -> void:
	backup_upload_path_dialog.current_dir = playlist.backup_upload_path
	backup_upload_path_dialog.visible = true


func _on_download_path_dialog_dir_selected(dir: String) -> void:
	playlist.download_path = dir
	download_path_input.text = dir


func _on_backup_upload_path_dialog_dir_selected(dir: String) -> void:
	playlist.backup_upload_path = dir
	backup_path_input.text = dir
