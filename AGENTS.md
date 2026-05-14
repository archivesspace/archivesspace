# AGENTS.md

This file provides persistent guidance for LLM coding agents working in this repository.

## Critical Conventions

- Do not assume standard Rails test commands (`bundle exec rspec`, etc.).
- Use the project build wrapper: `./build/run [task]`.
- Test execution uses JRuby + Ant tasks.

## Testing Commands (Use These)

```bash
# Frontend feature test file
./build/run frontend:test -Dpattern="features/infinite_tree_page_load_spec.rb"

# Frontend feature single example
./build/run frontend:test -Dpattern="features/infinite_tree_page_load_spec.rb" -Dexample='when the location hash is invalid'

# Backend single example
./build/run backend:test -Dexample="should create a resource"

# Backend single file
./build/run backend:test -Dspec=path/to/spec_file.rb
```

## Project Overview

ArchivesSpace is an open source archives information management application with a multi-component Ruby/JRuby architecture.

### Core Applications

- `backend/`: Sinatra REST API and business logic
- `frontend/`: Rails staff interface
- `public/`: Rails public interface
- `indexer/`: Solr indexing service
- `oai/`: OAI-PMH endpoint

### Shared Components

- `common/`: shared models, schemas, utilities
- `plugins/`: extension system (`plugins/local/` for local customization)
- `launcher/`: Java launcher/config for deployment

## Build and Dev Commands

```bash
# Initial setup
./build/run bootstrap

# Dev servers
./build/run backend:devserver
./build/run frontend:devserver
./build/run public:devserver
./build/run indexer
./build/run oai:devserver

# DB operations
./build/run db:migrate
./build/run db:nuke
./build/run db:migrate:test
```

## Code Quality

```bash
# Ruby
./build/run rubocop
./build/run rubocop -Dcorrect=true

# JS/CSS formatting and lint
npm run eslint:ci
npm run eslint:fix
npm run stylelint:ci
npm run stylelint:fix
npm run prettier:ci
npm run prettier:fix
```

## Architecture Notes

- Data layer uses Sequel ORM.
- JSONModel underpins shared validation/serialization.
- Search uses Apache Solr and the `indexer` service.
- Plugin loading is managed via `common/lib/plugin_manager.rb`.
- Repository scoping and multi-tenancy rules are pervasive.

## Workflow Hints

### Schema Changes

1. Add migration in `common/db/migrations/`.
2. Update backend models in `backend/app/model/`.
3. Update JSONModel schemas as needed.
4. Run relevant tests through `./build/run ...`.

### Feature Work

1. Implement backend/API changes first when needed.
2. Add frontend/public changes.
3. Update indexing behavior for searchable data.
4. Add or update tests for changed behavior.

## Internal References

- `LARGETREE_INIT_FLOW_CANONICAL.md`: canonical legacy LargeTree init/edit behavior and InfiniteTree porting notes.
