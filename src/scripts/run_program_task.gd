class_name RunProgramTask
extends RefCounted

## 用于运行外部程序，且不需要程序的命令行输出

var executable_path: String
var argument_string: String
var callback: Callable
var pid: int


func _init(a_executable_path: String, a_argument_string: String, a_callback: Callable) -> void:
    executable_path = a_executable_path
    argument_string = a_argument_string
    callback = a_callback


func run() -> void:
    var executer_helper := Executer.ExecuterHelper.new(executable_path)
    executer_helper.set_args(argument_string)
    Logger.info("Run: %s %s" % [executable_path, argument_string])
    pid = executer_helper.create_process()


func is_running() -> bool:
    return OS.is_process_running(pid)


func call_callback() -> void:
    callback.call()


func kill() -> void:
    if OS.is_process_running(pid):
        OS.kill(pid)
        Logger.debug("Killed process with pid: " + str(pid))