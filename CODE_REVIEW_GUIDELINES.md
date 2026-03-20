# Code Review Guidelines

- [ ] Consider running the code
- [ ] Are all locale changes for all languages included?
- [ ] Does documentation need to be updated, if so what?
        - Add the "user documentation needed" tag on the JIRA ticket if User Manual changes are needed.
        - Consider whether tech docs updates are needed.
- [ ] Code Style reviewing:
        - keep methods smaller than ?? lines
- [ ] Has accessibility been considered:
        - Keyboard navigation
        - Screenreader access
        - color contrast
        - image alt text
        - proper ARIA usage
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


