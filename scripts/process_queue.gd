class_name ProcessQueue extends Node

signal queue_changed(processes : Array[Process])

@export var yt_dlp_wrapper : YtDlpWrapper

var processes : Array[Process]
var current_process_index := 0
var console_signal_bus : ConsoleSignalBus
var remote_ip : String
var remote_user : String
var ssh_key_path : String


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
		Process.ProcessState.ERRORED
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
	process.status = Process.ProcessState.IN_PROGRESS
	var pid = -1
	
	if process.process_name == "update":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		pid = yt_dlp_wrapper.update()
	elif process.process_name == "download_playlist":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		pid = yt_dlp_wrapper.download_playlist(process.playlist)
	elif process.process_name == "download_single_video":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		process.data.temp_file = OS.get_user_data_dir() + "/download_single_video_temp.txt"
		pid = yt_dlp_wrapper.download_single_video(process)
	elif process.process_name == "get_single_video_filename":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		_get_single_video_filename(process)
	elif process.process_name == "mark_playlist_as_archived":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		process.data.temp_file = OS.get_user_data_dir() + "/mark_playlist_as_archived_temp.txt"
		pid = yt_dlp_wrapper.mark_playlist_as_archived(process)
	elif process.process_name == "populate_archive_file":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		_populate_archive_file(process)
	elif process.process_name == "copy_to_backup":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		pid = _copy_to_backup(process)
	elif process.process_name == "copy_to_remote":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		pid = _copy_to_remote(process)
	elif process.process_name == "delete_download":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		pid = _delete_download(process)
	
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
	
	# yt-dlp sometimes spawns two processes with the same name, for some reason.
	# Both need to be killed.
	var os_processes = Util.get_processes()
	for os_pid in os_processes:
		var process_name = os_processes[os_pid]
		if process_name == "yt-dlp.exe" and os_pid != process.pid:
			var second_kill_exit_code = error_string(OS.kill(os_pid))
			console_signal_bus.add_warning("Secondary process %s (%d) killed with exit code %s" % [process_name, os_pid, second_kill_exit_code])
	
	queue_changed.emit(processes)


func queue_download_playlist(playlist : Dictionary) -> void:
	var process = Process.new()
	process.process_name = "download_playlist"
	process.playlist = playlist
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	add_child(process)
	console_signal_bus.add_line("Queueing process download_playlist")
	queue_changed.emit(processes)


func queue_download_single_video(url : String, playlist : Dictionary, delete_download : bool) -> void:
	var process = Process.new()
	process.process_name = "download_single_video"
	# Overwrite the playlist's delete_download option for this single video
	playlist.delete_download = delete_download
	playlist.url = url
	process.playlist = playlist
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	add_child(process)
	
	var get_filename_process = Process.new()
	get_filename_process.process_name = "get_single_video_filename"
	get_filename_process.playlist = playlist
	get_filename_process.killable = false
	get_filename_process.parent_process = process
	processes.append(get_filename_process)
	process.child_processes.append(get_filename_process)
	add_child(get_filename_process)
	
	var copy_to_backup_process = Process.new()
	copy_to_backup_process.process_name = "copy_to_backup"
	copy_to_backup_process.playlist = playlist
	copy_to_backup_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	copy_to_backup_process.parent_process = process
	processes.append(copy_to_backup_process)
	process.child_processes.append(copy_to_backup_process)
	add_child(copy_to_backup_process)
	
	var copy_to_remote_process = Process.new()
	copy_to_remote_process.process_name = "copy_to_remote"
	copy_to_remote_process.playlist = playlist
	copy_to_remote_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	copy_to_remote_process.parent_process = process
	processes.append(copy_to_remote_process)
	process.child_processes.append(copy_to_remote_process)
	add_child(copy_to_remote_process)
	
	if delete_download:
		var delete_download_process = Process.new()
		delete_download_process.process_name = "delete_download"
		delete_download_process.playlist = playlist
		delete_download_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
		delete_download_process.parent_process = process
		processes.append(delete_download_process)
		process.child_processes.append(delete_download_process)
		add_child(delete_download_process)
	
	console_signal_bus.add_line("Queueing process download_single_video")
	queue_changed.emit(processes)


