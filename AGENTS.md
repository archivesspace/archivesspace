# AGENTS.md

This file provides persistent guidance for LLM coding agents working in this repository.

## Non-Negotiables

- Do not assume standard Rails test commands (`bundle exec rspec`, etc.).
- Use the project build wrapper for project tasks: `./build/run [task]`.
- Prefer focused test and lint commands for changed code before broad suites.
- Do not run destructive commands (`./build/run db:nuke`, data deletes, force pushes) unless explicitly requested.

## Quick Repo Map

- `backend/`: Sinatra API and business logic
- `frontend/`: Rails staff interface
- `public/`: Rails public interface
- `indexer/`: Solr indexing service
- `oai/`: OAI-PMH endpoint
- `common/`: shared models, schemas, utilities
- `plugins/`: extension system (`plugins/local/` for local customization)

## Core Commands

```bash
# Initial setup
./build/run bootstrap

# Dev servers
./build/run backend:devserver
./build/run frontend:devserver
./build/run public:devserver
./build/run indexer
./build/run oai:devserver

# Database
./build/run db:migrate
./build/run db:migrate:test
```

## Testing and Verification

### Focused tests (preferred while iterating)

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

### Lint/format commands

```bash
# Ruby
./build/run rubocop
./build/run rubocop -Dcorrect=true

# JS/CSS
npm run eslint:ci
npm run eslint:fix
npm run stylelint:ci
npm run stylelint:fix
npm run prettier:ci
npm run prettier:fix
```

### Change-to-validation expectations

- Backend model/API changes: run targeted backend specs.
- Frontend UI behavior changes: run targeted frontend feature specs.
- JS/CSS edits: run relevant lint/format checks for touched assets.
- Schema changes: run `./build/run db:migrate:test` and affected tests.

## Frontend Conventions

### Browser compatibility baseline

- Required: Chrome, Edge, Firefox, Safari, Chrome for Android, Safari on iOS
- Nice-to-have: Opera, Samsung Internet, Firefox for Android
- Not supported: Internet Explorer

Prefer web platform features that are at least five years old.

### JavaScript/CSS guidance

- Write vanilla JavaScript. Do not use TypeScript.
- Avoid introducing new jQuery usage unless surrounding code already depends on that pattern.
- Add JSDoc annotations to functions you touch or create.
- Write plain CSS (not Sass) for new styles unless unavoidable.

### Preferred solution order

1. HTML changes over CSS changes
2. CSS changes over JavaScript changes
3. Backend solutions over increased frontend JavaScript complexity

Use exceptions only when user experience needs are impractical to solve server-side.

## InfiniteTree Notes

- Primary modules: `frontend/app/assets/javascripts/InfiniteTree*.js`
- Primary specs: `frontend/spec/features/infinite_tree_*.rb`
- Canonical behavior reference: `LARGETREE_INIT_FLOW_CANONICAL.md`

Before changing behavior, read relevant feature specs to confirm intended behavior.

## End-to-End Tests

The end-to-end suite lives in `e2e-tests/`. Start with `e2e-tests/README.md`, which links to the canonical docs guide:

- https://docs.archivesspace.org/development/e2e_tests/
