# SSH Key Restore from LastPass

Restore SSH keys from LastPass to a new machine with one command.

## Quick Start

**If you already have LastPass CLI and are logged in:**
```bash
curl -sSL https://raw.githubusercontent.com/nixfred/lastpass-ssh-restore/main/restore-keys.sh | bash
```

**First time setup:**
```bash
# Install LastPass CLI
sudo apt install lastpass-cli  # or: brew install lastpass-cli

# Login to LastPass
lpass login your@email.com

# Run the restore script
curl -sSL https://raw.githubusercontent.com/nixfred/lastpass-ssh-restore/main/restore-keys.sh | bash
```

## Prerequisites

1. **LastPass CLI installed and logged in**
2. **SSH keys stored in LastPass** (see format below)

## Store Keys in LastPass

Add your SSH keys to LastPass notes in one of these formats:

**Option 1: Standard SSH format**
```
-----BEGIN OPENSSH PRIVATE KEY-----
[your private key content]
-----END OPENSSH PRIVATE KEY-----
ssh-ed25519 AAAAC3... your@email.com
```

**Option 2: With markers**
```
=== PRIVATE KEY ===
[your private key content]
=== PUBLIC KEY ===
ssh-ed25519 AAAAC3... your@email.com
```

## Manual Installation

```bash
# Download and run locally
curl -O https://raw.githubusercontent.com/nixfred/lastpass-ssh-restore/main/restore-keys.sh
chmod +x restore-keys.sh
./restore-keys.sh
```

## What It Does

1. Lists all SSH entries from your LastPass vault
2. Lets you select which key to restore
3. Extracts and saves keys to `~/.ssh/id_ed25519` (with proper permissions)
4. Validates the restored keys

## Test

```bash
ssh -T git@github.com
```