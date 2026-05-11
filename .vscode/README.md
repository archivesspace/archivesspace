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
4. [Ruby LSP](https://marketplace.visualstudio.com/items?itemName=Shopify.ruby-lsp) (Shopify.ruby-lsp)
5. [Herb LSP - HTML+ERB Language Tools](https://marketplace.visualstudio.com/items?itemName=marcoroth.herb-lsp) (marcoroth.herb-lsp)
6. [Stylelint](https://marketplace.visualstudio.com/items?itemName=stylelint.vscode-stylelint) (stylelint.vscode-stylelint)

It's important to note that since these extensions work in tandem with the [VS Code settings file](settings.json), these settings only impact your ArchivesSpace VS Code Workspace, not your global VS Code User settings.

The extensions should now work out of the box at this point providing error messages and autocorrecting fixable errors on file save!

### Ruby LSP (language intelligence)

The [Ruby LSP](https://github.com/Shopify/ruby-lsp) extension provides go-to-definition, hover docs, completion and other language-server features for Ruby files.

ArchivesSpace runs on **JRuby**, but `ruby-lsp` itself runs under MRI Ruby. The project's root `Gemfile` cannot be evaluated under MRI (it pulls in `backend/Gemfile`, which depends on JRuby-only gems such as `asutils`), so we ship a stub Gemfile that the LSP loads instead [Gemfile-ruby-lsp](Gemfile-ruby-lsp).

Setup:

1. Install an MRI Ruby,
  - we recommend using [mise](https://mise.jdx.dev/).
  - [settings.json](settings.json) already sets `rubyLsp.rubyVersionManager` to `mise`; change the `identifier` if you use a different manager (`asdf`, `chruby`, `rbenv`, `rvm`, `none`, etc.).

2. Install the [Ruby LSP](https://marketplace.visualstudio.com/items?itemName=Shopify.ruby-lsp) extension as recommended when you open the project in VSCode.


### E2E test suite development

The configuration included in this directory should pop up a dialog on VSCode that recommends installing two extensions for working with the E2E test suite:
- [Cucumber full support extension](https://marketplace.visualstudio.com/items?itemName=alexkrechik.cucumberautocomplete)
- [Run On Save extension](https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave)

These extensions offer autocompletion of step definitions and auto formatting of feature files on save. You will need to run `bundle` in the e2e-tests directory for the necessary libraries to be installed.

Note that the included **tasks.json** gives “Cucumber: Run e2e-test” and “Cucumber: Dry Run” tasks (they use `e2e-tests/` and the documented env vars).
