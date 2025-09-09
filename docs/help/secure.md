# Universal Permission Management Function

## Description

The `secure` function provides comprehensive security and permission management for files and directories using ACL (Access Control Lists), Unix groups, and sudo configurations.

## Usage

```bash
secure [OPERATION] [PATH] [USER] [OPTIONS]
```

## Operations

### Basic Operations

- `--acl PATH [USER]`	Setup ACL permissions for user
- `--group PATH [USER]`	Setup Unix group permissions  
- `--sudo USER [COMMANDS]`	Setup sudo NOPASSWD for commands
- `--check [PATH] [USER]`	Analyze current permissions
- `--wizard [PATH] [USER]`	Interactive permission setup
- `--remove PATH [USER]`	Remove enhanced permissions

### Help and Information

- `--help, -h`	Show this help message

## Methods

### ACL (Access Control Lists) - Recommended

Provides fine-grained file permissions without changing ownership:

```bash
secure --acl /opt/project myuser
```

**Advantages:**
- No ownership changes required
- User-specific permissions
- Preserves existing permissions
- Works with existing groups

### Group Permissions

Creates or uses Unix groups for permission management:

```bash
secure --group /opt/project myuser
```

**Process:**
- Creates admin group if needed
- Adds user to group
- Sets group ownership and permissions
- Requires re-login for group changes

### sudo NOPASSWD

Configures passwordless sudo for specific commands:

```bash
secure --sudo myuser "/usr/bin/rsync,/usr/bin/cp"
```

**Security Note:** Use with caution - least secure option

## Interactive Wizard

The wizard provides guided setup with security recommendations:

```bash
secure --wizard /opt/project myuser
```

**Options:**
1. ACL - File Access Control Lists (recommended)
2. Group - Unix group permissions
3. sudo - NOPASSWD for commands (least secure)
4. Check - Analyze current permissions
0. Cancel

## Permission Analysis

Check current permissions and security status:

```bash
secure --check /opt/project myuser
```

**Displays:**
- Read/Write/Execute permissions
- ACL status for user
- Group memberships
- sudo NOPASSWD entries

## Examples

### Setup ACL for project directory
```bash
secure --acl /opt/helper developer
```

### Create group-based permissions
```bash
secure --group /opt/data webuser
```

### Allow specific sudo commands
```bash
secure --sudo backupuser "/usr/bin/rsync,/usr/bin/tar"
```

### Remove all enhanced permissions
```bash
secure --remove /opt/project olduser
```

## Security Best Practices

### Recommended Order
1. **ACL** - Most flexible and secure
2. **Group** - Good for team access
3. **sudo** - Only for specific commands

### Security Considerations
- ACL preserves existing ownership
- Group permissions affect all group members
- sudo NOPASSWD should be limited to specific commands
- Always verify permissions after setup
- Remove unused permissions regularly

## System Requirements

### ACL Support
- `acl` package installed
- Filesystem mounted with ACL support
- `setfacl` and `getfacl` commands available

### Group Management
- `groupadd` and `usermod` commands
- Administrative privileges (sudo)

### sudo Configuration
- `sudo` package installed
- `/etc/sudoers.d/` directory writable
- `visudo` for validation

## Troubleshooting

### ACL Issues
- Check if filesystem supports ACL: `mount | grep acl`
- Install ACL tools: `sudo apt-get install acl`
- Remount with ACL: `mount -o remount,acl /`

### Group Issues
- User must re-login for group changes
- Check group membership: `groups username`
- Verify group exists: `getent group groupname`

### sudo Issues
- Configuration files in `/etc/sudoers.d/`
- Test with: `sudo -l -U username`
- Validate syntax: `sudo visudo -c`

## Return Codes

- `0` - Success
- `1` - Error (invalid operation, permission denied, etc.)

## Notes

- Always test permissions after setup
- Use `secure --check` to verify configuration
- Consider security implications of each method
- Remove unused permissions regularly
- ACL is recommended for most use cases