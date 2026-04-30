Feature: Accession Edit Default Values

  Background:
    Given an administrator user is logged in
    And the Pre-populate Records option is checked in Repository Preferences
    And the user is on the Accessions page

  Scenario: Open Accession Edit Default values page
    When the user clicks on 'Edit Default Values'
    Then the Accession Record Defaults page is displayed

  Scenario: Edit Default Values
    Given the user is on the Accession Record Default page
    When the user fills in 'Title' with 'Default Test Title'
    And the user clicks on 'Save'
    Then the 'Defaults' updated message is displayed
    And the new Accession form has the following default values
      | form_section      | form_field | form_value         |
      | Basic Information | Title      | Default Test Title |

  Scenario: Archivist user cannot edit default values
    Given an archivist user is logged in
    When the user clicks on 'Browse'
    And the user clicks on 'Accessions'
    Then the 'Edit Default Values' button is not present on the page
