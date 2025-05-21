Feature: Digital Object Suppress
  Background:
    Given an administrator user is logged in
     And a Digital Object has been created
     And the Digital Object is opened in edit mode
  Scenario: Digital Object is suppressed
    Given the Digital Object is not suppressed
     When the user clicks on 'Suppress'
      And the user clicks on 'Suppress' in the modal
     Then the Digital Object now is suppressed
      And the Digital Object cannot be accessed by archivists
  Scenario: Digital Object is unsuppressed
    Given the Digital Object is suppressed
     When the user clicks on 'Unsuppress'
      And the user clicks on 'Unsuppress' in the modal
     Then the Digital Object now is not suppressed
      And the Digital Object can be accessed by archivists
