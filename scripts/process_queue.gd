class_name ProcessQueue extends Node

signal queue_changed(processes : Array[Process])

@export var yt_dlp_wrapper : YtDlpWrapper

var processes : Array[Process]
var current_process_index := 0
var console_signal_bus : ConsoleSignalBus
var selected_server : Dictionary


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]
	if ! yt_dlp_wrapper:
		console_signal_bus.add_error("yt_dlp_wrapper not set in process_queue")


func _process(_delta):
	if current_process_index >= processes.size():
		return
	
	var current_process = processes[current_process_index]
	
	var finished_states = [
		Process.ProcessState.COMPLETE,
		Process.ProcessState.KILLED,
		Process.ProcessState.FAILED,
		Process.ProcessState.SKIPPED
	]
	
	if finished_states.has(current_process.status):
		current_process_index += 1
		return
	
	if current_process.status == Process.ProcessState.QUEUED:
		if current_process.parent_process and current_process.parent_process.status == Process.ProcessState.KILLED:
			# Kill any children of killed parent processes
			kill_process(current_process)
		else:
			_start_queued_process(current_process)


func _start_queued_process(process : Process) -> void:
	console_signal_bus.add_line("Starting queued process %s" % process.process_name)
	process.status = Process.ProcessState.IN_PROGRESS
	var pid = -1
	
	if process.process_name == Process.UPDATE_PROCESS:
		pid = yt_dlp_wrapper.update()
	elif process.process_name == Process.DOWNLOAD_PLAYLIST_PROCESS:
		process.data.temp_file = OS.get_user_data_dir() + "/download_playlist_temp.txt"
		pid = yt_dlp_wrapper.download_playlist(process)
	elif process.process_name == Process.GET_VIDEO_FILENAMES_PROCESS:
		_get_video_filenames(process)
	elif process.process_name == Process.DOWNLOAD_SINGLE_VIDEO_PROCESS:
		process.data.temp_file = OS.get_user_data_dir() + "/download_single_video_temp.txt"
		pid = yt_dlp_wrapper.download_single_video(process)
	elif process.process_name == Process.GET_SINGLE_VIDEO_FILENAME_PROCESS:
		_get_single_video_filename(process)
	elif process.process_name == Process.MARK_PLAYLIST_AS_ARCHIVED_PROCESS:
		process.data.temp_file = OS.get_user_data_dir() + "/mark_playlist_as_archived_temp.txt"
		pid = yt_dlp_wrapper.mark_playlist_as_archived(process)
	elif process.process_name == Process.POPULATE_ARCHIVE_FILE_PROCESS:
		_populate_archive_file(process)
	elif process.process_name == Process.COPY_SINGLE_TO_BACKUP_PROCESS:
		pid = _copy_single_to_backup(process)
	elif process.process_name == Process.COPY_SINGLE_TO_REMOTE_PROCESS:
		pid = _copy_single_to_remote(process)
	elif process.process_name == Process.DELETE_SINGLE_DOWNLOAD_PROCESS:
		pid = _delete_single_download(process)
	elif process.process_name == Process.COPY_MULTIPLE_TO_BACKUP_PROCESS:
		pid = _copy_multiple_to_backup(process)
	elif process.process_name == Process.COPY_MULTIPLE_TO_REMOTE_PROCESS:
		pid = _copy_multiple_to_remote(process)
	elif process.process_name == Process.DELETE_MULTIPLE_DOWNLOADS_PROCESS:
		pid = _delete_multiple_downloads(process)
	
	process.pid = pid
	
	if process.killable:
		process.progress_timer.start()
	
	queue_changed.emit(processes)


