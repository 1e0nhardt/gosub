class_name StatedTask
extends Task

var state := {}


func _init(a_task: Callable, a_callback: Callable = Callable()):
    task = a_task
    callback = a_callback


func run() -> void:
    id = WorkerThreadPool.add_task(task.bind(state))


func call_callback() -> void:
    callback.call(state)


func check_callables_arguments() -> bool:
    if task.get_argument_count() != 1:
        Logger.error("StatedTask: task function must take one argument!")
        return false

    if callback.get_argument_count() != 1:
        Logger.error("StatedTask: callback function must take one argument!")
        return false

    return true
