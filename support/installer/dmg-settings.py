import os.path

app = defines["app"]
name = os.path.basename(app)

format = "UDZO"
filesystem = "HFS+"
files = [app]
symlinks = {"Applications": "/Applications"}
icon = defines["icon"]
background = defines["background"]

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

window_rect = ((200, 120), (660, 400))
default_view = "icon-view"
show_icon_preview = False
include_icon_view_settings = True
icon_size = 128
text_size = 13
arrange_by = None
label_pos = "bottom"

icon_locations = {
    name: (165, 186),
    "Applications": (495, 186),
}
