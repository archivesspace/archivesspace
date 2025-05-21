Feature: Agent Publish
  Background:
    Given an administrator user is logged in
      And an Agent has been created
  Scenario: Publish the Agent from toolbar
    Given the Agent is opened in edit mode
     When the user clicks on 'Publish All'
      And the user clicks on 'Publish All' in the modal
     Then the 'Agent' published message is displayed
      And the 'View Published' button is displayed
  Scenario: Publish the Agent record from the Publish checkbox in the Basic Information section
    Given the Agent is opened in edit mode
     When the user checks 'Publish'
      And the user clicks on 'Save'
     Then the 'Agent' saved message is displayed
      And the 'View Published' button is displayed
  Scenario: View a published Agent Record in the public interface
    Given the Agent is opened in edit mode
      And the Agent is published
     When the user clicks on 'View Published'
     Then the Agent opens on a new tab in the public interface
