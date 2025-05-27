Feature: Agent Delete
  Background:
    Given an administrator user is logged in
      And an Agent has been created
  Scenario: Agent is deleted from the search results
     When the user clicks on 'Browse'
      And the user clicks on 'Agents'
      And the user filters by text with the Agent name
      And the user checks the checkbox of the Agent
      And the user clicks on 'Delete'
      And the user clicks on 'Delete Records'
     Then the 'Agents' deleted message is displayed
      And the Agent is deleted
  Scenario: Agent is deleted from the view page
    Given the user is on the Agent view page
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the Agents page is displayed
      And the 'Agent' deleted message is displayed
      And the Agent is deleted
  Scenario: Cancel Agent delete from the view page
    Given the user is on the Agent view page
     When the user clicks on 'Delete'
      And the user clicks on 'Cancel'
     Then the user is still on the Agent view page
