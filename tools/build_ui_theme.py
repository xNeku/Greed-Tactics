#!/usr/bin/env python3
"""Writes scenes/ui/theme/ui_theme.tres (v0.10 UI pass).

One palette for every screen and the battle HUD: dark ink panels with a
bronze rim and a soft shadow, gold accents, buttons that light up in gold.
Variation names are the ones the scenes already use, plus new ones for the
progression screens (RomanLevel, XpBar, Card, Chip, LockedLabel...).

python3 tools/build_ui_theme.py && godot --headless --script res://tools/resave_resources.gd
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "scenes/ui/theme/ui_theme.tres"

INK = (0.055, 0.06, 0.095, 0.96)
INK_LIGHT = (0.09, 0.095, 0.14, 0.97)
BRONZE = (0.55, 0.43, 0.24, 1.0)
GOLD = (1.0, 0.8, 0.36, 1.0)
GOLD_SOFT = (0.95, 0.78, 0.45, 1.0)
TEXT = (0.93, 0.91, 0.86, 1.0)
MUTED = (0.66, 0.66, 0.72, 1.0)


def c(rgba) -> str:
    return "Color(%g, %g, %g, %g)" % tuple(rgba)


subs: list[str] = []


def box(sid: str, bg, border=None, width=2, radius=5, margins=(14, 8, 14, 8), shadow=0, expand=0) -> str:
    lines = [f'[sub_resource type="StyleBoxFlat" id="{sid}"]']
    for side, value in zip(("left", "top", "right", "bottom"), margins):
        lines.append(f"content_margin_{side} = {float(value)}")
    lines.append(f"bg_color = {c(bg)}")
    if border is not None:
        for side in ("left", "top", "right", "bottom"):
            lines.append(f"border_width_{side} = {width}")
        lines.append(f"border_color = {c(border)}")
    for corner in ("top_left", "top_right", "bottom_right", "bottom_left"):
        lines.append(f"corner_radius_{corner} = {radius}")
    if shadow:
        lines.append("shadow_color = Color(0, 0, 0, 0.45)")
        lines.append(f"shadow_size = {shadow}")
        lines.append("shadow_offset = Vector2(0, 3)")
    if expand:
        for side in ("left", "top", "right", "bottom"):
            lines.append(f"expand_margin_{side} = {float(expand)}")
    subs.append("\n".join(lines))
    return sid


def empty(sid: str, margins=(0, 0, 0, 0)) -> str:
    lines = [f'[sub_resource type="StyleBoxEmpty" id="{sid}"]']
    for side, value in zip(("left", "top", "right", "bottom"), margins):
        lines.append(f"content_margin_{side} = {float(value)}")
    subs.append("\n".join(lines))
    return sid


box("button_normal", (0.1, 0.105, 0.155, 0.96), (0.42, 0.35, 0.22, 1), shadow=3)
box("button_hover", (0.17, 0.15, 0.1, 0.98), GOLD, shadow=4)
box("button_pressed", (0.3, 0.22, 0.08, 0.98), (1, 0.88, 0.45, 1), shadow=2)
box("button_disabled", (0.07, 0.07, 0.1, 0.8), (0.2, 0.2, 0.24, 0.8))
empty("focus")
box("panel", INK, BRONZE, margins=(16, 12, 16, 12), shadow=8)
box("preview", INK, BRONZE, margins=(12, 6, 12, 6), shadow=6)
box("top_bar", (0.04, 0.045, 0.07, 0.95), None, radius=0, margins=(16, 6, 16, 6))
box("card", INK_LIGHT, (0.32, 0.27, 0.19, 1), margins=(12, 10, 12, 10), shadow=6)
box("card_selected", (0.14, 0.12, 0.07, 0.98), GOLD, width=3, margins=(12, 10, 12, 10), shadow=10)
box("card_locked", (0.05, 0.05, 0.07, 0.9), (0.2, 0.2, 0.24, 1), margins=(12, 10, 12, 10))
box("chip", (0.16, 0.14, 0.09, 0.95), (0.5, 0.4, 0.22, 1), width=1, radius=10, margins=(10, 3, 10, 3))
box("chip_gold", (0.32, 0.24, 0.08, 0.98), GOLD, width=1, radius=10, margins=(10, 3, 10, 3))
box("banner", (0.04, 0.04, 0.06, 0.92), None, radius=0, margins=(24, 10, 24, 10))
box("bar_bg", (0.03, 0.03, 0.05, 1), (0.25, 0.22, 0.16, 1), width=1, radius=3, margins=(0, 0, 0, 0))
box("hp_fill", (0.38, 0.84, 0.48, 1), None, radius=3, margins=(0, 0, 0, 0))
box("mp_fill", (0.36, 0.6, 1, 1), None, radius=3, margins=(0, 0, 0, 0))
box("rage_fill", (0.95, 0.32, 0.25, 1), None, radius=3, margins=(0, 0, 0, 0))
box("xp_fill", (1, 0.76, 0.3, 1), None, radius=3, margins=(0, 0, 0, 0))
empty("queue", (8, 2, 8, 4))
box("queue_active", (0.26, 0.2, 0.08, 0.92), GOLD, width=1, radius=4, margins=(8, 2, 8, 2))
box("line_edit", (0.04, 0.045, 0.07, 1), (0.42, 0.35, 0.22, 1), margins=(10, 6, 10, 6))
box("separator", (0.55, 0.43, 0.24, 0.6), None, radius=0, margins=(0, 1, 0, 1))
box("tooltip", (0.04, 0.04, 0.06, 0.97), BRONZE, width=1, margins=(10, 6, 10, 6))

props = """default_font = ExtResource("1_bold")
default_font_size = 16
Button/colors/font_color = {text}
Button/colors/font_disabled_color = Color(0.42, 0.42, 0.48, 1)
Button/colors/font_focus_color = {text}
Button/colors/font_hover_color = Color(1, 0.95, 0.82, 1)
Button/colors/font_hover_pressed_color = Color(1, 0.9, 0.55, 1)
Button/colors/font_pressed_color = Color(1, 0.86, 0.45, 1)
Button/constants/h_separation = 8
Button/styles/disabled = SubResource("button_disabled")
Button/styles/focus = SubResource("focus")
Button/styles/hover = SubResource("button_hover")
Button/styles/hover_pressed = SubResource("button_pressed")
Button/styles/normal = SubResource("button_normal")
Button/styles/pressed = SubResource("button_pressed")
BigButton/base_type = &"Button"
BigButton/font_sizes/font_size = 20
BigButton/fonts/font = ExtResource("2_xbold")
CaptionLabel/base_type = &"Label"
CaptionLabel/colors/font_color = {muted}
CaptionLabel/font_sizes/font_size = 14
CaptionLabel/fonts/font = ExtResource("3_regular")
Card/base_type = &"PanelContainer"
Card/styles/panel = SubResource("card")
CardLocked/base_type = &"PanelContainer"
CardLocked/styles/panel = SubResource("card_locked")
Chip/base_type = &"PanelContainer"
Chip/styles/panel = SubResource("chip")
ChipGold/base_type = &"PanelContainer"
ChipGold/styles/panel = SubResource("chip_gold")
Banner/base_type = &"PanelContainer"
Banner/styles/panel = SubResource("banner")
GoldLabel/base_type = &"Label"
GoldLabel/colors/font_color = {gold}
GoldLabel/fonts/font = ExtResource("2_xbold")
HeaderLabel/base_type = &"Label"
HeaderLabel/colors/font_color = {gold}
HeaderLabel/font_sizes/font_size = 17
HeaderLabel/fonts/font = ExtResource("2_xbold")
HpBar/base_type = &"ProgressBar"
HpBar/styles/background = SubResource("bar_bg")
HpBar/styles/fill = SubResource("hp_fill")
HSeparator/styles/separator = SubResource("separator")
Label/colors/font_color = {text}
Label/colors/font_outline_color = Color(0.02, 0.02, 0.04, 1)
LineEdit/colors/font_color = {text}
LineEdit/colors/font_placeholder_color = Color(0.45, 0.45, 0.5, 1)
LineEdit/styles/focus = SubResource("line_edit")
LineEdit/styles/normal = SubResource("line_edit")
LockedLabel/base_type = &"Label"
LockedLabel/colors/font_color = Color(0.48, 0.48, 0.54, 1)
LockedLabel/font_sizes/font_size = 14
MessageLabel/base_type = &"Label"
MessageLabel/font_sizes/font_size = 16
MessageLabel/fonts/font = ExtResource("2_xbold")
MpBar/base_type = &"ProgressBar"
MpBar/styles/background = SubResource("bar_bg")
MpBar/styles/fill = SubResource("mp_fill")
PanelContainer/styles/panel = SubResource("panel")
PreviewPanel/base_type = &"PanelContainer"
PreviewPanel/styles/panel = SubResource("preview")
QueueEntry/base_type = &"PanelContainer"
QueueEntry/styles/panel = SubResource("queue")
QueueEntryActive/base_type = &"PanelContainer"
QueueEntryActive/styles/panel = SubResource("queue_active")
QueueLabel/base_type = &"Label"
QueueLabel/font_sizes/font_size = 15
QueueLabel/fonts/font = ExtResource("2_xbold")
RageBar/base_type = &"ProgressBar"
RageBar/styles/background = SubResource("bar_bg")
RageBar/styles/fill = SubResource("rage_fill")
ResultTitle/base_type = &"Label"
ResultTitle/colors/font_color = {gold}
ResultTitle/colors/font_outline_color = Color(0.18, 0.08, 0.02, 1)
ResultTitle/constants/outline_size = 10
ResultTitle/font_sizes/font_size = 52
ResultTitle/fonts/font = ExtResource("2_xbold")
RomanLevel/base_type = &"Label"
RomanLevel/colors/font_color = {gold}
RomanLevel/colors/font_outline_color = Color(0.2, 0.1, 0.02, 1)
RomanLevel/constants/outline_size = 6
RomanLevel/font_sizes/font_size = 30
RomanLevel/fonts/font = ExtResource("2_xbold")
SelectedCard/base_type = &"PanelContainer"
SelectedCard/styles/panel = SubResource("card_selected")
TitleLabel/base_type = &"Label"
TitleLabel/colors/font_color = {gold_soft}
TitleLabel/font_sizes/font_size = 24
TitleLabel/fonts/font = ExtResource("2_xbold")
TooltipPanel/styles/panel = SubResource("tooltip")
TopBar/base_type = &"PanelContainer"
TopBar/styles/panel = SubResource("top_bar")
XpBar/base_type = &"ProgressBar"
XpBar/styles/background = SubResource("bar_bg")
XpBar/styles/fill = SubResource("xp_fill")
""".format(text=c(TEXT), muted=c(MUTED), gold=c(GOLD), gold_soft=c(GOLD_SOFT))

header = """[gd_resource type="Theme" format=3]

[ext_resource type="FontFile" path="res://assets/fonts/Nunito-Bold.ttf" id="1_bold"]
[ext_resource type="FontFile" path="res://assets/fonts/Nunito-ExtraBold.ttf" id="2_xbold"]
[ext_resource type="FontFile" path="res://assets/fonts/Nunito-Regular.ttf" id="3_regular"]
"""
OUT.write_text(header + "\n" + "\n\n".join(subs) + "\n\n[resource]\n" + props)
print("ok", len(subs), "styles")
