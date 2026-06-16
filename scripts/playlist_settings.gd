extends VBoxContainer

@onready var name_input := %NameInput
@onready var url_input := %UrlInput
@onready var download_path_input := %DownloadPathInput
@onready var backup_path_input := %BackupPathInput
@onready var remote_path_input := %RemotePathInput
@onready var download_archive_file_name_input := %DownloadArchiveFileNameInput
@onready var cookies_from_browser_input := %CookiesFromBrowserInput
@onready var delete_download_input := %DeleteDownloadInput
@onready var preview_unarchived_on_startup_input := %PreviewUnarchivedOnStartupInput

var playlist : Dictionary:
	set(value):
		playlist = value
		name_input.text = playlist.name
		url_input.text = playlist.url
		download_path_input.text = playlist.download_path
		backup_path_input.text = playlist.backup_upload_path
		remote_path_input.text = playlist.remote_upload_path
		download_archive_file_name_input.text = playlist.download_archive_file_name
		delete_download_input.button_pressed = playlist.delete_download
		preview_unarchived_on_startup_input.button_pressed = playlist.preview_unarchived_on_startup
		
		for i in cookies_from_browser_input.get_item_count():
			var item = cookies_from_browser_input.get_item_text(i)
			if item == playlist.cookies_from_browser:
				cookies_from_browser_input.select(i)


func get_data() -> Dictionary:
	var id = cookies_from_browser_input.get_selected_id()
	return {
		"name": name_input.text,
		"url": url_input.text,
		"download_path": download_path_input.text,
		"backup_upload_path": backup_path_input.text,
		"remote_upload_path": remote_path_input.text,
		"download_archive_file_name": download_archive_file_name_input.text,
		"cookies_from_browser": cookies_from_browser_input.get_item_text(id),
		"delete_download": delete_download_input.button_pressed,
		"preview_unarchived_on_startup": preview_unarchived_on_startup_input.button_pressed,
	}
