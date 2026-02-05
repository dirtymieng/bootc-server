# SSH Configuration

Place your `authorized_keys` file here.

**Important:** This file is listed in `.gitignore` by default to avoid accidentally committing your public keys to a public repository.

If you want to version control your authorized_keys:
1. Remove `config/ssh/authorized_keys` from `.gitignore`
2. Ensure your repository is private
3. Only include public keys (never private keys)

Example `authorized_keys`:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqfk... user@laptop
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7... user@desktop
```
