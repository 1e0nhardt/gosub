class_name VideoEditPanel
extends PanelContainer
var audio_stream: AudioStreamWAV

var pointer_line_width: int = 2
var pointer_local_pos_x: float = 0.0:
    set(value):
        if pointer_local_pos_x == value:
            return
        pointer_local_pos_x = value
        pointer_drawer.queue_redraw()
var timeline_metric: TimelineMetricBar.Metric
var h_scroll_bar: ScrollBar

@onready var tracks_vbox: VBoxContainer = %TracksVBox
@onready var timeline_metric_bar: TimelineMetricBar = %TimelineMetricBar
@onready var tracks_view: TracksView = %TracksView
@onready var pointer_drawer: Control = %PointerDrawer
@onready var tracks_scroll_container: ScrollContainer = %TracksScrollContainer


func _ready() -> void:
    EventBus.audio_loaded.connect(_on_audio_loaded)
    timeline_metric_bar.current_time_changed.connect(_on_current_time_changed_changed)
    timeline_metric_bar.zoom_factor_changed.connect(_on_zoom_factor_changed)
    timeline_metric_bar.zoom_level_changed.connect(_on_zoom_level_changed)
    pointer_drawer.draw.connect(draw_pointer)
    h_scroll_bar = tracks_scroll_container.get_h_scroll_bar()
    h_scroll_bar.value_changed.connect(_on_h_scroll_bar_value_changed)

    timeline_metric = timeline_metric_bar.metric


func draw_pointer() -> void:
    var rel_pos = tracks_vbox.global_position - pointer_drawer.global_position
    rel_pos.x = rel_pos.x - pointer_line_width / 2.0 + pointer_local_pos_x
    pointer_drawer.draw_rect(Rect2(rel_pos, Vector2(pointer_line_width, tracks_vbox.size.y)), Color(0.2, 0.8, 0.2))


func on_process(t: float) -> void:
    pointer_local_pos_x = timeline_metric.calc_current_time_position_x(int(t * 1000))


func get_adapted_total_time() -> float:
    if audio_stream == null:
        Logger.info("No audio stream!")
        return 0.0

    return audio_stream.get_length() * 1.25 * 1000.0


func _on_audio_loaded(a_audio_stream: AudioStream) -> void:
    audio_stream = a_audio_stream
    tracks_view.set_audio_stream(audio_stream)
    tracks_view.custom_minimum_size.x = timeline_metric.pixels_per_ms * get_adapted_total_time()
    tracks_view.max_audio_waveform_width = timeline_metric.pixels_per_ms * audio_stream.get_length() * 1000


func _on_current_time_changed_changed(curr_time: int) -> void:
    pointer_local_pos_x = timeline_metric.calc_current_time_position_x(curr_time)
    EventBus.video_sought.emit(curr_time / 1000.0)
    pointer_drawer.queue_redraw()


func _on_zoom_factor_changed() -> void:
    tracks_view.custom_minimum_size.x = timeline_metric.pixels_per_ms * get_adapted_total_time()
    tracks_view.max_audio_waveform_width = timeline_metric.pixels_per_ms * audio_stream.get_length() * 1000
    pointer_drawer.queue_redraw()


func _on_zoom_level_changed() -> void:
    tracks_view.mark_waveform_dirty()


func _on_h_scroll_bar_value_changed(new_value: float) -> void:
    # -new_value 可以看做view的position.x
    var start := (new_value / tracks_view.max_audio_waveform_width) * audio_stream.get_length() * 1000
    timeline_metric.set_start_time(int(start))