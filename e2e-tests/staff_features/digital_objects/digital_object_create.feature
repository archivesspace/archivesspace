Feature: Digital Object Create
  Background:
    Given an administrator user is logged in
  Scenario: Digital Object is created
    Given the user is on the New Digital Object page
     When the user fills in 'Title' with 'Alabama: Mobile: Government Street [Cochran photos]'
      And the user fills in 'Identifier'
      And the user clicks on 'Save'
     Then the 'Digital Object' created message is displayed
  Scenario: Digital Object is not created because required fields are missing
    Given the user is on the New Digital Object page
     When the user clicks on 'Save'
     Then the following error messages are displayed
       | Title - Property is required but was missing |
       | Identifier - Property is required but was missing |
