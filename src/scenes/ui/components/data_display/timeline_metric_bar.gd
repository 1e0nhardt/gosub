@tool
class_name TimelineMetricBar
extends Control

signal current_time_changed(new_time: int)
signal zoom_factor_changed
signal zoom_level_changed

const ZOOM_FRAMES_PER_INTERVAL := [2, 5, 10, 15, 30, 60, 150, 300, 600, 900, 1800, 3600, 9000, 18000, 36000]

var metric: Metric

func _init() -> void:
    metric = Metric.new(self)
    metric.zoom_level_changed.connect(func(): zoom_level_changed.emit())


func _ready() -> void:
    metric.set_total_time(1000_000)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                var local_pos = event.position
                current_time_changed.emit(metric.calc_current_time(local_pos.x))
                queue_redraw()

        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            metric.scale_zoom(true)
            zoom_factor_changed.emit()

        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            metric.scale_zoom(false)
            zoom_factor_changed.emit()


func _draw() -> void:
    # 背景
    draw_rect(Rect2(0, 0, size.x, size.y), Color(0.2, 0.2, 0.2))
    # 刻度
    metric.draw(true)
    metric.draw()


func set_audio_stream(a_audio_stream: AudioStreamWAV) -> void:
    var audio_length = a_audio_stream.get_length() # s
    # metric.total_time = audio_length * 1000.0 # ms
    metric.set_total_time(audio_length * 1000.0)


class Metric extends RefCounted:
    signal zoom_level_changed
    # 绘制区域起点的时间值
    var start_time: int = 0
    var pixels_per_ms: float = 0.0
    # 修改大间隔时间宽度的pixels_per_ms阈值。用于控制刻度的尺度。
    var pixels_per_ms_threshold := []
    # 可以用来控制大间隔的宽度
    var base_ppms: float = 0.0001
    var zoom_level: int = -1
    var canvas_node: Control

    func _init(node: Control) -> void:
        canvas_node = node
        pixels_per_ms_threshold.resize(ZOOM_FRAMES_PER_INTERVAL.size())
        for i in range(ZOOM_FRAMES_PER_INTERVAL.size()):
            pixels_per_ms_threshold[i] = (ZOOM_FRAMES_PER_INTERVAL[-1] / ZOOM_FRAMES_PER_INTERVAL[i]) * base_ppms
        # Logger.info(pixels_per_ms_threshold, {})

    func draw(smaller: bool = false) -> void:
        var line_height := canvas_node.size.y / 2
        var ms_per_larger_interval := _get_larger_interval(pixels_per_ms) / 30.0 * 1000.0
        # 大间隔像素宽度
        var step := ms_per_larger_interval * pixels_per_ms
        if smaller:
            line_height /= 2.0
            step /= _get_small_interval_amount(pixels_per_ms)

        var total_intervals: int = ceil(canvas_node.size.x / step)
        var offset = 0.0
        if start_time >= 0:
            offset = step - fmod(start_time * pixels_per_ms, step)
        else:
            offset = - start_time * pixels_per_ms

        for i in range(total_intervals):
            canvas_node.draw_line(
                Vector2(i * step + offset, 0),
                Vector2(i * step + offset, line_height),
                Color.WHITE
            )

            if not smaller:
                var label_pos_x: float = i * step + offset + step / 20.0
                if label_pos_x + step * 0.3 > canvas_node.size.x:
                    return

                canvas_node.draw_string(
                    canvas_node.get_theme_default_font(),
                    Vector2(label_pos_x, canvas_node.size.y / 2 + line_height / 4.0),
                    _time_ms2str(start_time + (i * step + offset) / pixels_per_ms),
                    HORIZONTAL_ALIGNMENT_LEFT,
                    -1.0,
                    10,
                    Color.WHITE
                )

    func _get_larger_interval(ppms: float) -> float:
        for i in range(pixels_per_ms_threshold.size()):
            if ppms >= pixels_per_ms_threshold[i]:
                return ZOOM_FRAMES_PER_INTERVAL[i]

        return ZOOM_FRAMES_PER_INTERVAL[-1]

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
        var frames := ceili((time_ms % 1000) / 1000.0 * 30)
        if frames > 1 and frames < 29:
            return "%df" % frames
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
        start_time = ms
        canvas_node.queue_redraw()

    func set_total_time(ms: int) -> void:
        var interval_frames = ceili(ms / 1000.0 / 20 * 30)
        if interval_frames >= ZOOM_FRAMES_PER_INTERVAL[-1]:
            pixels_per_ms = pixels_per_ms_threshold[-1]
        else:
            for i in range(ZOOM_FRAMES_PER_INTERVAL.size()):
                if interval_frames < ZOOM_FRAMES_PER_INTERVAL[i]:
                    pixels_per_ms = pixels_per_ms_threshold[i]
                    zoom_level = i
                    break
        canvas_node.queue_redraw()

    func set_pixels_per_ms(ppms: float) -> void:
        pixels_per_ms = clampf(ppms, pixels_per_ms_threshold[-1], pixels_per_ms_threshold[0])

        var new_zoom_level = -1
        for i in range(pixels_per_ms_threshold.size()):
            if pixels_per_ms >= pixels_per_ms_threshold[i]:
                new_zoom_level = i
                break

        if new_zoom_level != zoom_level:
            zoom_level_changed.emit()

        canvas_node.queue_redraw()

    func scale_zoom(zoom_in: bool) -> void:
        if zoom_in:
            set_pixels_per_ms(pixels_per_ms * 1.05)
        else:
            set_pixels_per_ms(pixels_per_ms / 1.05)

    func get_zoom_factor() -> float:
        return pixels_per_ms / base_ppms

    func calc_current_time(local_pos_x: float) -> int:
        return int(start_time + local_pos_x / pixels_per_ms)

    func calc_current_time_position_x(ms: int) -> float:
        return (ms - start_time) * pixels_per_ms