func queue_mark_playlist_as_archived(playlist : Dictionary) -> void:
	var process = Process.new()
	process.process_name = "mark_playlist_as_archived"
	process.playlist = playlist
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	add_child(process)
	console_signal_bus.add_line("Queueing process mark_playlist_as_archived")
	
	var child_process = Process.new()
	child_process.process_name = "populate_archive_file"
	child_process.killable = false
	child_process.playlist = playlist
	child_process.parent_process = process
	processes.append(child_process)
	add_child(child_process)
	console_signal_bus.add_line("Queueing process populate_archive_file")
	process.child_processes.append(child_process)
	
	queue_changed.emit(processes)


func queue_update() -> void:
	var process = Process.new()
	process.process_name = "update"
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	add_child(process)
	console_signal_bus.add_line("Queueing process update")
	queue_changed.emit(processes)


func _on_process_progress_timer_timeout(process : Process) -> void:
	if ! OS.is_process_running(process.pid):
		var exit_code = OS.get_process_exit_code(process.pid)
		process.exit_code = exit_code
		
		if exit_code == 0:
			process.status = Process.ProcessState.COMPLETE
			console_signal_bus.add_line("Process %s (%d) complete" % [process.process_name, process.pid])
		else:
			process.status = Process.ProcessState.ERRORED
			console_signal_bus.add_error("Process %s (%d) completed with error code %s" % [process.process_name, process.pid, error_string(exit_code)])
		
		process.progress_timer.stop()
		queue_changed.emit(processes)


func _populate_archive_file(process : Process) -> void:
	var temp_file = process.parent_process.data.temp_file
	var archive_file = Util.get_archive_file_path(process.playlist)
	var file = FileAccess.open(temp_file, FileAccess.READ)
	
	if not file:
		console_signal_bus.add_error("Failed to read temp file: %s" % temp_file)
		process.status = Process.ProcessState.ERRORED
		return
	
	var content = file.get_as_text()
	file.close()
	
	var out = FileAccess.open(archive_file, FileAccess.WRITE)
	
	if not out:
		console_signal_bus.add_error("Failed to write archive file: %s" % archive_file)
		process.status = Process.ProcessState.ERRORED
		return
	
	for video_id in content.split("\n"):
		var id = video_id.strip_edges()
		
		if id != "":
			out.store_string("youtube " + id + "\n")
	
	out.close()
	process.status = Process.ProcessState.COMPLETE
	DirAccess.remove_absolute(temp_file)


# TODO I guess this won't be killable, unless we use multithreading or something, idk
func _get_single_video_filename(process : Process) -> void:
	var temp_file = process.parent_process.data.temp_file
	var file = FileAccess.open(temp_file, FileAccess.READ)
	
	if not file:
		console_signal_bus.add_error("Failed to read temp file: %s" % temp_file)
		process.status = Process.ProcessState.ERRORED
		return
	
	var content = file.get_as_text()
	file.close()
	var regex = RegEx.new()
	regex.compile(r"^\[Merger\] Merging formats into \"(?<filename>.+\.mp4)\"")
	
	for line in content.split("\n"):
		line = line.strip_edges()
		
		if line == "":
			continue
		
		var result = regex.search(line)
		
		if result:
			process.parent_process.data.filename = result.get_string("filename")
			console_signal_bus.add_line("Downloaded video: %s" % process.parent_process.data.filename)
			DirAccess.remove_absolute(temp_file)
			process.status = Process.ProcessState.COMPLETE
	
	if ! process.parent_process.data.filename:
		process.status = Process.ProcessState.ERRORED
		console_signal_bus.add_error("Could not parse downloaded video filename")


func _copy_to_backup(process : Process) -> int:
	var download_path = process.playlist.download_path
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
			process.status = Process.ProcessState.ERRORED
	
	return pid


func _copy_to_remote(process : Process) -> int:
	var download_path = process.playlist.download_path
	var filename = process.parent_process.data.filename
	print(process.playlist)
	var remote_path = process.playist.remote_upload_path
	var pid = -1
	
	if remote_path:
		pass
		#var ip = ""
		#var user = ""
		#var ssh_key_path = ""
		# TODO Add error if remote_ip, user, or ssh_key aren't set
		#pid = Util.scp(filename, remote_path, remote_ip, remote_user, ssh_key_path)
	
	return pid


func _delete_download(process : Process) -> int:
	var download_path = process.playlist.download_path
	var filename = process.parent_process.data.filename
	var pid = Util.rm(filename)
	
	if pid == -1:
		# TODO
		pass
	
	return pid
