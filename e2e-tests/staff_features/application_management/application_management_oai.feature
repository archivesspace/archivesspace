Feature: OAI-PMH settings can be adjusted and OAI-PMH endpoint is available
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
  Scenario: Verify that OAI-PMH endpoint is available
     When the user visits the OAI-PMH endpoint using the verb Identify
     Then an XML response beginning with "<OAI-PMH xmlns=" is displayed
