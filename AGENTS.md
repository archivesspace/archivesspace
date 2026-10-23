# AGENTS.md

This file provides persistent guidance for LLM coding agents working in this repository.

Pending guidance queue: see [AGENTS_BACKLOG.md](AGENTS_BACKLOG.md).

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

### Frontend feature spec conventions

- Prefer per-example `let`/`let!` data and the narrowest applicable `before` hook for mutable repository or browser state. Avoid `before(:all)` plus instance variables for that state.
- For repository-scoped UI specs, set state in this order: `set_repo(repo)`, `login_admin`, then `select_repository(repo)`.
- Move `when`/`if`/`while` preconditions into `context` blocks and keep `it` descriptions focused on observable outcomes.
- Name `shared_examples` with gerund-first behavioral phrases so `it_behaves_like` reads naturally (for example, `validating mixed content`).
- Use `aggregate_failures` for two or more related expectations against one stable observation; keep separate actions or phases in separate contexts.
- Use `subject(:name)` when one page or element is the primary subject; use `let` for supporting data.
- Extract repeated flows into behaviorally named `shared_context`/`shared_examples`. Keep comments that explain non-obvious intent, and prefer durable behavior assertions over timing-sensitive incidental alerts.
- In Capybara assertions, prefer `visible: :visible` over `visible: true`; prefer predicate matchers or `be(true)` over `eq(true)`.

Apply these conventions while touching or refactoring specs; do not rewrite legacy specs solely for style consistency.

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

### Manual staff UI checks

For local browser verification, start `./build/run frontend:devserver` and open the staff interface (usually `http://localhost:3000`). Sign in with the local development credentials `admin` / `admin`.

## InfiniteTree Notes

- Docs index: `infinite-tree-notes/INDEX.md`
- Canonical architecture: `infinite-tree-notes/canonical/architecture.md`
- Tree realization terminology: `infinite-tree-notes/canonical/tree-realization.md`
- Remaining work checklist: `infinite-tree-notes/canonical/remaining-work.md`
- Legacy LargeTree reference: `infinite-tree-notes/legacy-largetree/init-flow.md`
- Primary modules: `frontend/app/assets/javascripts/InfiniteTree*.js`
- Primary specs: `frontend/spec/features/infinite_tree_*.rb`
- Spec layout: `frontend/spec/shared/INFINITE_TREE_SPECS.md`

Before changing behavior, read relevant feature specs to confirm intended behavior.

### InfiniteTree spec structure

- Keep behavior-first feature files as readable manifests with explicit `Resources`, `Digital Objects`, and `Classifications` contexts where a contract applies; avoid loops that hide hierarchy coverage.
- Keep hierarchy identity/capabilities in `infinite_tree_hierarchy_configs.rb`, reusable contracts in gerund-named `infinite_tree_*_shared_examples.rb` files, and shared browser interactions in `infinite_tree_interaction_helpers.rb`.
- Organize specs by state/scenario, then user-facing behavior, then edge cases. Hoist repeated setup to the narrowest enclosing context.
- Keep helper usage and argument style consistent within a file. Consolidate duplicate local helpers and repeated expectation calculations; promote helpers to `infinite_tree_interaction_helpers.rb` only when multiple spec files need them.
- Behavior specs own DOM changes, selection state, and request bodies. Toolbar/action-matrix specs own visibility, enablement, and I18n contracts.
- Remove exact cross-file duplication, but retain a minimal smoke assertion when it improves local readability. Judge refactors by mapped behavior coverage, not unchanged example counts.

## End-to-End Tests

The Cucumber end-to-end suite lives in `e2e-tests/` and is run differently from the other project specs. Run its commands from that directory, not through `./build/run`.

### Setup and application state

- Use the Ruby version declared by `e2e-tests/.ruby-version` and `e2e-tests/.tool-versions`.
- From `e2e-tests/`, install dependencies with `bundle install` (and `mise install` first when using mise).
- For local development servers, the suite expects a blank database, a blank Solr index, and default application configuration except for `AppConfig[:db_url]`. Resetting data is destructive and still requires explicit user approval.
- Start the interfaces needed by the scenarios with `./build/run frontend:devserver` and/or `./build/run public:devserver`, then verify they are reachable.
- When changing only E2E tests, `docker compose pull && docker compose up` from `e2e-tests/` can provide the latest `master` application instead of local development servers.

Set the URL for each app the scenarios will visit:

```bash
cd e2e-tests/
export STAFF_URL='http://localhost:3000'
export PUBLIC_URL='http://localhost:3001'
```

Set only the URL or URLs needed for the scenarios being run. Examples, from `e2e-tests/`:

```bash
# All staff scenarios
bundle exec cucumber staff_features/

# One feature
bundle exec cucumber staff_features/assessments/assessment_create.feature

# One named scenario in a feature
bundle exec cucumber staff_features/assessments/assessment_create.feature --name 'Assessment is created'
```

To debug Ruby steps, add a temporary `byebug` statement. To see the test browser, run with `HEADLESS=''`, for example:

```bash
bundle exec cucumber HEADLESS='' staff_features/
```

Remove all `byebug` statements before pushing.

Run the E2E suite's own linters from `e2e-tests/`:

```bash
bundle exec cuke_linter # Cucumber feature files
bundle exec rubocop     # Ruby files
```

For setup and contribution guidance, start with `e2e-tests/README.md`, which links to the canonical docs guide:

- https://docs.archivesspace.org/development/e2e_tests/
