class_name Process extends Node

signal progress_timer_timeout(process : Process)

var status := ProcessState.QUEUED
var exit_code := 0
var pid := -1
var process_name := ""
var killable := true
var playlist := {}
var data := {}
var progress_timer := Timer.new()
var parent_process : Process
var child_processes : Array[Process]

const PROGRESS_CHECK_DURATION := 0.5

const UPDATE_PROCESS = "update"
const DOWNLOAD_PLAYLIST_PROCESS = "download_playlist"
const GET_VIDEO_FILENAMES_PROCESS = "get_video_filenames"
const DOWNLOAD_SINGLE_VIDEO_PROCESS = "download_single_video"
const GET_SINGLE_VIDEO_FILENAME_PROCESS = "get_single_video_filename"
const MARK_PLAYLIST_AS_ARCHIVED_PROCESS = "mark_playlist_as_archived"
const POPULATE_ARCHIVE_FILE_PROCESS = "populate_archive_file"
const COPY_SINGLE_TO_BACKUP_PROCESS = "copy_single_to_backup"
const COPY_SINGLE_TO_REMOTE_PROCESS = "copy_single_to_remote"
const DELETE_SINGLE_DOWNLOAD_PROCESS = "delete_single_download"
const COPY_MULTIPLE_TO_BACKUP_PROCESS = "copy_multiple_to_backup"
const COPY_MULTIPLE_TO_REMOTE_PROCESS = "copy_multiple_to_remote"
const DELETE_MULTIPLE_DOWNLOADS_PROCESS = "delete_multiple_downloads"

enum ProcessState { QUEUED, IN_PROGRESS, COMPLETE, FAILED, KILLED, SKIPPED }


func _ready() -> void:
	progress_timer.wait_time = PROGRESS_CHECK_DURATION
	progress_timer.autostart = false
	progress_timer.one_shot = false
	add_child(progress_timer)
	progress_timer.timeout.connect(_on_progress_timer_timeout)


func _on_progress_timer_timeout() -> void:
	progress_timer_timeout.emit(self)
