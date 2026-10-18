# Custom build options for compiling Godot for web export
# https://docs.godotengine.org/en/stable/engine_details/development/compiling/compiling_for_web.html#building-export-templates
optimize ="size_extra"
platform ="web"
target ="template_release"
javascript_eval ="no"
threads ="no"

# Improves performance and decrease size, but requires at least 12-16GB RAM to export and takes way longer to
lto="full"

# Disables languages that use right to left text among other things
module_text_server_adv_enabled="no" 
module_text_server_fb_enabled="yes" 

# Physics
# Only use jolt
module_godot_physics_3d_enabled="no" 

# visual
module_hdr_enabled = "no"
module_mobile_vr_enabled = "no"

# multiplayer
module_multiplayer_enabled = "no"

# 2d
module_navigation_2d_enabled = "no"

# vr
module_openxr_enabled = "no"
module_webxr_enabled = "no"
