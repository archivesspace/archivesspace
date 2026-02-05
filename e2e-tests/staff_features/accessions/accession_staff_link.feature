Feature: Accession Staff Link on Public Interface

  Background:
    Given an administrator user is logged in
    And an Accession has been created

  Scenario: Staff Only button appears for user with edit permissions
    When the user visits the Accession on the Public Interface
    And the user waits for the page to update
    Then the 'Staff Only' link is 'displayed'
    And the 'Staff Only' link opens a new tab with 'edit' access

  Scenario: Staff Only button appears for user with view-only permissions
    Given a viewer user is logged in
    When the user visits the Accession on the Public Interface
    And the user waits for the page to update
    Then the 'Staff Only' link is 'displayed'
    And the 'Staff Only' link opens a new tab with 'readonly' access

  Scenario: Staff Only button does not appear for unauthenticated user
    Given the user is logged out
    When the user visits the Accession on the Public Interface
    And the user waits for the page to update
    Then the 'Staff Only' link is 'not displayed'
