enum EngineDefaultGolden {
  static let text = """
    # Written by Macousel. Changes made here are overwritten.

    [options]
    focus_follows_mouse = false
    mouse_follows_focus = false
    preset_column_widths = [0.25, 0.33333, 0.5, 0.66667, 0.75]
    animation_speed = 20.0
    auto_center = false

    [padding]
    top = 4
    bottom = 4
    left = 4
    right = 4

    [swipe]
    sensitivity = 0.35

    [swipe.gesture]
    direction = "Natural"
    vertical = false

    [swipe.scroll]
    modifier = "ctrl + alt"

    [decorations]
    workspace_menu_status = false
    workspace_popup_status = false

    [decorations.menu.descriptor]
    style = "hidden"

    [decorations.active.border]
    enabled = true
    color = "#0A84FF"
    width = 3.0
    radius = "auto"

    [decorations.inactive.dim]
    opacity = 0.0

    [restore]
    enabled = true

    [windows.all]
    title = ".*"
    horizontal_padding = 4
    vertical_padding = 4
    width = 0.5

    [windows.app_com_apple_systempreferences]
    bundle_id = "com.apple.systempreferences"
    title = ".*"
    floating = true

    [windows.app_com_apple_calculator]
    bundle_id = "com.apple.calculator"
    title = ".*"
    floating = true

    [windows.app_com_apple_activitymonitor]
    bundle_id = "com.apple.ActivityMonitor"
    title = ".*"
    floating = true

    [windows.app_com_apple_stickies]
    bundle_id = "com.apple.Stickies"
    title = ".*"
    floating = true

    [windows.app_com_apple_digitalcolormeter]
    bundle_id = "com.apple.DigitalColorMeter"
    title = ".*"
    floating = true

    [windows.app_com_apple_archiveutility]
    bundle_id = "com.apple.archiveutility"
    title = ".*"
    floating = true

    [windows.app_com_apple_facetime]
    bundle_id = "com.apple.FaceTime"
    title = ".*"
    floating = true

    [windows.app_com_apple_photobooth]
    bundle_id = "com.apple.PhotoBooth"
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
    window_focus_east = ["alt + ctrl - l", "alt + ctrl - rightarrow"]
    window_focus_first = "alt + cmd + ctrl - leftarrow"
    window_focus_last = ["alt + cmd + ctrl - rightarrow", "alt + ctrl - 9"]
    window_focus_north = ["alt + ctrl - k", "alt + ctrl - uparrow"]
    window_focus_south = ["alt + ctrl - j", "alt + ctrl - downarrow"]
    window_focus_west = ["alt + ctrl - h", "alt + ctrl - leftarrow"]
    window_fullwidth = "alt + ctrl - f"
    window_grow = "alt + ctrl - equal"
    window_manage = "alt + ctrl - t"
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
