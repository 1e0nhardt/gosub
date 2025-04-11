@tool
class_name ProgressIndicator
extends Control

@export var amount: int = 6

var stage: int = -1:
    set(value):
        stage = value
        if stage >= amount:
            stage = amount - 1
        ProjectManager.current_project.pipeline_stage = stage
        queue_redraw()


func _draw() -> void:
    var h := size.y
    var w := size.x
    draw_line(Vector2(w / 2, 0), Vector2(w / 2, h), Color.WHITE, 3)
    for i in range(amount):
        var y := h / float(amount) * (i + 0.5)
        var color = Color.GRAY
        if i <= stage:
            color = Color.GREEN
        draw_circle(Vector2(w / 2, y), 7, color, true, -1, true)