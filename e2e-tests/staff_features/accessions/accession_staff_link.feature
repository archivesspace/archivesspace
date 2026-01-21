Feature: Accession Staff Link on Public Interface

  Background:
    Given an administrator user is logged in
    And an Accession has been created

  Scenario: Staff Only button opens edit view for user with edit permissions
    When the user visits the Accession on the Public Interface
    And the user clicks on 'Staff Only' that opens in a new tab
    Then the 'Save' button is present in the new tab

  Scenario: Staff Only button opens view only for user with view-only permissions
    Given a viewer user is logged in
    When the user visits the Accession on the Public Interface
    And the user clicks on 'Staff Only' that opens in a new tab
    Then the 'Save' button is not present in the new tab

  Scenario: Staff Only button does not appear for unauthenticated user
    Given the user is logged out
    When the user visits the Accession on the Public Interface
    Then the 'Staff Only' link is not visible