func kill_process(process : Process) -> void:
	process.progress_timer.stop()
	var kill_exit_code = error_string(0)
	if process.pid > -1:
		kill_exit_code = error_string(OS.kill(process.pid))
	process.status = Process.ProcessState.KILLED
	
	console_signal_bus.add_warning("Process %s (%d) killed with exit code %s" % [process.process_name, process.pid, kill_exit_code])
	
	var yt_dlp_processes = [
		Process.DOWNLOAD_PLAYLIST_PROCESS,
		Process.DOWNLOAD_SINGLE_VIDEO_PROCESS,
		Process.MARK_PLAYLIST_AS_ARCHIVED_PROCESS
	]
	
	if yt_dlp_processes.has(process.process_name):
		# yt-dlp sometimes spawns two processes with the same name, for some reason.
		# Both need to be killed.
		var os_processes = Util.get_processes()
		for os_pid in os_processes:
			var process_name = os_processes[os_pid]
			if process_name == "yt-dlp.exe" and os_pid != process.pid:
				var second_kill_exit_code = error_string(OS.kill(os_pid))
				console_signal_bus.add_warning("Secondary process %s (%d) killed with exit code %s" % [process_name, os_pid, second_kill_exit_code])
	
	queue_changed.emit(processes)


func queue_download_playlist(playlist : Dictionary, start_index : String, end_index : String) -> void:
	var process = Process.new()
	process.process_name = Process.DOWNLOAD_PLAYLIST_PROCESS
	process.playlist = playlist
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	add_child(process)
	
	var get_video_filenames_process = Process.new()
	get_video_filenames_process.process_name = Process.GET_VIDEO_FILENAMES_PROCESS
	get_video_filenames_process.playlist = playlist
	get_video_filenames_process.killable = false
	get_video_filenames_process.parent_process = process
	processes.append(get_video_filenames_process)
	process.child_processes.append(get_video_filenames_process)
	add_child(get_video_filenames_process)
	
	var copy_multiple_to_backup_process = Process.new()
	copy_multiple_to_backup_process.process_name = Process.COPY_MULTIPLE_TO_BACKUP_PROCESS
	copy_multiple_to_backup_process.playlist = playlist
	copy_multiple_to_backup_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	copy_multiple_to_backup_process.parent_process = process
	processes.append(copy_multiple_to_backup_process)
	process.child_processes.append(copy_multiple_to_backup_process)
	add_child(copy_multiple_to_backup_process)
	
	var copy_multiple_to_remote_process = Process.new()
	copy_multiple_to_remote_process.process_name = Process.COPY_MULTIPLE_TO_REMOTE_PROCESS
	copy_multiple_to_remote_process.playlist = playlist
	copy_multiple_to_remote_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	copy_multiple_to_remote_process.parent_process = process
	processes.append(copy_multiple_to_remote_process)
	process.child_processes.append(copy_multiple_to_remote_process)
	add_child(copy_multiple_to_remote_process)
	
	if process.playlist.delete_download:
		var delete_multiple_downloads_process = Process.new()
		delete_multiple_downloads_process.process_name = Process.DELETE_MULTIPLE_DOWNLOADS_PROCESS
		delete_multiple_downloads_process.playlist = playlist
		delete_multiple_downloads_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
		delete_multiple_downloads_process.parent_process = process
		processes.append(delete_multiple_downloads_process)
		process.child_processes.append(delete_multiple_downloads_process)
		add_child(delete_multiple_downloads_process)
	
	console_signal_bus.add_line("Queueing process %s" % process.process_name)
	queue_changed.emit(processes)


