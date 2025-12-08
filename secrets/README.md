# Encrypted Secrets Storage

This directory contains encrypted secrets that are **safe to commit to GitHub**.

## 🔐 Security Model

- **Encrypted files (`.age`)**: ✅ Safe to commit to GitHub
- **Unencrypted files**: ❌ Protected by `.gitignore`, never committed
- **Encryption**: `age` with passphrase protection
- **Decryption**: Only possible with correct passphrase

## 📁 Directory Structure

```
secrets/
├── ssh/                    # Encrypted SSH keys
│   ├── id_ed25519.age     # Your encrypted keys (safe in git)
│   ├── id_rsa.age
│   └── gcloud.age
└── README.md              # This file
```

## 🚀 Quick Start

### Backup Keys (Current System)

```bash
# Encrypt your SSH keys
just ssh-backup

# Commit encrypted keys to repository
git add secrets/ssh/*.age
git commit -m "Add encrypted SSH keys backup"
git push
```

### Restore Keys (New System)

**Option 1: Automatic (during system init)**
```bash
# Clone this repository
git clone <your-repo-url>
cd nix-config

# Bootstrap will automatically prompt to restore SSH keys
just init desktop
# ↳ You'll be asked: "Restore SSH keys now? [Y/n]"
```

**Option 2: Manual (anytime)**
```bash
# Decrypt and restore keys manually
just ssh-restore

# Test keys
ssh-add -l
ssh -T git@github.com
```

## 🛠️ Commands

```bash
just ssh-backup     # Backup SSH keys (encrypt to secrets/ssh/)
just ssh-restore    # Restore SSH keys (decrypt from secrets/ssh/)
just ssh-list       # List encrypted keys
```

## 🔒 What Gets Encrypted?

The script automatically encrypts all private keys from `~/.ssh/`:
- ✅ `id_rsa`, `id_ed25519`, `id_ecdsa` (private keys)
- ✅ `gcloud`, custom key files
- ❌ `*.pub` (public keys - not sensitive)
- ❌ `known_hosts`, `config` (not sensitive)

## ⚠️ Important Notes

1. **Remember Your Passphrase**: Without it, encrypted keys cannot be restored
2. **Passphrase Strength**: Use a strong, memorable passphrase
3. **Key Rotation**: Re-encrypt keys after passphrase changes
4. **Public Keys**: Optionally commit `*.pub` files unencrypted (they're public)

## 🔄 Updating Keys

If you generate new keys or update existing ones:

```bash
# Re-encrypt with updated keys
just ssh-backup

# Commit changes
git add secrets/ssh/*.age
git commit -m "Update encrypted SSH keys"
git push
```

## 🧪 Verification

After decrypting on a new system:

```bash
# Check key permissions (should be 600)
ls -la ~/.ssh/

# Verify SSH agent
ssh-add -l

# Test GitHub access
ssh -T git@github.com

# Test other SSH connections
ssh user@your-server
```

## 🔧 Troubleshooting

### "age: command not found"
```bash
nix-shell -p age
# or add to your configuration permanently
```

### Wrong passphrase
```bash
# Try decrypting again with correct passphrase
just ssh-restore
```

### Permissions errors
```bash
# Fix SSH directory permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
```

## 📚 Additional Resources

- [age encryption tool](https://github.com/FiloSottile/age)
- [SSH key management](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
