# Devcontainer

Integrate with vscode to run an ArchivesSpace development environment in Docker.

Pre-reqs:

- Visual Studio Code
- Docker
- Git

When you run an ArchivesSpace devcontainer for the first time VS code will
download the required container images so the initial setup will take a few
minutes to complete. It should be fast to start anytime after that.

Whenever a _new_ container is started there are some preliminary setup steps
run to start the database server and Solr and bootstrap ArchivesSpace. When
this is done the first time it will also take a couple of minutes to complete,
however it will likewise be faster on subsequent runs (particularly if using a
local repository). In every case gems are persisted in a Docker volume to
speed up bootstrapping (`archivesspace-gems`).

If you restart a stopped container the setup steps are not rerun. There is an
alias command `srv` that can be used to restart the database and Solr servers.

## [Use with a local repository](https://code.visualstudio.com/docs/remote/containers#_quick-start-open-an-existing-folder-in-a-container)

This method uses a locally cloned copy of ArchivesSpace. Running this way will
sync files between the host and container filesystems so your mileage may vary
on performance.

Good for:

- Linux (Ubuntu etc.)
- Mac OS

Not recommneded for:

- Windows (there'll be filesystem issues -- TODO: check if those have been fixed)

## [Use with a remote repository](https://code.visualstudio.com/docs/remote/containers#_quick-start-open-a-git-repository-or-github-pr-in-an-isolated-container-volume)

This method uses a fresh clone of ArchivesSpace and is a fully self contained
environment that does not require a local copy of the ArchivesSpace source
repository. This avoids filesystem issues but bootstrapping will be slower
because the repository has to be cloned in addition to the other setup steps
that are performed.

This is currently the only way to develop using Windows OS.

Good for:

- All
