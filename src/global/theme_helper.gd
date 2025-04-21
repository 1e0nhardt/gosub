class_name ThemeHelper
extends RefCounted

static var empty_stylebox := StyleBoxEmpty.new()


static func add_theme_type(target_theme: Theme, type: String, opt := {}, override := false) -> void:
    if not override and type in target_theme.get_type_list():
        Logger.info("Theme type %s already exists in target theme: %s" % [type, target_theme.resource_path])
        return

    target_theme.add_type(type)
    var base_type = opt.get("base_type", "")
    if base_type != "":
        target_theme.set_type_variation(type, base_type)

    var color_settings = opt.get("color", {})
    if not color_settings.is_empty():
        for key in color_settings.keys():
            target_theme.set_color(key, type, color_settings[key])

    var constant_settings = opt.get("constant", {})
    if not constant_settings.is_empty():
        for key in constant_settings.keys():
            target_theme.set_constant(key, type, constant_settings[key])

    var font_settings = opt.get("font", {})
    if not font_settings.is_empty():
        for key in font_settings.keys():
            target_theme.set_font(key, type, font_settings[key])

    var font_size_settings = opt.get("font_size", {})
    if not font_size_settings.is_empty():
        for key in font_size_settings.keys():
            target_theme.set_font_size(key, type, font_size_settings[key])

    var icon_settings = opt.get("icon", {})
    if not icon_settings.is_empty():
        for key in icon_settings.keys():
            target_theme.set_icon(key, type, icon_settings[key])

    var stylebox_settings = opt.get("stylebox", {})
    if not stylebox_settings.is_empty():
        for key in stylebox_settings.keys():
            target_theme.set_stylebox(key, type, stylebox_settings[key])


static func generate_theme(main_color_name: String = "blue") -> void:
    var ant_design = AntDesign.new(AntDesign.BASIC_MAIN_COLORS[main_color_name]["color"])
    var main_theme = Theme.new()

    main_theme.default_font = ant_design.default_font
    main_theme.default_font_size = ant_design.default_font_size

    update_theme_common(main_theme, ant_design)
    update_theme_layout(main_theme, ant_design)
    update_theme_navigation(main_theme, ant_design)

    ResourceSaver.save(main_theme, "res://assets/theme/main_theme_%s.tres" % ("dark" if ant_design.is_dark else "light"))


static func update_theme_common(theme: Theme, ant_design: AntDesign) -> void:
    var menu_bar_stylebox := get_flat_stylebox(ant_design.gray12)
    var main_bg_stylebox := get_flat_stylebox(ant_design.gray12)

    add_theme_type(theme, "AntDesign", {
        "color": {
            "normal": ant_design.brand_color,
            "hover": ant_design.hover_color,
            "pressed": ant_design.click_color,
            "primary_text": ant_design.primary_text_color,
            "secondary_text": ant_design.secondary_text_color,
            "disabled_text": ant_design.disable_text_color,
        },
    })

    add_theme_type(theme, "Main", {
        "stylebox": {
            "menu_bar": menu_bar_stylebox,
            "main_bg": main_bg_stylebox,
        }
    })

    add_theme_type(theme, "TitleLabel", {
        "base_type": "Label",
        "color": {
            "font_color": ant_design.title_color,
        },
        "font_size": {
            "font_size": ant_design.title_font_size
        },
    })

    add_theme_type(theme, "PrimaryLabel", {
        "base_type": "Label",
        "color": {
            "font_color": ant_design.primary_text_color,
        },
        "font_size": {
            "font_size": ant_design.default_font_size
        },
    })

    add_theme_type(theme, "SecondaryLabel", {
        "base_type": "Label",
        "color": {
            "font_color": ant_design.secondary_text_color,
        },
        "font_size": {
            "font_size": ant_design.secondary_font_size
        },
    })

    var margin_stylebox = get_flat_stylebox(Color.TRANSPARENT, 0, 4)
    var normal_stylebox := get_flat_stylebox(ant_design.brand_color, 6, 4)
    var hover_stylebox := get_flat_stylebox(ant_design.hover_color, 6, 4)
    var pressed_stylebox := get_flat_stylebox(ant_design.click_color, 6, 4)

    add_theme_type(theme, "PrimaryButton", {
        "base_type": "Button",
        "color": {
            "font_color": ant_design.primary_text_color,
        },
        "stylebox": {
            "normal": normal_stylebox,
            "hover": hover_stylebox,
            "pressed": pressed_stylebox,
            "disabled": margin_stylebox,
            "focus": margin_stylebox,
        },
    })

    normal_stylebox = get_flat_bordered_stylebox(ant_design.gray3, 2, 6, 4)
    hover_stylebox = get_flat_bordered_stylebox(ant_design.hover_color, 2, 6, 4)
    pressed_stylebox = get_flat_bordered_stylebox(ant_design.click_color, 2, 6, 4)

    add_theme_type(theme, "DefaultButton", {
        "base_type": "Button",
        "color": {
            "font_color": ant_design.primary_text_color,
            "font_hover_color": ant_design.hover_color,
            "font_pressed_color": ant_design.click_color,
        },
        "stylebox": {
            "normal": normal_stylebox,
            "hover": hover_stylebox,
            "pressed": pressed_stylebox,
            "disabled": margin_stylebox,
            "focus": margin_stylebox,
        },
    })

    hover_stylebox = get_flat_stylebox(ant_design.gray9, 6, 4)
    pressed_stylebox = get_flat_stylebox(ant_design.gray10, 6, 4)

    add_theme_type(theme, "TextButton", {
        "base_type": "Button",
        "color": {
            "font_color": ant_design.primary_text_color,
        },
        "stylebox": {
            "normal": margin_stylebox,
            "hover": hover_stylebox,
            "pressed": pressed_stylebox,
            "disabled": margin_stylebox,
            "focus": margin_stylebox,
        },
    })

    hover_stylebox = get_flat_stylebox(ant_design.gray9, 6, 4)
    pressed_stylebox = get_flat_stylebox(ant_design.gray10, 6, 4)

    add_theme_type(theme, "LinkTextButton", {
        "base_type": "Button",
        "color": {
            "font_color": ant_design.brand_color,
            "font_hover_color": ant_design.hover_color,
            "font_pressed_color": ant_design.click_color,
        },
        "stylebox": {
            "normal": margin_stylebox,
            "hover": margin_stylebox,
            "pressed": margin_stylebox,
            "disabled": margin_stylebox,
            "focus": margin_stylebox,
        },
    })

    add_theme_type(theme, "IconButton", {
        "base_type": "Button",
        "color": {
            "icon_normal_color": ant_design.gray3,
            "icon_hover_color": ant_design.hover_color,
            "icon_pressed_color": ant_design.click_color,
        },
        "stylebox": {
            "normal": margin_stylebox,
            "hover": margin_stylebox,
            "pressed": margin_stylebox,
            "disabled": margin_stylebox,
            "focus": margin_stylebox,
        },
    })

    hover_stylebox = get_flat_stylebox(ant_design.gray9, 6, 4)
    pressed_stylebox = get_flat_stylebox(ant_design.gray10, 6, 4)

    add_theme_type(theme, "IconToggleButton", {
        "base_type": "Button",
        "color": {
            "icon_normal_color": ant_design.gray3,
            "icon_hover_color": ant_design.hover_color,
            "icon_hover_pressed_color": ant_design.hover_color,
            "icon_pressed_color": ant_design.gray3,
        },
        "stylebox": {
            "normal": margin_stylebox,
            "hover": margin_stylebox,
            "pressed": margin_stylebox,
            "disabled": margin_stylebox,
            "focus": margin_stylebox,
        },
    })

    var selected_stylebox := StyleBoxLineEx.new()
    selected_stylebox.color = ant_design.brand_color
    selected_stylebox.thickness = 2
    selected_stylebox.offset = 2

    add_theme_type(theme, "TabButton", {
        "base_type": "Button",
        "color": {
            "font_color": ant_design.primary_text_color,
            "font_hover_color": ant_design.brand_color,
            "font_pressed_color": ant_design.brand_color,
            "font_hover_pressed_color": ant_design.brand_color,
        },
        "stylebox": {
            "normal": margin_stylebox,
            "hover": margin_stylebox,
            "pressed": margin_stylebox,
            "disabled": margin_stylebox,
            "focus": margin_stylebox,
            "selected": selected_stylebox,
        },
    })


