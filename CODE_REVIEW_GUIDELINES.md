# Code Review Guidelines

Guidance for reviewers of ArchivesSpace pull requests. If you want to tick items
off, copy the list into your review comment: toggling the checkboxes on this page
commits a change to this file.

- [ ] Check out the branch and run the code in a running instance of ArchivesSpace, as described in [CONTRIBUTING.md](CONTRIBUTING.md#what-happens-after-you-submit-a-pull-request). Pay particular attention to:
  - changes to the build system
  - database migrations
  - UI style changes
- [ ] Are all new user-facing strings externalized into the appropriate `en.yml` locale file (`common/locales/`, `frontend/config/locales/`, or `public/config/locales/`) rather than hard-coded, so that Weblate can pick them up for the "officially" supported languages (Dutch, English, French, German, Japanese, Spanish and Ukrainian)?
- [ ] Does documentation need to be updated, if so what?
  - Add the "user documentation needed" tag on the Jira ticket if User Manual changes are needed.
  - Add the "metadata documentation needed" tag on the Jira ticket if Metadata Documentation changes are needed.
  - If tech docs updates are needed the PR creator should also create a corresponding PR on tech-docs
- [ ] Code style:
  - descriptive and compact naming of methods, classes, files, etc.
  - level of abstraction of the implementation
    - should a bug fix be implemented in the frontend / public code or the backend?
- [ ] Accessibility: changes to the staff or public interface meet [WCAG 2.1 Level AA](https://www.w3.org/WAI/WCAG21/quickref/). Check in particular:
  - Keyboard: every new or changed control can be reached and used with the keyboard alone, and focus is visible.
  - Interactive components such as modals, menus, tabs, and comboboxes follow the matching [WAI-ARIA Authoring Practices pattern](https://www.w3.org/WAI/ARIA/apg/patterns/).
  - Names: controls, form fields, and images have names that say what they are or do, including the row or record a repeated control acts on.
  - Color: text meets contrast requirements, and information isn't shown by color alone.
  - ARIA: native HTML elements are used where possible, and ARIA only where HTML can't do the job.
  - Automated check: an axe check (`be_axe_clean`) covers new pages or components.
- [ ] Test coverage:
  - if e2e tests are added that include new step definitions:
    - could we reuse existing steps instead of introducing new ones?
      - maybe by refactoring existing steps to be more generic?
    - if not, are the steps we added generic and re-usable enough?
- [ ] Common pitfalls:
  - proxy URLs
  - mixed content
  - changes to the AppConfig
  - changes to the backend API
  - db migrations
  - changes in the build release-notes process
  - differences in prod / dev environment
    - asset pipeline
    - impact on plugins
      - not all Rails components that can be overwritten in dev env can also be overwritten in prod
  - scaling issues:
    - N+1 query issues
    - long running single threaded tasks
    - background jobs for things that could take longer than a normal HTTP request cycle
    - nested SQL joins
