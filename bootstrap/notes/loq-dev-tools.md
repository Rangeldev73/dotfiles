# LOQ development tools: decisions and tests

Package lists: pkgs-dev.txt (official repos) and pkgs-aur.txt (AUR).
Planned order: JDK, IntelliJ (JetBrains Toolbox), VS Code (Microsoft build),
Docker (with a @docker subvolume), C/C++, .NET, Python (uv), Node.js LTS,
Godot (godot-mono), git extras, utilities, Chrome, Claude Code and Claude
Desktop, Steam (multilib, prime-run).

## Java (verified 2026-11-23)
- Official packages: jdk25-openjdk and jdk21-openjdk, with -src and -doc, maven.
- Most projects target Java 21 (Spring Boot 4.1); linkpulse uses release 25.
- Default: java-25-openjdk (the first JDK installed became the default).
  Change it with: sudo archlinux-java set java-21-openjdk
  Check: archlinux-java status
- After the first install, the new PATH needs a re-login or: source /etc/profile
- Verified: java/javac 25.0.5.1, Maven 3.10.0 running on java-25-openjdk.
- Per-project JDK is chosen in the IDE (Project Structure -> SDK).

## IntelliJ IDEA (verified 2026-11-23)
- Same setup as on Windows: JetBrains Toolbox (AUR jetbrains-toolbox) and the
  unified IntelliJ IDEA (free tier, no subscription). Since 2025.3 the free tier
  includes basic Spring support and the Spring Boot project wizard.
- Not chosen: intellij-idea-oss (official repo, open-source build with core
  features only).
- Toolbox updates itself; it and the IDEs live in ~/.local/share/JetBrains/Toolbox
  (in @home, so root snapshots and rollbacks do not touch them).
- Verified: Toolbox and IntelliJ open fine under Hyprland; no login needed.
- Logged in to the JetBrains account (2026-11-23).

