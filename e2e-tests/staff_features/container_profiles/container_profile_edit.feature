Feature: Container Profile Edit
  Background:
    Given an administrator user is logged in
      And a Container Profile has been created
  Scenario: Container Profile is opened in the edit mode from the browse menu
    Given the Container Profile appears in the search results list
     When the user clicks on 'Edit'
     Then the Container Profile is opened in the edit mode
  Scenario: Container Profile is opened in the edit mode from the view mode
    Given the Container Profile is opened in the view mode
     When the user clicks on 'Edit'
     Then the Container Profile is opened in the edit mode
  Scenario Outline: Container Profile is successfully updated
    Given the Container Profile is opened in the view mode
     When the user clicks on 'Edit'
      And the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Save'
      And the user clicks on 'Edit'
     Then the field '<Field>' has value '<NewValue>'
      Examples:
        | Field | NewValue                       |
        | Width | 10                             |
  Scenario: Container Profile is not updated after changes are reverted
    Given the Container Profile is opened in edit mode
     When the user changes the 'Name' field
      And the user clicks on 'Revert Changes'
     Then the Container Profile Name field has the original value
  Scenario: Container Profile update fails due to missing required field
    Given the Container Profile is opened in edit mode
     When the user clears the 'Name' field
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Name - Property is required but was missing |
      And the Container Profile Name field has the original value
