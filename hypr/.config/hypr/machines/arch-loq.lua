-- Lenovo LOQ 15IRX9 (hostname: arch-loq).
-- To fill in after the first boot: monitor mode and refresh rate.
return {
    gl_prefix = "",

    -- GPUs Hyprland may use (AQ_DRM_DEVICES), in order of priority.
    -- Names come from /etc/udev/rules.d/90-gpu-names.rules.
    -- Intel only: the NVIDIA can sleep (battery). Games/apps still use it
    -- with prime-run. An external monitor on the HDMI port (probably wired
    -- to the NVIDIA) needs the second line instead; then exit Hyprland
    -- (Super+M) so it starts again with the new value.
    drm_devices = "/dev/dri/intel-igpu",
    -- drm_devices = "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu",
}