func queue_download_single_video(url : String, playlist : Dictionary, copy_to_backup : bool, copy_to_remote : bool, delete_download : bool) -> void:
	var process = Process.new()
	process.process_name = Process.DOWNLOAD_SINGLE_VIDEO_PROCESS
	# Overwrite the playlist's delete_download option for this single video
	playlist.delete_download = delete_download
	playlist.url = url
	process.playlist = playlist
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	add_child(process)
	
	var get_filename_process = Process.new()
	get_filename_process.process_name = Process.GET_SINGLE_VIDEO_FILENAME_PROCESS
	get_filename_process.playlist = playlist
	get_filename_process.killable = false
	get_filename_process.parent_process = process
	processes.append(get_filename_process)
	process.child_processes.append(get_filename_process)
	add_child(get_filename_process)
	
	if copy_to_backup:
		var copy_single_to_backup_process = Process.new()
		copy_single_to_backup_process.process_name = Process.COPY_SINGLE_TO_BACKUP_PROCESS
		copy_single_to_backup_process.playlist = playlist
		copy_single_to_backup_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
		copy_single_to_backup_process.parent_process = process
		processes.append(copy_single_to_backup_process)
		process.child_processes.append(copy_single_to_backup_process)
		add_child(copy_single_to_backup_process)
	
	if copy_to_remote:
		var copy_single_to_remote_process = Process.new()
		copy_single_to_remote_process.process_name = Process.COPY_SINGLE_TO_REMOTE_PROCESS
		copy_single_to_remote_process.playlist = playlist
		copy_single_to_remote_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
		copy_single_to_remote_process.parent_process = process
		processes.append(copy_single_to_remote_process)
		process.child_processes.append(copy_single_to_remote_process)
		add_child(copy_single_to_remote_process)
	
	if delete_download:
		var delete_single_download_process = Process.new()
		delete_single_download_process.process_name = Process.DELETE_SINGLE_DOWNLOAD_PROCESS
		delete_single_download_process.playlist = playlist
		delete_single_download_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
		delete_single_download_process.parent_process = process
		processes.append(delete_single_download_process)
		process.child_processes.append(delete_single_download_process)
		add_child(delete_single_download_process)
	
	console_signal_bus.add_line("Queueing process %s" % process.process_name)
	queue_changed.emit(processes)


func queue_mark_playlist_as_archived(playlist : Dictionary) -> void:
	var process = Process.new()
	process.process_name = Process.MARK_PLAYLIST_AS_ARCHIVED_PROCESS
	process.playlist = playlist
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	add_child(process)
	
	var child_process = Process.new()
	child_process.process_name = Process.POPULATE_ARCHIVE_FILE_PROCESS
	child_process.killable = false
	child_process.playlist = playlist
	child_process.parent_process = process
	processes.append(child_process)
	add_child(child_process)
	process.child_processes.append(child_process)
	
	console_signal_bus.add_line("Queueing process %s" % process.process_name)
	queue_changed.emit(processes)


func queue_update() -> void:
	var process = Process.new()
	process.process_name = Process.UPDATE_PROCESS
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	add_child(process)
	console_signal_bus.add_line("Queueing process %s" % process.process_name)
	queue_changed.emit(processes)


func _on_process_progress_timer_timeout(process : Process) -> void:
	if ! OS.is_process_running(process.pid):
		var exit_code = OS.get_process_exit_code(process.pid)
		process.exit_code = exit_code
		
		if exit_code == 0:
			process.status = Process.ProcessState.COMPLETE
			console_signal_bus.add_line("Process %s (%d) complete" % [process.process_name, process.pid])
		else:
			process.status = Process.ProcessState.FAILED
			console_signal_bus.add_error("Process %s (%d) completed with error code %s" % [process.process_name, process.pid, error_string(exit_code)])
		
		process.progress_timer.stop()
		queue_changed.emit(processes)


func _populate_archive_file(process : Process) -> void:
	var temp_file = process.parent_process.data.temp_file
	var archive_file = Util.get_archive_file_path(process.playlist)
	var file = FileAccess.open(temp_file, FileAccess.READ)
	
	if not file:
		console_signal_bus.add_error("Failed to read temp file: %s" % temp_file)
		process.status = Process.ProcessState.FAILED
		return
	
	var content = file.get_as_text()
	file.close()
	
	var out = FileAccess.open(archive_file, FileAccess.WRITE)
	
	if not out:
		console_signal_bus.add_error("Failed to write archive file: %s" % archive_file)
		process.status = Process.ProcessState.FAILED
		return
	
	for video_id in content.split("\n"):
		var id = video_id.strip_edges()
		
		if id != "":
			out.store_string("youtube " + id + "\n")
	
	out.close()
	process.status = Process.ProcessState.COMPLETE


