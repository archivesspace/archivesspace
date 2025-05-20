Feature: Agent Edit
  Background:
    Given an administrator user is logged in
      And an Agent has been created
   Scenario: Agent is opened in the edit mode from the browse menu
    Given the Agent appears in the search results list
     When the user clicks on 'Edit'
     Then the Agent is opened in the edit mode
  Scenario: Agent is opened in the edit mode from the view mode
    Given the Agent is opened in the view mode
     When the user clicks on 'Edit'
     Then the Agent is opened in the edit mode
  Scenario Outline: Agent is successfully updated
    Given the Agent is opened in edit mode
     When the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Save'
     Then the 'Agent' saved message is displayed
      And the field '<Field>' has value '<NewValue>'
        Examples:
          | Field                | NewValue         |
          | Prefix               | Test             |
  Scenario: Agent is not updated after changes are reverted
    Given the Agent is opened in edit mode
     When the user fills in 'Primary Part of Name' with 'New Agent Name'
      And the user clicks on 'Revert Changes'
     Then the Primary Part of Name has the original value
