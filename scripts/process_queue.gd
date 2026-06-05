class_name ProcessQueue extends Node

signal queue_changed(processes : Array)

@export var yt_dlp_wrapper : YtDlpWrapper

var processes := []
var current_process_index := 0
var console_signal_bus : ConsoleSignalBus

const PROGRESS_CHECK_DURATION := 0.5

enum ProcessState { QUEUED, IN_PROGRESS, COMPLETE, ERRORED, KILLED }


func _ready() -> void:
	console_signal_bus = get_tree().get_nodes_in_group("console_signal_bus")[0]
	if ! yt_dlp_wrapper:
		console_signal_bus.add_error("yt_dlp_wrapper not set in process_queue")


func _process(_delta):
	if current_process_index >= processes.size():
		return
	
	var current_process = processes[current_process_index]
	
	if current_process.status == ProcessState.QUEUED:
		_start_queued_process(current_process_index)


func _start_queued_process(process_index : int) -> void:
	var process = processes[process_index]
	process.status = ProcessState.IN_PROGRESS
	var pid = -1
	
	if process.name == "update":
		console_signal_bus.add_line("Starting queued process %s" % process.name)
		pid = yt_dlp_wrapper.update()
	elif process.name == "download_playlist":
		console_signal_bus.add_line("Starting queued process %s" % process.name)
		pid = yt_dlp_wrapper.download_playlist(process.playlist)
	elif process.name == "download_single_video":
		console_signal_bus.add_line("Starting queued process %s" % process.name)
		pid = yt_dlp_wrapper.download_single_video(process.url, process.playlist)
	elif process.name == "mark_playlist_as_archived":
		console_signal_bus.add_line("Starting queued process %s" % process.name)
		yt_dlp_wrapper.mark_playlist_as_archived(process.playlist)
	
	process.pid = pid
	process.timer.connect("timeout", _on_progress_check_timer_timeout.bind(pid))
	process.timer.start()
	queue_changed.emit(processes)


func _on_progress_check_timer_timeout(pid : int) -> void:
	var i = processes.find_custom(func(x): return x.pid == pid)
	var process = processes[i]
	
	if ! OS.is_process_running(pid):
		var exit_code = OS.get_process_exit_code(pid)
		process.exit_code = exit_code
		
		if exit_code == 0:
			process.status = ProcessState.COMPLETE
			console_signal_bus.add_line("Process %s (%d) complete" % [process.name, process.pid])
		else:
			process.status = ProcessState.ERRORED
			console_signal_bus.add_error("Process %s (%d) completed with error code %d" % [process.name, process.pid, exit_code])
		
		process.timer.stop()
		queue_changed.emit(processes)
		current_process_index += 1


# FIXME This doesn't seem to be working
func kill_process(pid : int) -> void:
	var i = processes.find_custom(func(x): return x.pid == pid)
	var process = processes[i]
	process.timer.stop()
	var exit_code = error_string(OS.kill(pid))
	process.status = ProcessState.KILLED
	if i == current_process_index:
		current_process_index += 1
	console_signal_bus.add_warning("Process %s (%d) killed with exit code %s" % [process.name, process.pid, exit_code])
	queue_changed.emit(processes)


func queue_download_playlist(playlist : Dictionary) -> void:
	var timer = Timer.new()
	timer.wait_time = PROGRESS_CHECK_DURATION
	timer.autostart = false
	timer.one_shot = false
	add_child(timer)
	processes.append({
		"exit_code": -1,
		"name": "download_playlist",
		"pid": -1,
		"playlist": playlist,
		"status": ProcessState.QUEUED,
		"timer": timer,
		"url": "",
	})
	console_signal_bus.add_line("Queueing process download_playlist")
	queue_changed.emit(processes)


func queue_download_single_video(url : String, playlist : Dictionary, delete_download : bool) -> void:
	var timer = Timer.new()
	timer.wait_time = PROGRESS_CHECK_DURATION
	timer.autostart = false
	timer.one_shot = false
	add_child(timer)
	# Overwrite the playlist's delete_download option for this single video
	playlist.delete_download = delete_download
	processes.append({
		"exit_code": -1,
		"name": "download_single_video",
		"pid": -1,
		"playlist": playlist,
		"status": ProcessState.QUEUED,
		"timer": timer,
		"url": url,
	})
	console_signal_bus.add_line("Queueing process download_single_video")
	queue_changed.emit(processes)


func queue_mark_playlist_as_archived(playlist : Dictionary) -> void:
	var timer = Timer.new()
	timer.wait_time = PROGRESS_CHECK_DURATION
	timer.autostart = false
	timer.one_shot = false
	add_child(timer)
	processes.append({
		"exit_code": -1,
		"name": "mark_playlist_as_archived",
		"pid": -1,
		"playlist": playlist,
		"status": ProcessState.QUEUED,
		"timer": timer,
		"url": "",
	})
	console_signal_bus.add_line("Queueing process mark_playlist_as_archived")
	queue_changed.emit(processes)


func queue_update() -> void:
	var timer = Timer.new()
	timer.wait_time = PROGRESS_CHECK_DURATION
	timer.autostart = false
	timer.one_shot = false
	add_child(timer)
	processes.append({
		"exit_code": -1,
		"name": "update",
		"pid": -1,
		"playlist": "",
		"status": ProcessState.QUEUED,
		"timer": timer,
		"url": "",
	})
	console_signal_bus.add_line("Queueing process update")
	queue_changed.emit(processes)


func get_windows_processes() -> Array:
	var output = []
	OS.execute("tasklist", [], output, true)
	
	if output.size() > 0:
		var processes = output[0].split("\n")
		return processes
	
	return []
