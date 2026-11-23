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
