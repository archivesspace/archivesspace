Feature: Resource Suppress
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Resource is suppressed
    Given the Resource is not suppressed
     When the user clicks on 'Suppress'
      And the user clicks on 'Suppress' in the modal
     Then the Resource now is suppressed
      And the Resource cannot be accessed by archivists
  Scenario: Resource is unsuppressed
    Given the Resource is suppressed
     When the user clicks on 'Unsuppress'
      And the user clicks on 'Unsuppress' in the modal
     Then the Resource now is not suppressed
      And the Resource can be accessed by archivists
