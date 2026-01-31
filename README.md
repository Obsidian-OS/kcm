# ObsidianOS KCM

A KDE System Settings (KCM) module for managing ObsidianOS, including backups, slot management, and system updates. This provides a native Plasma integration for the `obsidianctl` command-line tool.

## Features

### Backup Management
- Create new system backups to specified slots or custom directories
- Restore system from existing backups
- Delete old backups
- Browse and view details of available backups
- Automatic cleanup of old backups

### Slot Management
- Switch between active system slots (A and B)
- Perform one-time slot switches for the next boot
- Synchronize content between system slots
- Analyze differences between slots
- Check the health and integrity of system slots

### System Updates
- Update system slots from local image files (SquashFS)
- Perform network-based system updates

### Slot Environment
- Enter a chrooted environment of a specific system slot for advanced debugging or maintenance
- Verify the integrity of system slots

## Requirements

- **ObsidianOS**: This module is designed to work specifically with ObsidianOS
- **obsidianctl**: The `obsidianctl` command-line utility must be installed and accessible in your PATH
- **KDE Plasma 6**: Requires KDE Frameworks 6 and Qt 6
- **polkit**: For privilege escalation

### Build Dependencies

- CMake >= 3.22
- Extra CMake Modules (ECM) >= 6.0
- Qt 6.6+
- KDE Frameworks 6.0+
  - KCMUtils
  - KI18n
  - KCoreAddons
  - KConfig

## Building

### Using Make (Recommended)

```bash
make build
sudo make install
```

### Manual CMake Build

```bash
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr ..
make
sudo make install
```

### Arch/ObsidianOS

```bash
makepkg -si
```

## Usage

After installation, the module will appear in KDE System Settings under **Connected Devices > ObsidianOS**.

Alternatively, you can launch it directly:

```bash
systemsettings kcm_obsidianos
```

### Tabs

- **Backups**: Manage your system backups
- **Slots**: Perform operations related to system slots (switching, syncing, analysis)
- **System Updates**: Apply system updates from local files or the network
- **Slot Environment**: Access a chrooted environment of a slot or verify its integrity

Most operations require administrative privileges and will prompt for your password via `pkexec`.

## Makefile Targets

| Target      | Description                           |
|-------------|---------------------------------------|
| `all`       | Build the project (default)           |
| `configure` | Run CMake configuration               |
| `build`     | Build the project                     |
| `install`   | Install to system (requires root)     |
| `uninstall` | Remove installed files (requires root)|
| `clean`     | Remove build directory                |
| `rebuild`   | Clean and rebuild                     |
| `debug`     | Build with debug symbols              |
| `test`      | Run tests                             |
| `help`      | Show help message                     |

## License

This project is licensed under the GPL-3.0 License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Related Projects

- [obsidianctl](https://github.com/Obsidian-OS/obsidianctl) - The command-line tool this module wraps
- [obsidian-control](https://github.com/Obsidian-OS/obsidian-control) - The deprecated standalone Qt application version
