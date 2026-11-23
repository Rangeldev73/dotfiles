-- Lenovo LOQ 15IRX9 (hostname: arch-loq).
return {
    gl_prefix = "",

    -- Monitor scale. "auto" picked 1.5 on the 15.6" 1080p panel: XWayland apps
    -- (Godot, Steam) were stretched and blurry. 1 = native 1920x1080, sharp.
    -- The internal panel already runs at 144 Hz with mode "preferred".
    scale = 1,

    -- GPUs Hyprland may use (AQ_DRM_DEVICES), in order of priority.
    -- Names come from /etc/udev/rules.d/90-gpu-names.rules.
    -- Intel only: the NVIDIA can sleep (battery). Games/apps still use it
    -- with prime-run. An external monitor on the HDMI port (probably wired
    -- to the NVIDIA) needs the second line instead; then exit Hyprland
    -- (Super+M) so it starts again with the new value.
    drm_devices = "/dev/dri/intel-igpu",
    -- drm_devices = "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu",
}
