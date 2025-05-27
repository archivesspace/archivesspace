Feature: Digital Object link Agent
  Background:
    Given an administrator user is logged in
  Scenario: Link Agent
    Given a Digital Object has been created
      And the Digital Object is opened in the edit mode
     When the user clicks on 'Add Agent Link' in the 'Agent Links' form
      And the user selects 'Creator' from 'Role'
      And the user searches and selects an Agent
      And the user clicks on 'Save Digital Object'
     Then the 'Digital Object' updated message is displayed
      And a new Linked Agent is added to the Digital Object
  Scenario: Remove a Linked Agent
    Given a Digital Object with a Linked Agent has been created
      And the Digital Object is opened in the edit mode
     When the user clicks on remove icon in the 'Agent Links' form
      And the user clicks on 'Confirm Removal'
      And the user clicks on 'Save Digital Object'
      And the 'Digital Object' updated message is displayed
     Then the Linked Agent is removed from the Digital Object
