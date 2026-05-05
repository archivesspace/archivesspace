Feature: Acccession Publish
  Background:
    Given an administrator user is logged in
    And an Accession has been created
  Scenario: Publish the Accession record from the Publish checkbox in the Basic Information section
    Given the Accession is opened in edit mode
    When the user checks 'Publish'
    And the user clicks on 'Save'
    Then the 'Accession' updated message is displayed
    And the 'View Published' button is displayed
