#!/bin/bash
# Restore SSH keys from LastPass

set -e

# Check if logged in
if ! lpass status > /dev/null 2>&1; then
    echo "ERROR: Not logged into LastPass. Run: lpass login YOUR_EMAIL"
    exit 1
fi

# List SSH entries
echo "SSH keys in LastPass:"
echo "===================="
SSH_ENTRIES=$(lpass ls | grep -i ssh | sed 's/ \[id:.*\]//')

if [ -z "$SSH_ENTRIES" ]; then
    echo "No SSH entries found"
    exit 1
fi

i=1
while IFS= read -r entry; do
    echo "[$i] $entry"
    i=$((i+1))
done <<< "$SSH_ENTRIES"
echo "[0] Quit"

# Get selection
echo ""
read -p "Enter number: " num < /dev/tty

if [ "$num" = "0" ] || [ -z "$num" ]; then
    exit 0
fi

# Get selected entry name
KEY_NAME=$(echo "$SSH_ENTRIES" | sed -n "${num}p")

if [ -z "$KEY_NAME" ]; then
    echo "Invalid selection"
    exit 1
fi

echo "Selected: $KEY_NAME"

# Create SSH directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Get the notes field
NOTES=$(lpass show "$KEY_NAME" --notes)

if [ -z "$NOTES" ]; then
    echo "ERROR: No notes found in this entry"
    exit 1
fi

# Try to extract between markers first
PRIVATE_KEY=$(echo "$NOTES" | sed -n '/-----BEGIN.*PRIVATE KEY-----/,/-----END.*PRIVATE KEY-----/p')
PUBLIC_KEY=$(echo "$NOTES" | sed -n '/ssh-/p' | head -1)

# If no standard SSH key format found, try custom markers
if [ -z "$PRIVATE_KEY" ]; then
    PRIVATE_KEY=$(echo "$NOTES" | sed -n '/=== PRIVATE KEY ===/,/=== PUBLIC KEY ===/p' | sed '1d;$d')
fi

if [ -z "$PUBLIC_KEY" ]; then
    PUBLIC_KEY=$(echo "$NOTES" | sed -n '/=== PUBLIC KEY ===/,$p' | sed '1d' | grep -v "^===" | head -1)
fi

# Check if we got the keys
if [ -z "$PRIVATE_KEY" ]; then
    echo "ERROR: Could not find private key in notes"
    echo "Notes should contain either:"
    echo "  - Standard SSH private key (-----BEGIN ... PRIVATE KEY-----)"
    echo "  - Or between === PRIVATE KEY === markers"
    exit 1
fi

# Save keys
echo "$PRIVATE_KEY" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

if [ -n "$PUBLIC_KEY" ]; then
    echo "$PUBLIC_KEY" > ~/.ssh/id_ed25519.pub
    chmod 644 ~/.ssh/id_ed25519.pub
    echo "✓ Saved both keys"
else
    # Generate public from private
    if ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub 2>/dev/null; then
        chmod 644 ~/.ssh/id_ed25519.pub
        echo "✓ Generated public key from private"
    else
        echo "⚠ Could not extract or generate public key"
    fi
fi

# Verify
if ssh-keygen -y -f ~/.ssh/id_ed25519 > /dev/null 2>&1; then
    echo "✓ Keys restored successfully"
    ssh-keygen -lf ~/.ssh/id_ed25519.pub 2>/dev/null || true
else
    echo "ERROR: Private key validation failed"
    exit 1
fi