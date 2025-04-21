class_name AntDesign
extends RefCounted

# 中性色板
const GRAY_PALETTE = [
    Color("ffffff"),
    Color("fafafa"),
    Color("f5f5f5"),
    Color("f0f0f0"),
    Color("d9d9d9"),
    Color("bfbfbf"),
    Color("8c8c8c"),
    Color("595959"),
    Color("434343"),
    Color("262626"),
    Color("1f1f1f"),
    Color("141414"),
    Color("000000"),
]

# 中性色
# Ant Design 的中性色主要被大量的应用在界面的文字部分，此外背景、边框、分割线等场景中也非常常见。产品中性色的定义需要考虑深色背景以及浅色背景的差异，同时结合 WCAG 2.0 标准。Ant Design 的中性色在落地的时候是按照透明度的方式实现的
const NEUTRAL_COLORS_BLACK_BG = {
    "title": Color("FFFFFFD9"),
    "primary_text": Color("FFFFFFD9"),
    "secondary_text": Color("FFFFFFA6"),
    "disable_text": Color("FFFFFF40"),
    "primary_border": Color("424242"),
    "divider": Color("FDFDFD1F"),
    "layout_bg": Color("141414"),
}

const NEUTRAL_COLORS_WHITE_BG = {
    "title": Color("000000E0"),
    "primary_text": Color("000000E0"),
    "secondary_text": Color("000000A6"),
    "disable_text": Color("00000040"),
    "primary_border": Color("D9D9D9"),
    "divider": Color("0505050F"),
    "layout_bg": Color("F5F5F5"),
}

# 主色
const BASIC_MAIN_COLORS = {
    "red": {
        "name": "薄暮",
        "name_en": "Dust Red",
        "tag": "斗志，奔放",
        "color": Color("f5222d"),
    },
    "volcano": {
        "name": "火山",
        "name_en": "Volcano",
        "tag": "醒目、澎湃",
        "color": Color("fa541c"),
    },
    "orange": {
        "name": "日暮",
        "name_en": "Sunset Orange",
        "tag": "温暖、欢快",
        "color": Color("fa8c16"),
    },
    "gold": {
        "name": "金盏花",
        "name_en": "Calendula Gold",
        "tag": "活力、积极",
        "color": Color("faad14"),
    },
    "yellow": {
        "name": "日出",
        "name_en": "Sunrise Yellow",
        "tag": "出生、阳光",
        "color": Color("fadb14"),
    },
    "lime": {
        "name": "青柠",
        "name_en": "Lime",
        "tag": "自然、生机",
        "color": Color("a0d911"),
    },
    "green": {
        "name": "极光绿",
        "name_en": "Polar Green",
        "tag": "健康、创新",
        "color": Color("52c41a"),
    },
    "cyan": {
        "name": "明青",
        "name_en": "Cyan",
        "tag": "希望、坚强",
        "color": Color("13c2c2"),
    },
    "blue": {
        "name": "拂晓蓝",
        "name_en": "Daybreak Blue",
        "tag": "包容、科技、普惠",
        "color": Color("1677ff"),
    },
    "geekblue": {
        "name": "极客蓝",
        "name_en": "Geek Blue",
        "tag": "探索、钻研",
        "color": Color("2f54eb"),
    },
    "purple": {
        "name": "酱紫",
        "name_en": "Golden Purple",
        "tag": "优雅、浪漫",
        "color": Color("722ed1"),
    },
    "magenta": {
        "name": "法式洋红",
        "name_en": "Magenta",
        "tag": "明快、感性",
        "color": Color("eb2f96"),
    }
}

# 品牌色
# 应用场景包括：关键行动点，操作状态、重要信息高亮，图形化等场景。
var brand_color := BASIC_MAIN_COLORS["blue"]["color"] # 6
var selected_bg_color := Color("e6f4ff") # 1
var hover_color := Color("4096ff") # 5
var normal_color := BASIC_MAIN_COLORS["blue"]["color"] # 6
var click_color := Color("0958d9") # 7

# 功能色
# 功能色代表了明确的信息以及状态，比如成功、出错、失败、提醒、链接等。功能色的选取需要遵守用户对色彩的基本认知。我们建议在一套产品体系下，功能色尽量保持一致，不要有过多的自定义干扰用户的认知体验。
var link_color := BASIC_MAIN_COLORS["blue"]["color"] # blue-6
var success_color := BASIC_MAIN_COLORS["green"]["color"] # green-6
var warning_color := BASIC_MAIN_COLORS["gold"]["color"] # gold-6
var error_color := BASIC_MAIN_COLORS["red"]["color"] # red-6

# 字体
var font_regular: FontFile = load("res://assets/fonts/ResourceHanRoundedCN-Regular.ttf")
# var font_bold: FontVariation = load("res://assets/fonts/default_bold_font.tres")
# var font_code: FontVariation = load("res://assets/fonts/default_code_font.tres")

# 字体大小
var title_font_size: int = 20
var default_font_size: int = 16
var secondary_font_size: int = 14

var default_font: Font = font_regular
var default_font_color: Color = Color.BLACK

var palette: Array

var is_dark: bool = true
var title_color: Color:
    get(): return get_neutral_color("title")
var primary_text_color: Color:
    get(): return get_neutral_color("primary_text")
var secondary_text_color: Color:
    get(): return get_neutral_color("secondary_text")
var disable_text_color: Color:
    get(): return get_neutral_color("disable_text")
var primary_border_color: Color:
    get(): return get_neutral_color("primary_border")
