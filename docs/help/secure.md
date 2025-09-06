# Secure - Permission Management

## Description
Universal permission management function for secure file access and system operations.
Provides multiple methods for granting elevated permissions safely.

## Usage
`secure [OPERATION] [PATH] [USER] [OPTIONS]`

## Operations

### Setup Operations
- `--acl PATH [USER]`        Setup ACL (Access Control Lists) permissions
- `--group PATH [USER]`      Setup Unix group permissions
- `--sudo USER [COMMANDS]`   Setup sudo NOPASSWD for specific commands
- `--wizard [PATH] [USER]`   Interactive setup wizard

### Management Operations
- `--check [PATH] [USER]`    Analyze current permissions
- `--remove PATH [USER]`     Remove enhanced permissions

## Parameters
- `PATH`     Target directory or file (default: current directory)
- `USER`     Target user (default: current user)
- `COMMANDS` Comma-separated list of allowed commands for sudo

## Examples

### Basic Usage
```bash
# Interactive setup for current directory
secure --wizard

# Check permissions for current directory
secure --check

# Setup ACL for specific path
secure --acl /opt/myproject

# Setup for different user
secure --acl /var/www alice