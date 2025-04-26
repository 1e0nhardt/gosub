@tool
class_name TimelineMetricBar
extends Control

var metric_total_width_min: float = 100.0
var metric_total_width_max: float = 2600_000

# var half_pointer_width: float = 13.0 / 2.0
var metric_total_width: float = 1200.0:
    set(value):
        metric_total_width = value
        pixels_per_ms = metric_total_width / total_time
        queue_redraw()
# 目标总时长
var total_time: float = 10_000 # ms
# 手工定制的不同 ppms 时大间隔的时间跨度(帧)
var zoom_frames_per_interval := [2, 5, 10, 15, 30, 60, 150, 300, 600, 900, 1800, 3600, 9000, 18000, 36000]
# 修改大间隔时间宽度的pixels_per_ms阈值。用于控制刻度的尺度。
var pixels_per_ms_threshold := []
# 可以用来控制大间隔的宽度
var base_metric_total_time: float = 12_000_000.0 # ms
# 目标ppms
var pixels_per_ms: float = metric_total_width / base_metric_total_time
# 绘制区域起点的时间值
var start_time: int
var current_time: int = 0 # ms


func _init() -> void:
    pixels_per_ms_threshold.resize(zoom_frames_per_interval.size())
    for i in range(zoom_frames_per_interval.size()):
        pixels_per_ms_threshold[i] = (36000 / zoom_frames_per_interval[i]) * metric_total_width / base_metric_total_time


func _ready() -> void:
    resized.connect(_on_resized)
    _on_resized.call_deferred()
    # set_start_time.call_deferred(-int(half_pointer_width / pixels_per_ms))


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                var local_pos = event.position
                set_start_time(start_time + local_pos.x / pixels_per_ms)
                Logger.info("%.2fs" % (start_time / 1000.0))

        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            if metric_total_width * 1.05 > metric_total_width_max:
                return

            metric_total_width *= 1.05

        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            if metric_total_width / 1.05 < metric_total_width_min:
                return

            metric_total_width /= 1.05


func _draw() -> void:
    draw_rect(Rect2(0, 0, size.x, size.y), Color(0.2, 0.2, 0.2))
    # var pointer_rect_start_pos_x := 0.0
    # if start_time >= 0:
    #     pointer_rect_start_pos_x = current_time * pixels_per_ms - half_pointer_width
    # else:
    #     pointer_rect_start_pos_x = current_time * pixels_per_ms - half_pointer_width - start_time * pixels_per_ms
    # draw_rect(Rect2(pointer_rect_start_pos_x, 0, half_pointer_width * 2.0, size.y / 6.0), Color(0.3, 0.8, 0.3))
    draw_rect(Rect2(current_time * pixels_per_ms - 4, 0, 8.0, size.y / 2.0), Color(0.3, 0.8, 0.3))
    _draw_metric(true)
    _draw_metric()


func _draw_metric(smaller: bool = false) -> void:
    var line_height := size.y / 2
    var ms_per_larger_interval := _get_larger_interval(pixels_per_ms) / 30.0 * 1000.0
    # 大间隔像素宽度
    var step := ms_per_larger_interval * pixels_per_ms
    if smaller:
        line_height /= 2.0
        step /= _get_small_interval_amount(pixels_per_ms)

    var total_intervals: int = ceil(size.x / step)
    var offset = 0.0
    if start_time >= 0:
        offset = step - fmod(start_time * pixels_per_ms, step)
    else:
        offset = - start_time * pixels_per_ms

    for i in range(total_intervals):
        draw_line(
            Vector2(i * step + offset, 0),
            Vector2(i * step + offset, line_height),
            Color.WHITE
        )

        if not smaller:
            var label_pos_x: float = i * step + offset + step / 20.0
            if label_pos_x + step * 0.3 > size.x:
                return

            draw_string(
                get_theme_default_font(),
                Vector2(label_pos_x, size.y / 2 + line_height / 4.0),
                _time_ms2str(start_time + (i * step + offset) / pixels_per_ms),
                HORIZONTAL_ALIGNMENT_LEFT,
                -1.0,
                10,
                Color.WHITE
            )


func _get_larger_interval(ppms: float) -> float:
    for i in range(pixels_per_ms_threshold.size()):
        if ppms >= pixels_per_ms_threshold[i]:
            return zoom_frames_per_interval[i]

    return zoom_frames_per_interval[-1]


func _get_small_interval_amount(ppms: float) -> float:
    var level := 0
    for i in range(pixels_per_ms_threshold.size()):
        level = i
        if ppms >= pixels_per_ms_threshold[i]:
            break

    match level:
        0:
            return 2
        1:
            return 5
        _:
            return 10


@warning_ignore_start("INTEGER_DIVISION")
func _time_ms2str(time_ms: int) -> String:
    var seconds := time_ms / 1000
    var minutes := seconds / 60
    var hours := minutes / 60
    seconds %= 60
    minutes %= 60
    if hours > 0:
        return "%02d:%02d:%02d" % [hours, minutes, seconds]
    else:
        return "%02d:%02d" % [minutes, seconds]
@warning_ignore_restore("INTEGER_DIVISION")


func set_start_time(ms: int) -> void:
    Logger.info("set_start_time: %d" % ms)
    start_time = ms
    queue_redraw()


func _on_resized() -> void:
    metric_total_width = size.x