var divider_color: Color:
    get(): return get_neutral_color("divider")
var layout_bg_color: Color:
    get(): return get_neutral_color("layout_bg")

var gray1 := GRAY_PALETTE[0]
var gray2 := GRAY_PALETTE[1]
var gray3 := GRAY_PALETTE[2]
var gray4 := GRAY_PALETTE[3]
var gray5 := GRAY_PALETTE[4]
var gray6 := GRAY_PALETTE[5]
var gray7 := GRAY_PALETTE[6]
var gray8 := GRAY_PALETTE[7]
var gray9 := GRAY_PALETTE[8]
var gray10 := GRAY_PALETTE[9]
var gray11 := GRAY_PALETTE[10]
var gray12 := GRAY_PALETTE[11]
var gray13 := GRAY_PALETTE[12]


func _init(primary_color: Color, a_is_dark: bool = true, dark_bg_color: Color = Color("141414")):
    is_dark = a_is_dark
    var ant_palette = AntPalette.new(primary_color, a_is_dark, dark_bg_color)
    palette = ant_palette.palette

    selected_bg_color = palette[0]
    brand_color = palette[5]
    normal_color = brand_color
    hover_color = palette[6]
    click_color = palette[4]

    link_color = brand_color
    success_color = BASIC_MAIN_COLORS["green"]["color"] # green-6
    warning_color = BASIC_MAIN_COLORS["gold"]["color"] # gold-6
    error_color = BASIC_MAIN_COLORS["red"]["color"] # red-6

    if not is_dark:
        default_font_color = NEUTRAL_COLORS_WHITE_BG["primary_text"]
    else:
        default_font_color = NEUTRAL_COLORS_BLACK_BG["primary_text"]


func get_neutral_color(n: String) -> Color:
    return NEUTRAL_COLORS_BLACK_BG[n] if is_dark else NEUTRAL_COLORS_WHITE_BG[n]


class AntPalette extends RefCounted:
    const hue_step = 2 # 色相阶梯
    const saturation_step = 0.16; # 饱和度阶梯，浅色部分
    const saturation_step2 = 0.05; # 饱和度阶梯，深色部分
    const brightness_step1 = 0.05; # 亮度阶梯，浅色部分
    const brightness_step2 = 0.15; # 亮度阶梯，深色部分
    const light_color_count = 5; # 浅色数量，主色上
    const dark_color_count = 4; # 深色数量，主色下

    # 暗色主题颜色映射关系表
    const dark_color_map = [
        Vector2i(7, 15),
        Vector2i(6, 25),
        Vector2i(5, 30),
        Vector2i(5, 45),
        Vector2i(5, 65),
        Vector2i(5, 85),
        Vector2i(4, 90),
        Vector2i(3, 95),
        Vector2i(2, 97),
        Vector2i(1, 98)
    ];

    var primary: Color
    var palette: Array
    var dark: bool
    var dark_bg_color: Color = Color("141414")

    func _init(a_primary: Color, is_dark: bool = true, a_dark_bg_color: Color = Color("141414")):
        primary = a_primary
        dark = is_dark
        dark_bg_color = a_dark_bg_color
        generate_palette()

    func get_hue(c: Color, i: int, is_light: bool) -> float:
        var hue: float = c.h * 360.0
        # 根据色相(Hue)判断冷暖色
        if hue > 60.0 and hue < 240.0:
            # 冷色
            hue = hue - hue_step * i if is_light else hue + hue_step * i
        else:
            # 暖色
            hue = hue + hue_step * i if is_light else hue - hue_step * i
        if hue < 0.0:
            hue += 360.0
        elif hue >= 360.0:
            hue -= 360.0
        return roundf(hue) / 360.0

    func get_saturation(c: Color, i: int, is_light: bool) -> float:
        # 灰色饱和度不改变
        if is_zero_approx(c.h) and is_zero_approx(c.s):
            return c.s

        var saturation: float
        if is_light:
            saturation = c.s - saturation_step * i
        elif i == dark_color_count:
            saturation = c.s + saturation_step
        else:
            saturation = c.s + saturation_step2 * i

        if saturation > 1.0:
            saturation = 1.0

        # 第一格的s限制在0.06 - 0.1之间
        if is_light and i == light_color_count and saturation > 0.1:
            saturation = 0.1

        if saturation < 0.06:
            saturation = 0.06

        return roundf(saturation * 100.0) / 100.0

    func get_value(c: Color, i: int, is_light: bool) -> float:
        var value: float
        if is_light:
            value = c.v + brightness_step1 * i
        else:
            value = c.v - brightness_step2 * i
        return clampf(roundf(value * 100.0) / 100.0, 0.0, 1.0)

    func get_palette_color(c: Color, index: int) -> Color:
        var is_light = index <= 6
        var i = light_color_count + 1 - index if is_light else index - light_color_count - 1
        var hue: float
        var sat: float
        var val: float
        hue = get_hue(c, i, is_light)
        sat = get_saturation(c, i, is_light)
        val = get_value(c, i, is_light)
        return Color.from_hsv(hue, sat, val)

    func generate_palette() -> void:
        for i in range(1, 10):
            var pc = get_palette_color(primary, i)
            palette.append(pc)

        palette.insert(5, primary)

        if dark:
            var new_palette: Array = dark_color_map.map(
                func(v: Vector2i): return dark_bg_color.lerp(palette[v.x], v.y / 100.0)
            )
            palette = new_palette

        # for pc in palette:
        #     Logger.info("palette color v3: %s" % pc.to_html())
