-- VirtualBox VM (hostname: arch-hyprlab).
-- No real GPU: GL apps (kitty, polkit agent) need software rendering.
return {
    gl_prefix = "env LIBGL_ALWAYS_SOFTWARE=1 ",
}