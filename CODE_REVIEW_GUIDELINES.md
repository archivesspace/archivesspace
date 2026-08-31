# Code Review Guidelines

Guidance for reviewers of ArchivesSpace pull requests. If you want to tick items
off, copy the list into your review comment: toggling the checkboxes on this page
commits a change to this file.

- [ ] Check out the branch and run the code in a running instance of ArchivesSpace, as described in [CONTRIBUTING.md](CONTRIBUTING.md#what-happens-after-you-submit-a-pull-request). Pay particular attention to:
  - changes to the build system
  - database migrations
  - UI Style changes
- [ ] Are all new user-facing strings externalized into `common/locales/en.yml` rather than hard-coded, so that Weblate can pick them up for the "officially" supported languages (Dutch, English, French, German, Japanese, Spanish and Ukrainian)?
- [ ] Does documentation need to be updated, if so what?
  - Add the "user documentation needed" tag on the JIRA ticket if User Manual changes are needed.
  - Add the "metadata documentation needed" tag on the JIRA ticket if Metadata Documentation changes are needed.
  - If tech docs updates are needed the PR creator should also create a corresponding PR on tech-docs
- [ ] Code Style reviewing:
  - descriptive and compact naming of methods, classes, files, etc.
  - level of abstraction of the implementation
    - should a bug fix be implemented in the frontend / public code or the backend?
- [ ] Has accessibility been considered:
  - Keyboard navigation
    - focus management
      - opening a modal should move the focus to the modal close button
  - Screenreader access
  - color contrast
  - image alt text
  - proper ARIA usage
- [ ] Test coverage:
  - if e2e tests are added that include new step definitions:
    - could we reuse existing steps instead of introducing new ones?
      - maybe by refactoring existing steps to be more generic?
    - if not, are the steps we added generic and re-usable enough?
- [ ] Common pitfalls
  - proxy urls
  - mixed content
  - changes to the AppConfig
  - changes to the backend API
  - db migrations
  - changes in the build release-notes process
  - differences in prod / dev environment
    - asset pipeline
    - impact on plugins
      - not all rails components that can be overwritten in dev env can also be overwritten in prod
  - scaling issues:
    - n+1 query issues
    - long running single threaded tasks
    - background jobs for things that could take longer than a normal http request cycle
    - nested SQL joins