## VS Code (verified 2026-11-23)
- AUR visual-studio-code-bin (Microsoft build and marketplace). Not chosen:
  code (official repo, Code - OSS with Open VSX, no Microsoft C#/C++/Pylance).
- Extensions: ~/.vscode/extensions; settings: ~/.config/Code/User.
- Extra Electron flags go in ~/.config/code-flags.conf (none needed so far).
- Verified: opens under Hyprland, sharp text, no keyring warning.
  pacman reported org.freedesktop.secrets as installed (provider not checked yet).
- Settings Sync logged in (2026-11-23), token in the keyring.

## Docker (verified 2026-11-23)
- Packages: docker, docker-compose, docker-buildx (Docker 29.10).
- Storage driver: overlayfs with the containerd image store
  (driver-type io.containerd.snapshotter.v1). Images live in
  /var/lib/containerd, volumes and containers in /var/lib/docker.
- Both folders are their own Btrfs subvolumes, so root snapshots and rollbacks
  do not hold old database blocks or images (chosen over a containerd
  config.toml root= change, or turning the containerd store off):
    @docker     -> /var/lib/docker      (ID 280)
    @containerd -> /var/lib/containerd  (ID 283)
  fstab lines copy the other Btrfs lines (same UUID and options, subvol=/@docker
  and subvol=/@containerd). Backups made: /etc/fstab.bak-docker and
  /etc/fstab.bak-containerd. Safety snapshot before the change: 15.
- Steps used (on a running system):
  1. sudo snapper -c root create --description "before @docker subvolume"
  2. mount -o subvolid=5 /dev/mapper/cryptroot /mnt; btrfs subvolume create
     /mnt/@docker (and @containerd); umount /mnt
  3. stop docker.socket docker.service containerd.service, move the old folder
     away, mkdir the mount point, append the fstab line, findmnt --verify,
     systemctl daemon-reload, mount, start docker.socket.
- Access: user in the docker group (root-equivalent; accepted on a single-user
  laptop with LUKS). Not chosen: rootless Docker, sudo docker.
- Service: docker.socket enabled, docker.service is not. Docker starts on the
  first docker command and keeps running until stopped or reboot.
  Before gaming: docker compose down in the project (frees the containers),
  or stop everything: sudo systemctl stop docker.socket docker.service containerd.service
- Verified after a reboot: both folders mounted on their subvolumes,
  docker.socket active, docker.service inactive until first use, hello-world ok.
- Note: findmnt with two paths treats them as source and target; use
  findmnt -T <path> once per path.

## C/C++ (verified 2026-11-23)
- gcc/g++ and make from base-devel; added gdb, cmake, ninja, clang (clangd,
  clang-format), valgrind. gdb was already installed (pulled by another
  package); listed explicitly anyway.
- Verified: gcc and clang++ build and run; valgrind reports a deliberate leak
  (16 bytes definitely lost); gdb stops at a breakpoint in main.
  Versions: gdb 18.1, cmake 4.5.1, ninja 1.13.2, clangd 23.1.5.

## .NET (verified 2026-11-23)
- Official dotnet-sdk 10 (SDK 10.0.114, runtime 10.0.14 in /usr/share/dotnet).
- Verified: dotnet new console + dotnet run prints Hello, World!
- First run warns "An issue was encountered verifying workloads": expected with
  the distro package, harmless (Godot needs no workloads). Do not run
  dotnet workload update (it writes to /usr/share/dotnet, owned by pacman).
- Open: Godot C# projects often target net8.0; running them may need
  dotnet-runtime-8.0 too. Check in the Godot item.
- .NET 11 SDK (2026-11-23): the game (Ypykuara) pins SDK 11.0.100 in
  global.json (its decision D-006), and Arch only ships .NET 10. Installed
  with Microsoft's script, user-local:
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    bash /tmp/dotnet-install.sh --channel 11.0 --install-dir ~/.dotnet
  bash/.bash_profile puts ~/.dotnet first on PATH and sets DOTNET_ROOT (before
  Hyprland starts, so GUI apps see it). Update: run the script again.
  When Arch packages .NET 11: remove that block and ~/.dotnet.
  Not chosen: AUR packages (only previews of 11 found, may conflict with the
  Arch .NET that godot-mono depends on); changing global.json (against D-006).
- Verified: in ~/projects/Ypykuara the game's CI steps pass with SDK 11.0.100
  (restore, build -warnaserror, format whitespace/style --verify-no-changes).

## Python (verified 2026-11-23)
- System python (3.14.10) plus uv 0.13.9. Projects: uv init / uv add / uv run;
  each project gets its own .venv. Extra Python versions and the cache live in
  ~/.local/share/uv/python and ~/.cache/uv (@home).
- Never use sudo pip install (Arch blocks global pip on purpose).
- Verified: uv init + uv add requests + uv run in /tmp.
  The "Failed to hardlink files" warning came from /tmp (tmpfs) vs the cache in
  @home; hypothesis: no warning for projects inside $HOME.

## Node.js (verified 2026-11-23)
- nodejs-lts-krypton (Node 24.22.3, "Active LTS") and npm 12.2.3.
  Not chosen: nodejs-lts-jod (Node 22, older LTS).
- TypeScript is per project (devDependency), not a system package.
- Never sudo npm install -g (global tools: set a user prefix first).
- Verified: npm install -D typescript, tsc hello.ts, node hello.js in /tmp.

## Godot (installed 2026-11-23)
- Official godot-mono 4.7.2 (same as the game), command godot-mono, uses dotnet-sdk.
- Project Manager renders with OpenGL (Compatibility). Without prime-run it
  uses the Intel iGPU; prime-run godot-mono uses the RTX 4050 (verified).
- Was blurry: it runs on XWayland and Hyprland had picked scale 1.5. Fixed with
  scale = 1 in machines/arch-loq.lua (sharp; sizes to be raised per app in
  the visual chat; Godot has its own Display Scale).
- Game (verified 2026-11-23): cloned to ~/projects/Ypykuara (git@github.com,
  no Git LFS). After a new Hyprland session (so DOTNET_ROOT is set), F5 in the
  editor builds and runs it on the Intel iGPU. No dotnet-runtime-8.0 needed:
  the net8.0 game ran with only the .NET 11 runtime in ~/.dotnet
  (hypothesis: Godot rolls forward to a newer runtime).
- First open of a fresh clone prints "Cannot open file
  res://localization/ui.*.translation": those files are generated from ui.csv
  and git-ignored, so they do not exist until the first import (harmless).
- .NET CLI telemetry turned off: DOTNET_CLI_TELEMETRY_OPTOUT=1 in bash/.bash_profile.

## Git extras and utilities (verified 2026-11-23)
- git-lfs 3.8.1 (git lfs install done for the user), gh 2.105.0 (logged in 2026-11-23:
  gh auth status shows the token in the keyring), unzip/zip, curl (already installed), jq 1.8.2, btop 1.4.8.

## Chrome and keyring (verified 2026-11-23)
- AUR google-chrome (command google-chrome-stable). Runs on Wayland natively
  (hyprctl clients: xwayland 0).
- No Secret Service was running (nothing provided org.freedesktop.secrets on
  D-Bus). Installed gnome-keyring + seahorse; the package enables
  gnome-keyring-daemon.socket for user sessions.
- Keyring created on first use with an EMPTY password (decision): with
  autologin no login password is typed, so a password would mean a prompt on
  every boot. Trade-off: while the laptop is on and unlocked, any program of
  the user can read it; at rest it is protected by LUKS.
  Test: printf ok | secret-tool store --label=test app test;
        secret-tool lookup app test; secret-tool clear app test
- Chrome and VS Code are told to use it (stow packages chrome and vscode):
  --password-store=gnome-libsecret in ~/.config/chrome-flags.conf and
  ~/.config/code-flags.conf (read by the AUR launchers).

## Logins (verified 2026-11-23)
- Google in Chrome, JetBrains (Toolbox), VS Code Settings Sync and gh
  (gh auth login: GitHub.com, SSH, skip key upload, web browser).
- gh auth status: "Logged in to github.com account Rangeldev73 (keyring)";
  seahorse lists the entries.
- To check after the next reboot: the empty-password keyring opens by itself
  (no prompt) and the logins are still there.

## Claude Code and Claude Desktop (2026-11-23)
- Claude Code: official native installer (curl -fsSL https://claude.ai/install.sh | bash),
  version 2.1.330, launcher ~/.local/bin/claude, updates itself.
  ~/.local/bin was not on PATH: added in bash/.bash_profile (not ~/.bashrc as
  the installer suggests: .bashrc is not versioned and is read after Hyprland).
- Claude Desktop: AUR claude-desktop 6.28899.6 (not maintained by Anthropic).
  PKGBUILD reviewed before installing (yay -G claude-desktop):
  - source: Anthropic's APT pool https://downloads.claude.ai/claude-desktop/apt/stable/...
    with pinned sha256sums;
  - extra file claude-desktop.sh: launcher that reads
    ~/.config/claude-desktop-flags.conf and adds --ozone-platform=wayland on
    Wayland, then execs /usr/lib/claude-desktop/claude-desktop;
  - no install= hook;
  - depends on qemu-system-x86 + edk2-ovmf: Cowork runs its sandbox in a QEMU VM
    (PKGBUILD comment: upstream lists them under Recommends).
  Flags file (stow package claude): --password-store=gnome-libsecret.
