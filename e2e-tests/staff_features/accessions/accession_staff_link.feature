Feature: Accession Staff Link on Public Interface

  Background:
    Given an administrator user is logged in
      And an Accession has been created
      And the Accession ID is recorded

  Scenario: Staff Only button appears for user with edit permissions
    When the user visits the Accession on the Public Interface
      And the user waits for the page to update
    Then the Staff Only button is displayed
      And the Staff Only button opens the edit page

  Scenario: Staff Only button appears for user with view-only permissions
    Given the user is logged out
      And a viewer user is logged in
    When the user visits the Accession on the Public Interface
      And the user waits for the page to update
    Then the Staff Only button is displayed
      And the Staff Only button opens the readonly page

  Scenario: Staff Only button does not appear for unauthenticated user
    Given the user is logged out
    When the user visits the Accession on the Public Interface
      And the user waits for the page to update
    Then the Staff Only button is not displayed
