@tool
class_name ProgressIndicator
extends Control

@export var amount: int = 6

var stage: int = -1:
    set(value):
        stage = value
        if stage >= amount:
            stage = amount - 1
        if stage in [-1, 0, 1, 2, 4]:
            animating = true
        else:
            animating = false
        ProjectManager.current_project.pipeline_stage = stage

var t: float = 0
var animating: bool = false
var pipeline_started: bool = false


func _ready() -> void:
    if not Engine.is_editor_hint():
        EventBus.pipeline_started.connect(func(): pipeline_started = true)
        EventBus.pipeline_finished.connect(func(): pipeline_started = false)


func _physics_process(delta: float) -> void:
    t += delta * 5.0
    queue_redraw()


func _draw() -> void:
    var h := size.y
    var w := size.x
    draw_line(Vector2(w / 2, 0), Vector2(w / 2, h), Color.WHITE, 3)
    for i in range(amount):
        var y := h / float(amount) * (i + 0.5)
        var color = Color.GRAY
        if i <= stage + int(pipeline_started):
            color = Color.GREEN
        if pipeline_started and animating and (i == stage or (stage == -1 and i == 0)):
            draw_circle(Vector2(w / 2, y + (h / float(amount)) * float(stage != -1)), 9, Color.GRAY, false, 2, true)
            draw_arc(Vector2(w / 2, y + (h / float(amount)) * float(stage != -1)), 9, t, t + PI / 3, 20, Color.GREEN_YELLOW, 2, true)
        draw_circle(Vector2(w / 2, y), 7, color, true, -1, true)
