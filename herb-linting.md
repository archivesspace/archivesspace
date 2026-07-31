decisions:

1. Some rules have been set to `severity: warning` purely because refactoring existing views to pass would preent a tremendous amount of work.  By setting them to warn, we'll avoid adding new patterns like this in the future, but CI will still pass on those existing instances.  Ideally, next time we work in those files we should also fix up those existing rule violations in a warn state.