# TODO I guess this won't be killable, unless we use multithreading or something, idk
func _get_single_video_filename(process : Process) -> void:
	var temp_file = process.parent_process.data.temp_file
	var file = FileAccess.open(temp_file, FileAccess.READ)
	
	if not file:
		console_signal_bus.add_error("Failed to read temp file: %s" % temp_file)
		for child_process in process.parent_process.child_processes:
			child_process.status = Process.ProcessState.FAILED
		return
	
	var content = file.get_as_text()
	file.close()
	var filename_regex = RegEx.new()
	filename_regex.compile(r"^\[Merger\] Merging formats into \"(?<filename>.+\.mp4)\"")
	var archived_regex = RegEx.new()
	archived_regex.compile(r"^\[download\] (?<id>.+):\s*(?<title>.*?)\s*has already been recorded in the archive")
	var downloaded_regex = RegEx.new()
	downloaded_regex.compile(r"^\[download\] (?<filename>.+) has already been downloaded")
	
	for line in content.split("\n"):
		line = line.strip_edges()
		
		if line == "":
			continue
		
		var result1 = filename_regex.search(line)
		var result2 = archived_regex.search(line)
		var result3 = downloaded_regex.search(line)
		
		if result1:
			process.parent_process.data.filename = result1.get_string("filename")
			console_signal_bus.add_line("Downloaded video: %s" % process.parent_process.data.filename)
			process.status = Process.ProcessState.COMPLETE
		elif result2:
			console_signal_bus.add_warning("Download %s skipped, video already archived" % result2.get_string("title"))
			for child_process in process.parent_process.child_processes:
				child_process.status = Process.ProcessState.SKIPPED
		elif result3:
			console_signal_bus.add_warning("Download %s skipped, video already downloaded" % result3.get_string("filename"))
			for child_process in process.parent_process.child_processes:
				child_process.status = Process.ProcessState.SKIPPED
	
	if ! process.parent_process.data.has("filename") and process.status != Process.ProcessState.SKIPPED:
		for child_process in process.parent_process.child_processes:
			child_process.status = Process.ProcessState.FAILED
		console_signal_bus.add_error("Could not parse downloaded video filename")


func _get_video_filenames(process : Process) -> void:
	var temp_file = process.parent_process.data.temp_file
	var file = FileAccess.open(temp_file, FileAccess.READ)
	
	if not file:
		console_signal_bus.add_error("Failed to read temp file: %s" % temp_file)
		for child_process in process.parent_process.child_processes:
			child_process.status = Process.ProcessState.FAILED
		return
	
	var content = file.get_as_text()
	file.close()
	var filename_regex = RegEx.new()
	filename_regex.compile(r"^\[Merger\] Merging formats into \"(?<filename>.+\.mp4)\"")
	var archived_regex = RegEx.new()
	# FIXME Title issue: ERROR: Unicode parsing error, some characters were replaced with � (U+FFFD): Invalid UTF-8 leading byte (92), try with Taskmaster season 21 ep 8
	archived_regex.compile(r"^\[download\] (?<id>.+):\s*(?<title>.*?)\s*has already been recorded in the archive")
	var downloaded_regex = RegEx.new()
	downloaded_regex.compile(r"^\[download\] (?<filename>.+) has already been downloaded")
	var file_parsed = false
	
	for line in content.split("\n"):
		line = line.strip_edges()
		
		if line == "":
			continue
		
		var result1 = filename_regex.search(line)
		var result2 = archived_regex.search(line)
		var result3 = downloaded_regex.search(line)
		
		if result1:
			file_parsed = true
			var filename = result1.get_string("filename")
			if ! process.parent_process.data.has("filenames"):
				process.parent_process.data.filenames = []
			process.parent_process.data.filenames.append(filename)
			console_signal_bus.add_line("Downloaded video: %s" % filename)
			process.status = Process.ProcessState.COMPLETE
		elif result2:
			file_parsed = true
			console_signal_bus.add_warning("Download %s skipped, video already archived" % result2.get_string("title"))
		elif result3:
			file_parsed = true
			console_signal_bus.add_warning("Download %s skipped, video already downloaded" % result3.get_string("filename"))
	
	if ! file_parsed:
		console_signal_bus.add_error("Could not parse downloaded video filename")
		for child_process in process.parent_process.child_processes:
			child_process.status = Process.ProcessState.FAILED
	elif ! process.parent_process.data.has("filenames"):
		console_signal_bus.add_warning("Downloads skipped, no new videos found")
		for child_process in process.parent_process.child_processes:
			child_process.status = Process.ProcessState.SKIPPED
	elif process.parent_process.data.filenames.size() > 0:
		console_signal_bus.add_line("%d new videos found" % process.parent_process.data.filenames.size())
		process.status = Process.ProcessState.COMPLETE


