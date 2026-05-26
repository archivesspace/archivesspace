Feature: Application Management OAI-PMH Settings
  Background: 
    Given an administrator user is logged in
  Scenario: Update OAI-PMH Settings
     When the user clicks on 'System'
      And the user clicks on 'Manage OAI-PMH Settings'
      And the user changes the '<Field>' field to '<NewValue>'
      And the user clicks on 'Update OAI-PMH Settings'
     Then the 'OAI-PMH settings' updated message is displayed
      And the field '<Field>' has value '<NewValue>'
        Examples:
          | Field               | NewValue                    |
          | OAI Admin Email     | archivist@example.org       |
