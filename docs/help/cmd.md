# CMD - System Integration & Command Management

Universal command integration function for package installation, dependency checking, and wrapper script creation.

## Usage

```bash
cmd <operation> [arguments...]
```

## Operations

### --check / check
Check if commands are available on the system.

```bash
cmd --check setfacl getfacl
cmd --check sudo visudo
cmd --check git curl wget
```

**Output:**
- Lists each command with availability status
- Shows full path for available commands
- Returns error code if any commands are missing

### --dependencies / dependencies
Check and install package dependencies with automatic command mapping.

```bash
cmd --dependencies acl
cmd --dependencies sudo
cmd --dependencies group
```

**Package Mappings:**
- `acl` → checks `setfacl`, `getfacl` commands
- `sudo` → checks `sudo`, `visudo` commands  
- `group` → checks `groupadd`, `usermod`, `getent` commands

**Interactive Flow:**
1. Checks if required commands are available
2. If missing, prompts user for installation permission
3. Automatically installs appropriate packages
4. Verifies installation success

### --install / install
Install packages using the system's package manager.

```bash
cmd --install acl sudo git
cmd --install "package1 package2"
```

**Supported Package Managers:**
- **apt** (Debian/Ubuntu): `sudo apt update && sudo apt install -y`
- **yum** (RHEL/CentOS): `sudo yum install -y`
- **dnf** (Fedora): `sudo dnf install -y`
- **pacman** (Arch): `sudo pacman -S --noconfirm`
- **brew** (macOS): `brew install`

**Features:**
- Auto-detects available package manager
- Batch installation support
- Progress feedback per package
- Error handling for failed installations

### --wrapper / wrapper
Create system-wide wrapper scripts for easy command access.

```bash
cmd --wrapper [name] [script_path] [pattern]
```

**Parameters:**
- `name`: Wrapper command name (default: project name)
- `script_path`: Path to source script (default: current script)
- `pattern`: Template variable pattern (default: $)

**Examples:**
```bash
cmd --wrapper helper /opt/helper/scripts/helper.sh
cmd --wrapper secure /opt/helper/scripts/secure.sh
```

**Features:**
- Creates executable wrapper in `/usr/local/bin` or `~/.local/bin`
- Template-based script generation
- Variable substitution support
- PATH configuration advice
- Automatic privilege detection

## Template Variables

Wrapper scripts support variable substitution:

- `$NAME$` → Command name
- `$SCRIPT_PATH$` → Full path to source script  
- `$VERSION$` → Script version
- Custom variables from environment

## Examples

### Basic Package Check
```bash
# Check if git is installed
cmd --check git

# Check multiple commands
cmd --check git curl wget make gcc
```

### Dependency Management
```bash
# Install ACL tools for secure.sh
cmd --dependencies acl

# Install sudo tools  
cmd --dependencies sudo
```

### Package Installation
```bash
# Install development tools
cmd --install git curl wget build-essential

# Install specific packages
cmd --install acl sudo openssh-server
```

### Wrapper Creation
```bash
# Create system-wide helper command
cmd --wrapper helper /opt/helper/scripts/helper.sh

# Create secure command wrapper
cmd --wrapper secure /opt/helper/scripts/secure.sh
```

## Return Codes

- **0**: Success
- **1**: Missing commands/packages or installation failed
- **2**: Invalid arguments or unsupported operation

## Notes

- Package installation requires appropriate privileges
- Wrapper creation may require sudo for system-wide installation
- Dependency checking uses intelligent package-to-command mapping
- All operations provide detailed feedback and error messages

## Integration

Used by other framework scripts for:
- Automatic dependency resolution
- Package installation workflows
- System integration tasks
- Command availability verification