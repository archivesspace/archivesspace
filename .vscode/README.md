# Using the VS Code editor for local development

The [settings.json](settings.json) file in this directory makes it easy for contributors using VS Code to follow the ArchivesSpace code style. Using this tool chain in your editor helps fix code format and lint errors _before_ committing files or running tests. In many cases such errors will be fixed automatically when the file being worked on is saved. Errors that can't be fixed automatically will be highlighted with squiggly lines. Hovering your mouse over these lines will display a description of the error to help reach a solution.

## Prerequisites

1. [Node.js](https://nodejs.org)
2. [Ruby](https://www.ruby-lang.org/)
3. [VS Code](https://code.visualstudio.com/)

## Set up VS Code

### Add system dependencies

1. [ESLint](https://eslint.org/)
2. [Prettier](https://prettier.io/)
3. [Rubocop](https://rubocop.org/)
4. [Stylelint](https://stylelint.io/)

#### Rubocop

```bash
gem install rubocop
```

See https://docs.rubocop.org/rubocop/installation.html for further information, including using Bundler instead of Gem.

#### ESLint, Prettier, Stylelint

Run the following command from the ArchivesSpace root directory.

```bash
npm install
```

See [package.json](../package.json) for further details on how these tools are used in ArchivesSpace.

### Add VS Code extensions

Add the following extensions via the VS Code command palette or the Extensions panel. (See this [documentation for installing and managing extensions](https://code.visualstudio.com/learn/get-started/extensions)).

1. [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) (dbaeumer.vscode-eslint)
2. [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) (esbenp.prettier-vscode)
3. [Ruby Rubocop Revised](https://marketplace.visualstudio.com/items?itemName=LoranKloeze.ruby-rubocop-revived) (LoranKloeze.ruby-rubocop-revived)
4. [Solargraph](https://marketplace.visualstudio.com/items?itemName=castwide.solargraph) (castwide.solargraph)
5. [Stylelint](https://marketplace.visualstudio.com/items?itemName=stylelint.vscode-stylelint) (stylelint.vscode-stylelint)

It's important to note that since these extensions work in tandem with the [VS Code settings file](settings.json), these settings only impact your ArchivesSpace VS Code Workspace, not your global VS Code User settings.

The extensions should now work out of the box at this point providing error messages and autocorrecting fixable errors on file save!

### Solargraph (language intelligence)

The [Solargraph](https://solargraph.org/) extension provides go-to-definition, hover docs, completion and other language-server features for Ruby files.

ArchivesSpace runs on **JRuby**, but Solargraph runs under MRI Ruby. Solargraph parses the project Gemfile via `Bundler::Dsl` to discover dependencies, but the root `Gemfile` evaluates `backend/Gemfile`, which `require 'asutils'` at parse time - and asutils is JRuby-only. To work around that without modifying the project Gemfile, this directory ships:

- [Gemfile-solargraph](Gemfile-solargraph) - a minimal stub Gemfile that lists only `solargraph` itself.
- [solargraph](solargraph) - a wrapper script that exports `BUNDLE_GEMFILE` to the stub before exec'ing the real `solargraph` binary.

`.vscode/settings.json` then sets `solargraph.commandPath` to that wrapper, and `solargraph.useBundler` to `false` so Solargraph runs from a global gem install instead of `bundle exec`.

Setup:

1. Install an MRI Ruby (we recommend [mise](https://mise.jdx.dev/)) and make sure its `bin/` directory is on the `PATH` of the shell that launches VS Code, so the wrapper can find `solargraph` via `exec`.
2. Install the [Solargraph](https://marketplace.visualstudio.com/items?itemName=castwide.solargraph) extension when prompted by VS Code. If the `solargraph` gem isn't already installed, the extension will offer to run `gem install solargraph` for you.

The stub's lockfile (`Gemfile-solargraph.lock`) is committed alongside the Gemfile, so no `bundle install` is needed on first checkout. If you ever want to refresh it, run `BUNDLE_GEMFILE=.vscode/Gemfile-solargraph bundle update`.


### E2E test suite development

The configuration included in this directory should pop up a dialog on VSCode that recommends installing two extensions for working with the E2E test suite:
- [Cucumber full support extension](https://marketplace.visualstudio.com/items?itemName=alexkrechik.cucumberautocomplete)
- [Run On Save extension](https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave)

These extensions offer autocompletion of step definitions and auto formatting of feature files on save. You will need to run `bundle` in the e2e-tests directory for the necessary libraries to be installed.

Note that the included **tasks.json** gives “Cucumber: Run e2e-test” and “Cucumber: Dry Run” tasks (they use `e2e-tests/` and the documented env vars).
