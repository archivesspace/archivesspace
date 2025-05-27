Feature: Accession Suppress
  Background:
    Given an administrator user is logged in
      And an Accession has been created
      And the Accession is opened in edit mode
  Scenario: Accession is suppressed
    Given the Accession is not suppressed
     When the user clicks on 'Suppress'
      And the user clicks on 'Suppress' in the modal
     Then the Accession now is suppressed
      And the Accession cannot be accessed by archivists
  Scenario: Accession is unsuppressed
    Given the Accession is suppressed
     When the user clicks on 'Unsuppress'
      And the user clicks on 'Unsuppress' in the modal
     Then the Accession now is not suppressed
      And the Accession can be accessed by archivists
