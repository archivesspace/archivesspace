Feature: Agent Create
  Background:
    Given an administrator user is logged in
      And the user clicks on 'Create'
      And the user hovers on 'Agent' in the dropdown menu
  Scenario: Agent Person is created
     When the user clicks on 'Person'
      And the user fills in 'Primary Part of Name' in the 'Name Forms' form
      And the user clicks on 'Save'
     Then the 'Agent' created message is displayed
      And the 'Primary Part of Name' has a unique value
  Scenario: Agent Person is not created because required fields are missing
     When the user clicks on 'Person'
      And the user clicks on 'Save'
     Then the following error messages are displayed
       | Primary Part of Name - Property is required but was missing |
  Scenario: Agent Family is created
     When the user clicks on 'Family'
      And the user fills in 'Family Name' in the 'Name Forms' form
      And the user clicks on 'Save'
     Then the 'Agent' created message is displayed
      And the 'Family Name' has a unique value
  Scenario: Agent Family is not created because required fields are missing
     When the user clicks on 'Family'
      And the user clicks on 'Save'
     Then the following error messages are displayed
       | Family Name - Property is required but was missing |
  Scenario: Agent Corporate Entity is created
     When the user clicks on 'Corporate Entity'
      And the user fills in 'Primary Part of Name' in the 'Name Forms' form
      And the user clicks on 'Save'
     Then the 'Agent' created message is displayed
      And the 'Primary Part of Name' has a unique value
  Scenario: Agent Corporate Entity is not created because required fields are missing
     When the user clicks on 'Corporate Entity'
      And the user clicks on 'Save'
     Then the following error messages are displayed
       | Primary Part of Name - Property is required but was missing |
  Scenario: Agent Software is created
     When the user clicks on 'Software'
      And the user fills in 'Software Name' in the 'Name Forms' form
      And the user clicks on 'Save'
     Then the 'Agent' created message is displayed
      And the 'Software Name' has a unique value
  Scenario: Agent Software is not created because required fields are missing
     When the user clicks on 'Software'
      And the user clicks on 'Save'
     Then the following error messages are displayed
       | Software Name - Property is required but was missing |
  Scenario: Agent cannot be created by user with view-only permissions from the Create menu
    Given a viewer user is logged in
     When the user clicks on 'Browse'
      And the user clicks on 'Agents'
     Then the 'Create' button is not present on the page 
  Scenario: Agent cannot be created by user with view-only permissions from the Agents Browse page
    Given a viewer user is logged in
      And the user is on the Agents page
     Then the 'Create Agent' button is not present on the page 
  Scenario: Agent Person is created via the Agents Browse page
    Given the user is on the Agents page
      And the user clicks on 'Create Agent'
     When the user clicks on 'Person'
      And the user fills in 'Primary Part of Name' in the 'Name Forms' form
      And the user clicks on 'Save'
     Then the 'Agent' created message is displayed
      And the 'Primary Part of Name' has a unique value
