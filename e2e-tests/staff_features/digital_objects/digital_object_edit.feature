Feature: Digital Object Edit
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
  Scenario: Digital Object is opened in the edit mode from the browse menu
    Given the Digital Object appears in the search results list
     When the user clicks on 'Edit'
     Then the Digital Object is opened in the edit mode
  Scenario: Digital Object is opened in the edit mode from the view mode
    Given the Digital Object is opened in the view mode
     When the user clicks on 'Edit'
     Then the Digital Object is opened in the edit mode
  Scenario Outline: Digital Object is successfully updated
    Given the Digital Object is opened in edit mode
     When the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Save'
     Then the 'Digital Object' updated message is displayed
      And the field '<Field>' has value '<NewValue>'
        Examples:
          | Field               | NewValue                    |
          | Title               | Updated Test Digital Object |
          | Digital Object Type | Mixed Materials             |
  Scenario: Digital Object is not updated after changes are reverted
    Given the Digital Object is opened in edit mode
     When the user changes the 'Title' field
      And the user clicks on 'Revert Changes'
     Then the Digital Object Title field has the original value
  Scenario: Digital Object update fails due to invalid date input
    Given the Digital Object is opened in edit mode
     When the user fills in 'Begin' with '2024-13-15' in the 'Dates' form
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Begin - Not a valid date |
  Scenario: Digital Object update fails due to missing required field
    Given the Digital Object is opened in edit mode
     When the user clears the 'Identifier' field
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Identifier - Property is required but was missing |
      And the Digital Object Identifier field has the original value
