Feature: Resource Edit
  Background:
    Given an administrator user is logged in
      And a Resource has been created
  Scenario: Resource is opened in the edit mode from the browse menu
    Given the Resource appears in the search results list
     When the user clicks on 'Edit'
     Then the Resource is opened in the edit mode
  Scenario: Resource is opened in the edit mode from the view mode
    Given the Resource is opened in the view mode
     When the user clicks on 'Edit'
     Then the Resource is opened in the edit mode
  Scenario Outline: Resource is successfully updated
    Given the Resource is opened in edit mode
     When the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Save'
     Then the 'Resource' updated message is displayed
     Then the field '<Field>' has value '<NewValue>'
      Examples:
       | Field | NewValue              |
       | Title | Updated Test Resource |
  Scenario: Resource is not updated after changes are reverted
    Given the Resource is opened in edit mode
     When the user changes the 'Title' field
      And the user clicks on 'Revert Changes'
     Then the Resource Title field has the original value
  Scenario: Resource update fails due to invalid date input
    Given the Resource is opened in edit mode
     When the user fills in 'Begin' with '2024-13-15'
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Begin - Not a valid date |
      And the Resource Begin field has the original value
  Scenario: Delete required sub-record of a Resource fails
    Given the Resource is opened in edit mode
      And the Resource has one Language
     When the user clicks on remove icon in the 'Languages' form
      And the user clicks on 'Confirm Removal'
      And the user clicks on 'Save'
     Then the following error messages are displayed
      | Languages - At least 1 item(s) is required |
      | Must contain at least one Language         |
      And the Resource has one Language with the original values
  Scenario: Delete sub-record of a Resource
    Given the Resource is opened in edit mode
      And the Resource has one Note
     When the user clicks on remove icon in the 'Notes' form
      And the user clicks on 'Confirm Removal'
      And the user clicks on 'Save'
     Then the 'Resource' updated message is displayed
      And the Resource does not have Notes