func _copy_single_to_backup(process : Process) -> int:
	var filename = process.parent_process.data.filename
	var backup_path = process.playlist.backup_upload_path
	var pid = -1
	
	if backup_path:
		if DirAccess.dir_exists_absolute(backup_path):
			console_signal_bus.add_line("Copying download to %s" % backup_path)
			pid = Util.cp(filename, backup_path)
			if pid == -1:
				console_signal_bus.add_error("Error copying download to %s, process could not be created" % backup_path)
		else:
			console_signal_bus.add_error("Error copying download to %s, dir does not exist" % backup_path)
			process.status = Process.ProcessState.FAILED
	
	return pid


func _copy_multiple_to_backup(process : Process) -> int:
	var filenames = process.parent_process.data.filenames as Array[String]
	var download_path = process.playlist.download_path
	var backup_path = process.playlist.backup_upload_path
	var pid = -1
	
	if backup_path:
		if DirAccess.dir_exists_absolute(backup_path):
			console_signal_bus.add_line("Copying downloads to %s" % backup_path)
			pid = Util.cp_multi(filenames, download_path, backup_path)
			if pid == -1:
				console_signal_bus.add_error("Error copying downloads to %s, process could not be created" % backup_path)
		else:
			console_signal_bus.add_error("Error copying downloads to %s, dir does not exist" % backup_path)
			process.status = Process.ProcessState.FAILED
	
	return pid


func _copy_single_to_remote(process : Process) -> int:
	var filename = process.parent_process.data.filename
	var remote_path = process.playlist.remote_upload_path
	var pid = -1
	
	if remote_path:
		pid = Util.scp(filename, remote_path, selected_server.ip, selected_server.user, selected_server.ssh_key_path)
		if pid == -1:
			console_signal_bus.add_error("Error uploading to %s, process could not be created" % remote_path)
	
	return pid


func _copy_multiple_to_remote(process : Process) -> int:
	var filenames = process.parent_process.data.filenames as Array[String]
	var remote_path = process.playlist.remote_upload_path
	var pid = -1
	
	if remote_path:
		pid = Util.scp_multi(filenames, remote_path, selected_server.ip, selected_server.user, selected_server.ssh_key_path)
		if pid == -1:
			console_signal_bus.add_error("Error uploading to %s, process could not be created" % remote_path)
	
	return pid


func _delete_single_download(process : Process) -> int:
	var download_path = process.playlist.download_path
	var filename = process.parent_process.data.filename
	var pid = Util.rm(filename)
	
	if pid == -1:
		console_signal_bus.add_error("Error deleting download from %s, process could not be created" % download_path)
	
	return pid


func _delete_multiple_downloads(process : Process) -> int:
	var download_path = process.playlist.download_path
	var filenames = process.parent_process.data.filenames as Array[String]
	var pid = Util.rm_multi(filenames)
	
	if pid == -1:
		console_signal_bus.add_error("Error deleting downloads from %s, process could not be created" % download_path)
	
	return pid
