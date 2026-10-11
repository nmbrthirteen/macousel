enum EngineChangedGolden {
  static let text = """
    # Written by Macousel. Changes made here are overwritten.

    [options]
    focus_follows_mouse = true
    mouse_follows_focus = true
    preset_column_widths = [0.3, 0.45, 0.6, 1.0]
    animation_speed = 8.0
    auto_center = true

    [padding]
    top = 15
    bottom = 15
    left = 15
    right = 15

    [swipe]
    sensitivity = 0.7

    [swipe.gesture]
    fingers_count = 3
    direction = "Reversed"
    vertical = false

    [swipe.scroll]
    modifier = "alt + fn"

    [decorations]
    workspace_menu_status = false
    workspace_popup_status = false

    [decorations.menu.descriptor]
    style = "hidden"

    [decorations.active.border]
    enabled = false
    color = "#0A84FF"
    width = 5.0
    radius = "auto"

    [decorations.inactive.dim]
    opacity = -0.35

    [restore]
    enabled = false

    [windows.all]
    title = ".*"
    horizontal_padding = 7
    vertical_padding = 7

    [windows.app_com_apple_calculator]
    bundle_id = "com.apple.Calculator"
    title = ".*"
    floating = true

    [windows.app_com_example_editor]
    bundle_id = "com.example.Editor"
    title = ".*"
    width = 0.6

    [windows.app_com_example_chat]
    bundle_id = "com.example.Chat"
    title = ".*"
    index = 2

    [windows.app_com_example_app_v2]
    bundle_id = "com.Example-App.v2"
    title = ".*"
    floating = true

    [windows.app_com_example_app_v2_2]
    bundle_id = "com.example_app.v2"
    title = ".*"
    floating = true

    [bindings]
    window_center = "alt + ctrl - c"
    window_equalize = "alt + ctrl - 0"
    window_focus_1 = "alt + ctrl - 1"
    window_focus_2 = "alt + ctrl - 2"
    window_focus_3 = "alt + ctrl - 3"
    window_focus_4 = "alt + ctrl - 4"
    window_focus_5 = "alt + ctrl - 5"
    window_focus_6 = "alt + ctrl - 6"
    window_focus_7 = "alt + ctrl - 7"
    window_focus_8 = "alt + ctrl - 8"
    window_focus_east = "alt - f5"
    window_focus_first = "alt + cmd + ctrl - leftarrow"
    window_focus_last = ["alt + cmd + ctrl - rightarrow", "alt + ctrl - 9"]
    window_focus_north = ["alt + ctrl - k", "alt + ctrl - uparrow"]
    window_focus_south = ["alt + ctrl - j", "alt + ctrl - downarrow"]
    window_focus_west = "cmd + ctrl - j"
    window_fullwidth = "alt + ctrl - f"
    window_grow = "alt + ctrl - equal"
    window_nextdisplay = "alt + ctrl - n"
    window_resize = "alt + ctrl - r"
    window_shrink = "alt + ctrl - minus"
    window_stack = ["alt + ctrl - rightbracket", "alt + ctrl - leftbracket"]
    window_swap_east = ["alt + shift + ctrl - l", "alt + shift + ctrl - rightarrow"]
    window_swap_first = "alt + shift + cmd + ctrl - leftarrow"
    window_swap_last = "alt + shift + cmd + ctrl - rightarrow"
    window_swap_north = ["alt + shift + ctrl - k", "alt + shift + ctrl - uparrow"]
    window_swap_south = ["alt + shift + ctrl - j", "alt + shift + ctrl - downarrow"]
    window_swap_west = ["alt + shift + ctrl - h", "alt + shift + ctrl - leftarrow"]
    window_tabbeddisplay = "alt + shift + ctrl - t"
    window_unstack = ["alt + shift + ctrl - leftbracket", "alt + shift + ctrl - rightbracket"]
    window_vertical_grow = "alt + shift + ctrl - equal"
    window_vertical_shrink = "alt + shift + ctrl - minus"

    """
}
