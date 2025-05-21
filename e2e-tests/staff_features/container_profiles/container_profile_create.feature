Feature: Container Profile Create
  Background:
    Given an administrator user is logged in
  Scenario: Open new container profile page from Create in the main toolbar
     When the user clicks on 'Create'
      And the user clicks on 'Container Profile' in the dropdown menu
     Then the New Container Profile page is displayed
  Scenario: Open new container profile page from Manage Container Profile
     When the user clicks on 'System'
      And the user clicks on 'Manage Container Profiles' in the dropdown menu
      And the user clicks on 'Create Container Profile'
     Then the New Container Profile page is displayed
  Scenario: Open new container profile page from Browse in the main toolbar
     When the user clicks on 'Browse'
      And the user clicks on 'Container Profiles' in the dropdown menu
      And the user clicks on 'Create Container Profile'
     Then the New Container Profile page is displayed
  Scenario: Container Profile is created
     When the user clicks on 'Create'
      And the user clicks on 'Container Profile' in the dropdown menu
      And the user fills in 'Name'
      And the user fills in 'Depth' with '1.1'
      And the user fills in 'Height' with '2.2'
      And the user fills in 'Width' with '3.3'
      And the user clicks on 'Save'
     Then the 'Container Profile' created message is displayed
      And the Container Profile is created
  Scenario: Container Proofile is not created because required fields are missing
     When the user clicks on 'Create'
      And the user clicks on 'Container Profile' in the dropdown menu
      And the user clicks on 'Save'
     Then the following error messages are displayed
       | Name - Property is required but was missing   |
       | Height - Property is required but was missing |
       | Width - Property is required but was missing  |
       | Depth - Property is required but was missing  |
  Scenario: Container Profile is not created because Depth is alphanumeric
     When the user clicks on 'Create'
      And the user clicks on 'Container Profile' in the dropdown menu
      And the user fills in 'Name'
      And the user fills in 'Depth' with 'abc'
      And the user fills in 'Height' with '2.2'
      And the user fills in 'Width' with '3.3'
      And the user clicks on 'Save'
     Then the following error message is displayed
       | Depth - Must be a number with no more than 2 decimal places |
