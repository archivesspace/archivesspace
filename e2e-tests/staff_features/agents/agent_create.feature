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
