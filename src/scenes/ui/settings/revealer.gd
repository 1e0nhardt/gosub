@tool
class_name Revealer
extends Container

signal expanded

const ANIMATION_ICON_DURATION := 0.1
const ANIMATION_REVEAL_DURATION := 0.24

@export var content_separation: int = 2
@export var content_margin_lr: int = 8
@export var content_margin_top: int = 8
@export var content_margin_bottom: int = 8
@export var title_panel_style: StyleBoxFlat
@export var content_panel_style: StyleBoxFlat
@export var always_expanded: bool = false

var _percent_revealed: float = 0.0:
    set(value):
        _percent_revealed = value
        update_minimum_size()
var is_expanded: bool = false:
    set(value):
        is_expanded = value
        if is_expanded:
            expanded.emit()

        if is_inside_tree() and not always_expanded:
            _toggle_capture.button_pressed = is_expanded
            _toggle_content(is_expanded)
            update_minimum_size()
var _tween: Tween

@onready var _toggle_bar: PanelContainer = $ToggleBar
@onready var _toggle_capture: Button = $ToggleBar/ToggleCapture
@onready var _label: Label = %TitleLabel
@onready var _toggle_icon: TextureRect = %Icon


func _ready() -> void:
    title_panel_style = title_panel_style.duplicate()
    content_panel_style = content_panel_style.duplicate()

    sort_children.connect(_resort)
    _toggle_capture.toggled.connect(func(toggled_on): is_expanded = true if always_expanded else toggled_on)
    if always_expanded:
        _toggle_icon.rotation_degrees = 0.0
        _percent_revealed = 1.0
        title_panel_style.corner_radius_bottom_left = 0
        title_panel_style.corner_radius_bottom_right = 0
    else:
        title_panel_style.corner_radius_bottom_left = 6
        title_panel_style.corner_radius_bottom_right = 6


func _get_minimum_size() -> Vector2:
    var final_size := Vector2.ZERO
    # title bar size
    if is_instance_valid(_toggle_bar):
        final_size = _toggle_bar.get_combined_minimum_size()

    # content size
    var content_size := Vector2.ZERO
    var first := true
    for child in get_children():
        if not child is Control or child == _toggle_bar:
            continue

        var control = child as Control
        if not control.visible:
            continue

        var control_size := control.get_combined_minimum_size()
        content_size.x = max(content_size.x, control_size.x)
        content_size.y += control_size.y

        if first:
            first = false
            content_size.y += content_margin_top
        else:
            content_size.y += content_separation

    content_size.y += content_margin_bottom
    content_size.y *= _percent_revealed

    final_size.x = max(final_size.x, content_size.x)
    final_size.y += content_size.y
    return final_size


# 每当minimum size变化时，会自动调用。
func _draw() -> void:
    if title_panel_style:
        draw_style_box(title_panel_style, Rect2(Vector2.ZERO, _toggle_bar.size))
    if content_panel_style and _percent_revealed > 0.01:
        draw_style_box(
            content_panel_style,
            Rect2(
                Vector2(0, _toggle_bar.size.y),
                Vector2(size.x, size.y - _toggle_bar.size.y)
            )
        )


func set_title(title: String) -> void:
    _label.text = title


func set_icon(icon: Texture) -> void:
    _toggle_icon.texture = icon


func set_title_color(color: Color) -> void:
    _label.add_theme_color_override("font_color", color)
    _toggle_icon.modulate = color


func set_container_color(color: Color) -> void:
    title_panel_style.bg_color = color
    content_panel_style.bg_color = color


func _toggle_content(toggled_on: bool, immediate: bool = false) -> void:
    # Just change immediately.
    if immediate:
        for child_node in get_children():
            if not child_node is Control or child_node == _toggle_bar:
                continue

            child_node.visible = toggled_on

        _toggle_icon.rotation_degrees = 90.0 * int(toggled_on)
        _percent_revealed = 1.0 * int(toggled_on)

        title_panel_style.corner_radius_bottom_left = 0 if toggled_on else 6
        title_panel_style.corner_radius_bottom_right = 0 if toggled_on else 6
        return

    if toggled_on:
        title_panel_style.corner_radius_bottom_left = 0
        title_panel_style.corner_radius_bottom_right = 0

    # https://docs.godotengine.org/en/stable/classes/class_tween.html
    # Note: Tweens are not designed to be re-used and trying to do so results in an undefined behavior. Create a new Tween for each animation and every time you replay an animation from start. Keep in mind that Tweens start immediately, so only create a Tween when you want to start animating.
    if _tween:
        _tween.kill()
    _tween = create_tween()

    for child in get_children():
        if (not child is Control) or child == _toggle_bar:
            continue

        if toggled_on:
            child.visible = true

    _tween.set_parallel()
    _tween.tween_property(_toggle_icon, "rotation_degrees", 90.0 * int(toggled_on), ANIMATION_ICON_DURATION) \
        .set_trans(Tween.TRANS_QUAD) \
        .set_ease(Tween.EASE_IN_OUT)
    _tween.tween_property(self, "_percent_revealed", float(toggled_on), ANIMATION_REVEAL_DURATION) \
        .set_trans(Tween.TRANS_QUAD) \
        .set_ease(Tween.EASE_IN_OUT)
    _tween.chain().tween_callback(func():
        if not is_expanded:
            title_panel_style.corner_radius_bottom_left = 6
            title_panel_style.corner_radius_bottom_right = 6
            queue_redraw()
            for child in get_children():
                if (not child is Control) or child == _toggle_bar:
                    continue
                child.visible = false
    )


# 将子节点宽度设为容器宽度，再用fit_child_in_rect确定子节点的尺寸，根据fit后的尺寸安排好子节点的位置。
func _resort() -> void:
    var content_offset := 0
    var base_width = get_rect().size.x

    if is_instance_valid(_toggle_bar):
        var bar_position := Vector2.ZERO
        var bar_size := _toggle_bar.get_combined_minimum_size()
        bar_size.x = base_width

        fit_child_in_rect(_toggle_bar, Rect2(bar_position, bar_size))

        content_offset = int(_toggle_bar.get_rect().size.y) + content_margin_top

    var first := true
    for child in get_children():
        if not child is Control or not child.visible:
            continue
        if child == _toggle_bar:
            continue

        var pos := Vector2.ZERO
        var child_size = child.get_combined_minimum_size()
        child_size.x = base_width

        if first:
            first = false
        else:
            content_offset += content_separation
        pos.y = content_offset

        fit_child_in_rect(child, Rect2(pos, child_size).grow_individual(-content_margin_lr, 0, -content_margin_lr, 0))
        content_offset += int(child.get_rect().size.y)
