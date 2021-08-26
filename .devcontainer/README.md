# Devcontainer

Integrate with vscode to run an ArchivesSpace development environment in Docker.

## Secrets

Create a file `.devcontainer/secrets` with variables to be exported:

```bash
export REMOTE_DB_HOST=host
export REMOTE_DB_PORT=port
export REMOTE_DB_NAME=name
export REMOTE_DB_USER=user
export REMOTE_DB_PASSWORD=password
```