static func update_theme_layout(theme: Theme, ant_design: AntDesign) -> void:
    var split_bar_background_stylebox := get_flat_stylebox(ant_design.gray12)
    var placeholder_texture2d := PlaceholderTexture2D.new()

    add_theme_type(theme, "GosubSplitContainer", {
        "base_type": "SplitContainer",
        "color": {
            "font_color": ant_design.primary_text_color,
        },
        "constant": {
            "separation": 4,
            "minimum_grab_thickness": 4,
        },
        "icon": {
            "grabber": placeholder_texture2d,
            "h_grabber": placeholder_texture2d,
            "v_grabber": placeholder_texture2d,
        },
        "stylebox": {
            "split_bar_background": split_bar_background_stylebox,
        },
    })

    var tab_bar_stylebox := StyleBoxFlat.new()
    tab_bar_stylebox.bg_color = ant_design.gray11
    tab_bar_stylebox.corner_radius_top_left = 8
    tab_bar_stylebox.corner_radius_top_right = 8

    var tab_panel_stylebox := StyleBoxFlat.new()
    tab_panel_stylebox.bg_color = ant_design.gray10
    tab_panel_stylebox.corner_radius_bottom_left = 8
    tab_panel_stylebox.corner_radius_bottom_right = 8

    add_theme_type(theme, "GosubTabContainer", {
        "stylebox": {
            "tab_bar": tab_bar_stylebox,
            "tab_panel": tab_panel_stylebox,
        },
    })


static func update_theme_navigation(theme: Theme, ant_design: AntDesign) -> void:
    add_theme_type(theme, "VSteps", {
        "color": {
            "finished": ant_design.palette[6],
            "active": ant_design.brand_color,
            "wait": ant_design.gray7
        },
        "font_size": {
            "icon_font_size": 20
        }
    })


#region Util
static func get_flat_stylebox(color: Color, corner_radius: int = 0, content_margin: int = -1) -> StyleBoxFlat:
    var stylebox := StyleBoxFlat.new()
    stylebox.bg_color = color
    stylebox.set_corner_radius_all(corner_radius)
    if content_margin >= 0:
        stylebox.set_content_margin_all(content_margin)
    return stylebox


static func get_flat_bordered_stylebox(color: Color, border_width: int = 2, corner_radius: int = 0, content_margin: int = -1) -> StyleBoxFlat:
    var stylebox := StyleBoxFlat.new()
    stylebox.bg_color = Color.TRANSPARENT
    stylebox.set_corner_radius_all(corner_radius)
    stylebox.set_border_width_all(border_width)
    stylebox.border_color = color
    if content_margin >= 0:
        stylebox.set_content_margin_all(content_margin)
    return stylebox
#endregion Util