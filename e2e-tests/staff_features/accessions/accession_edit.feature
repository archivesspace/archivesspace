Feature: Accession Edit
  Background:
    Given an administrator user is logged in
      And an Accession has been created
  Scenario: Accession is opened in the edit mode from the browse menu
    Given the Accession appears in the search results list
     When the user clicks on 'Edit'
     Then the Accession is opened in the edit mode
  Scenario: Accession is opened in the edit mode from the view mode
    Given the Accession is opened in the view mode
     When the user clicks on 'Edit'
     Then the Accession is opened in the edit mode
  Scenario Outline: Accession is successfully updated
    Given the Accession is opened in edit mode
     When the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Save'
     Then the 'Accession' updated message is displayed
     Then the field '<Field>' has value '<NewValue>'
     Examples:
      | Field    | NewValue                 |
      | Title    | Updated Test Accession   |
      | Accession Date     | 2024-10-03               |
  Scenario: Accession is not updated after changes are reverted
    Given the Accession is opened in edit mode
     When the user changes the 'Title' field
      And the user clicks on 'Revert Changes'
     Then the Accession Title field has the original value
  Scenario: Accession update fails due to invalid date input
    Given the Accession is opened in edit mode
     When the user fills in 'Accession Date' with '2024-13-15'
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Accession Date - Not a valid date  |
      And the Accession Date field has the original value
  # Scenario: Accession update succeeds for User A with a warning for other user editing it
  #   Given the Accession is opened in edit mode by User A
  #     And the Accession is opened in edit mode by User B
  #    When User A changes the 'Title' field
  #    Then User B sees a conflict message which indicates that User A is editing this record
  # Scenario: Accession update fails due to concurrent edit by another user
  #   Given the Accession is opened in edit mode by User A
  #     And the Accession is opened in edit mode by User B
  #    When User A changes the 'Title' field
  #     And User A clicks on 'Save'
  #     And User B changes the 'Title' field
  #     And User B clicks on 'Save'
  #    Then User B sees the following conflict message
  #      | Failed to save your changes - This record has been updated by another user. Please refresh the page to access the latest version.|
  Scenario: Accession update fails due to missing required field
    Given the Accession is opened in edit mode
     When the user clears the 'Identifier' field
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Identifier - Property is required but was missing |
      And the Accession Identifier field has the original value
