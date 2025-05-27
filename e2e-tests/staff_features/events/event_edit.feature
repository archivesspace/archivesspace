Feature: Event Edit
  Background:
    Given an administrator user is logged in
      And an Event has been created
  Scenario: Event is opened in the edit mode from the browse menu
    Given the Event appears in the search results list
     When the user clicks on 'Edit'
     Then the Event is opened in the edit mode
  Scenario: Event is opened in the edit mode from the view mode
    Given the Event is opened in the view mode
     When the user clicks on 'Edit'
     Then the Event is opened in the edit mode
  Scenario Outline: Event is successfully updated
    Given the Event is opened in edit mode
     When the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Save'
     Then the 'Event' saved message is displayed
      And the field '<Field>' has value '<NewValue>'
       Examples:
        | Field        | NewValue           |
        | Type         | Component Transfer |
        | Outcome      | Pass               |
        | Outcome Note | Test Note          |
  Scenario: Event is not updated after changes are reverted
    Given the Event is opened in edit mode
     When the user changes the 'Type' field to 'Accumulation'
      And the user clicks on 'Revert Changes'
     Then the Event Type field has the original value
  Scenario: Event update fails due to invalid date input
    Given the Event is opened in edit mode
     When the user fills in 'Begin' with '2024-13-15' in the 'Event Date/Time' form
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Begin - Not a valid date |
  Scenario: Event update fails due to missing required field
    Given the Event is opened in edit mode
     When the user clears 'Role' in the 'Agent Links' form
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Role - Property is required but was missing |
