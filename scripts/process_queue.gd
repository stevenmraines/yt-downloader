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
		pid = yt_dlp_wrapper.download_single_video(process.playlist)
	elif process.process_name == "mark_playlist_as_archived":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		pid = yt_dlp_wrapper.mark_playlist_as_archived(process.playlist)
	elif process.process_name == "copy_to_backup":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		var download_path = process.playlist.download_path
		# TODO How to get filename?
		var filename = download_path + "/whatever.mp4"
		var backup_path = process.playlist.backup_upload_path
		if backup_path:
			pass
			#if DirAccess.dir_exists_absolute(backup_path):
				#console_signal_bus.add_line("Copying download to %s" % backup_path)
				#DirAccess.copy_absolute(download_path, backup_path)
			#else:
				#console_signal_bus.add_error("Error copying download to %s, dir does not exist" % backup_path)
	elif process.process_name == "copy_to_remote":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		var download_path = process.playlist.download_path
		var filename = download_path + "/whatever.mp4"
		var remote_path = process.playist.remote_upload_path
		if remote_path:
			pass
		#var ip = ""
		#var user = ""
		#var ssh_key_path = ""
		# TODO Add error if remote_ip, user, or ssh_key aren't set
		#Util.scp(filename, remote_path, remote_ip, remote_user, ssh_key_path)
	elif process.process_name == "delete_download":
		console_signal_bus.add_line("Starting queued process %s" % process.process_name)
		var download_path = process.playlist.download_path
		var filename = download_path + "/whatever.mp4"
		# FIXME Use OS.create_process so that we can get the PID like with everything else
		#DirAccess.remove_absolute(filename)
	
	process.pid = pid
	# FIXME "Unable to start the timer because it's not inside the scene tree"
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
	
	var copy_to_backup_process = Process.new()
	copy_to_backup_process.process_name = "copy_to_backup"
	copy_to_backup_process.playlist = playlist
	copy_to_backup_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	process.parent_process = process
	processes.append(copy_to_backup_process)
	
	var copy_to_remote_process = Process.new()
	copy_to_remote_process.process_name = "copy_to_remote"
	copy_to_remote_process.playlist = playlist
	copy_to_remote_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	process.parent_process = process
	processes.append(copy_to_remote_process)
	
	if delete_download:
		var delete_download_process = Process.new()
		delete_download_process.process_name = "delete_download"
		delete_download_process.playlist = playlist
		delete_download_process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
		process.parent_process = process
		processes.append(delete_download_process)
	
	console_signal_bus.add_line("Queueing process download_single_video")
	queue_changed.emit(processes)


func queue_mark_playlist_as_archived(playlist : Dictionary) -> void:
	var process = Process.new()
	process.process_name = "mark_playlist_as_archived"
	process.playlist = playlist
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
	console_signal_bus.add_line("Queueing process mark_playlist_as_archived")
	queue_changed.emit(processes)


func queue_update() -> void:
	var process = Process.new()
	process.process_name = "update"
	process.progress_timer_timeout.connect(_on_process_progress_timer_timeout)
	processes.append(process)
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
			console_signal_bus.add_error("Process %s (%d) completed with error code %d" % [process.process_name, process.pid, exit_code])
		
		process.progress_timer.stop()
		queue_changed.emit(processes)
		#current_process_index += 1
