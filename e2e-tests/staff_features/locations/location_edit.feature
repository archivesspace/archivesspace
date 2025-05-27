Feature: Location Edit
  Background:
    Given an administrator user is logged in
      And a Location has been created
  Scenario: Location is opened in the edit mode from the browse menu
    Given the Location appears in the search results list
     When the user clicks on 'Edit'
     Then the Location is opened in the edit mode
  Scenario: Location is opened in the edit mode from the view mode
    Given the Location is opened in view mode
     When the user clicks on 'Edit'
     Then the Location is opened in the edit mode
  Scenario Outline: Location is successfully updated
    Given the Location is opened in edit mode
     When the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Save'
     Then the 'Location' saved message is displayed
      And the field '<Field>' has value '<NewValue>'
      Examples:
      | Field    | NewValue      |
      | Building | Test Building |
  Scenario: Location is not updated after changes are reverted
    Given the Location is opened in edit mode
     When the user fills in 'Building' with 'New Building'
      And the user clicks on 'Revert Changes'
     Then the Location Building field has the original value
