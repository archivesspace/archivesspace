Feature: Agent light mode
  Background:
    Given an administrator user is logged in
      And an Agent has been created
      And the Agent is opened in edit mode
  Scenario: Agent is viewed in light mode
     When the user checks 'Light Mode'
     Then the Agent is in the light mode
  Scenario: Agent is viwed in full mode
    Given the light mode is checked
     When the user unchecks 'Light Mode'
     Then the Agent is in the full mode
