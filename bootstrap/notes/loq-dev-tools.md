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
