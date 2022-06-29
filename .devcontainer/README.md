# Devcontainer

Integrate with vscode to run an ArchivesSpace development environment in Docker.

Pre-reqs:

- Visual Studio Code
- Docker
- Git

## [Use with a local repository (local files)](https://code.visualstudio.com/docs/remote/containers#_quick-start-open-an-existing-folder-in-a-container)

This method uses a locally cloned copy of ArchivesSpace. Running this way will
sync files between the host and container filesystems so your mileage may vary
on performance.

Recommended for:

- Linux (Ubuntu etc.)

Not recommneded for:

- Mac OS (although faster Intel Macs may be ok?)
- Windows (there'll be filesystem issues)

## [Use with a remote repository (volumes)](https://code.visualstudio.com/docs/remote/containers#_quick-start-open-a-git-repository-or-github-pr-in-an-isolated-container-volume)

This method uses a fresh clone of ArchivesSpace and Docker volumes. Using volumes
avoids filesystem issues but bootstrapping will be slower because the repository
has to be cloned.

Recommended for:

- All (x86)

## Secrets

Variables supported:

- REMOTE_DB_HOST
- REMOTE_DB_PORT
- REMOTE_DB_NAME
- REMOTE_DB_USER
- REMOTE_DB_PASSWORD

There are two ways to use them:

1. Create a file `.devcontainer/secrets` with variables to be exported. __Note: this
only works with a local repository container.__
2. Define them as locally available environment variables. __Note: these must be
available when vscode starts, they are not picked up through integrated terminals.__
