@tool
class_name VSteps
extends VBoxContainer

@export var steps: Array[StepItem]
@export var icon_width: float = 36.0
@export var h_separation: int = 12
@export var text_separation: int = 6
@export var current: int = 2
@export var no_progress_index: int = 0

var circle_radius := icon_width / 2.0 * 0.8
var step_amount: int:
    get: return steps.size()
var t: float

# theme colors
var brand_color: Color
var hover_color: Color
var finished_color: Color
var active_color: Color
var wait_color: Color
var primary_text_color: Color
var secondary_text_color: Color
var disabled_text_color: Color
var icon_font_size: int = 20


func _ready() -> void:
    brand_color = get_theme_color("normal", "AntDesign")
    hover_color = get_theme_color("hover", "AntDesign")
    primary_text_color = get_theme_color("primary_text", "AntDesign")
    secondary_text_color = get_theme_color("secondary_text", "AntDesign")
    disabled_text_color = get_theme_color("disabled_text", "AntDesign")
    finished_color = get_theme_color("finished", "VSteps")
    active_color = get_theme_color("active", "VSteps")
    wait_color = get_theme_color("wait", "VSteps")
    icon_font_size = get_theme_font_size("icon_font_size")

    steps = steps.filter(func(item): return item != null)
    for item in steps:
        var step_hbox = generate_step_hbox(item)
        add_child(step_hbox)

    sort_children.connect(queue_redraw)


func _physics_process(delta: float) -> void:
    t += delta * 4.0
    queue_redraw()


func _draw() -> void:
    var v_separation := get_theme_constant("separation")
    var current_child_position_y := 0
    var icon_position := Vector2.ZERO
    icon_position.x = h_separation + icon_width / 2.0
    var icon_positions_y := []
    var index := 0

    for child in get_children():
        index += 1
        var step_hbox = child as HBoxContainer
        var icon_drawer = step_hbox.get_child(1) as Control
        var label_vbox = step_hbox.get_child(2)
        var name_label: Label = label_vbox.get_child(0)
        var desc_label = label_vbox.get_child(1)

        icon_position.y = current_child_position_y + icon_drawer.size.y / 2.0

        var circle_color: Color
        if index < current:
            name_label.add_theme_color_override("font_color", primary_text_color)
            desc_label.add_theme_color_override("font_color", secondary_text_color)
            circle_color = finished_color
        elif index == current:
            name_label.add_theme_color_override("font_color", primary_text_color)
            desc_label.add_theme_color_override("font_color", primary_text_color)
            circle_color = active_color
        else:
            name_label.add_theme_color_override("font_color", disabled_text_color)
            desc_label.add_theme_color_override("font_color", disabled_text_color)
            circle_color = wait_color

        draw_circle(icon_position, circle_radius, circle_color, true, -1, true)
        if index < current:
            # tick
            draw_polyline([
                icon_position - Vector2(circle_radius / 1.8, 0.0),
                icon_position + Vector2(-circle_radius / 8.0, circle_radius / 2.5),
                icon_position + Vector2(circle_radius / 2.0, -circle_radius / 2.0),
                ], brand_color.lerp(finished_color, 0.3), 2.0, true
            )
        else:
            var font := get_theme_default_font()
            var char_size := font.get_string_size(str(index), HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
            char_size.y *= -0.25 # ? 为什么 char_size 近乎是实际字形高度的两倍
            char_size.x *= 0.5
            draw_string(font, icon_position - char_size, str(index), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, primary_text_color)
            # var new_pos = icon_position - char_size
            # char_size.y *= -4
            # char_size.x *= 2
            # new_pos.y -= char_size.y
            # draw_rect(Rect2(new_pos, char_size), Color.RED, false, 1)

        # draw_progress
        if index == current and index != no_progress_index:
            draw_circle(icon_position, circle_radius + 3.0, disabled_text_color, false, 1.0, true)
            draw_arc(icon_position, circle_radius + 3.0, t, t + PI * 2 / 3, 8, brand_color, 1.0, true)

        current_child_position_y += step_hbox.size.y + v_separation
        icon_positions_y.append(icon_position.y)

    for i in range(1, icon_positions_y.size()):
        var line_color = brand_color if i < current else wait_color
        draw_line(
            Vector2(icon_position.x, icon_positions_y[i - 1] + (circle_radius + 4)),
            Vector2(icon_position.x, icon_positions_y[i] - (circle_radius + 4)),
            line_color, 1.0, true
        )

func generate_step_hbox(item: StepItem) -> HBoxContainer:
    var step_hbox = HBoxContainer.new()
    step_hbox.add_theme_constant_override("separation", h_separation)
    step_hbox.add_child(Control.new())

    var icon_drawer = Control.new()
    icon_drawer.custom_minimum_size.x = icon_width
    step_hbox.add_child(icon_drawer)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", text_separation)
    var name_label = Label.new()
    name_label.theme_type_variation = "PrimaryLabel"
    name_label.text = item.name
    vbox.add_child(name_label)

    var description_label = Label.new()
    description_label.theme_type_variation = "SecondaryLabel"
    description_label.text = item.description
    vbox.add_child(description_label)
    step_hbox.add_child(vbox)

    return step_hbox
