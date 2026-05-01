Feature: Accession Create

  Background:
    Given an administrator user is logged in

  Scenario: Accession is created
    Given the user is on the New Accession page
    When the user fills in 'Identifier'
    And the user clicks on 'Save'
    Then the 'Accession' created message is displayed
    And the Accession is created

  Scenario: Accession is not created because required fields are missing
    Given the user is on the New Accession page
    When the user clicks on 'Save'
    Then the following error messages are displayed
      | Identifier - Property is required but was missing |

  Scenario: Accession cannot be created by user with view-only permissions
    Given a viewer user is logged in
    When the user clicks on 'Browse'
    And the user clicks on 'Accessions'
    Then the 'Create Accession' button is not present on the page
