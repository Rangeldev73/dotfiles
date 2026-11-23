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
- To do: log in to the JetBrains account after Chrome is installed.

## VS Code (verified 2026-11-23)
- AUR visual-studio-code-bin (Microsoft build and marketplace). Not chosen:
  code (official repo, Code - OSS with Open VSX, no Microsoft C#/C++/Pylance).
- Extensions: ~/.vscode/extensions; settings: ~/.config/Code/User.
- Extra Electron flags go in ~/.config/code-flags.conf (none needed so far).
- Verified: opens under Hyprland, sharp text, no keyring warning.
  pacman reported org.freedesktop.secrets as installed (provider not checked yet).
- To do: Settings Sync login after Chrome is installed.

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

## Python (verified 2026-11-23)
- System python (3.14.10) plus uv 0.13.9. Projects: uv init / uv add / uv run;
  each project gets its own .venv. Extra Python versions and the cache live in
  ~/.local/share/uv/python and ~/.cache/uv (@home).
- Never use sudo pip install (Arch blocks global pip on purpose).
- Verified: uv init + uv add requests + uv run in /tmp.
  The "Failed to hardlink files" warning came from /tmp (tmpfs) vs the cache in
  @home; hypothesis: no warning for projects inside $HOME.
