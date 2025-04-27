extends Node

var run_program_tasks: Array[RunProgramTask] = []

var tasks: Array[Task] = []
var running_pid: Array[int] = []
var error_code: int = -1


func _process(_delta: float) -> void:
    for task: RunProgramTask in run_program_tasks:
        if not task.is_running():
            task.call_callback()
            run_program_tasks.erase(task)

    for i in range(tasks.size() - 1, -1, -1):
        var task = tasks[i]
        if WorkerThreadPool.is_task_completed(task.id):
            error_code = WorkerThreadPool.wait_for_task_completion(task.id)
            if error_code != OK:
                Logger.error("WorkerThreadPool.wait_for_task_completion error: %d !" % error_code)
            else:
                task.call_callback()
            tasks.remove_at(i)


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        for task: RunProgramTask in run_program_tasks:
            task.kill()


func add_task(task: Task) -> void:
    if not task.check_callables():
        return

    task.run()
    tasks.push_back(task)


func run_program(task: RunProgramTask) -> void:
    task.run()
    run_program_tasks.push_back(task)