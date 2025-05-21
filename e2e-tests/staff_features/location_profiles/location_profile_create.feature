Feature: Location Profile Create
  Background:
    Given an administrator user is logged in
  Scenario: Location Profile is created
     When the user clicks on 'System'
      And the user clicks on 'Manage Location Profiles' in the dropdown menu
      And the user clicks on 'Create Location Profile'
      And the user fills in 'Name'
      And the user fills in 'Depth' with '10'
      And the user fills in 'Height' with '20'
      And the user fills in 'Width' with '30'
      And the user clicks on 'Save'
     Then the 'Location Profile' created message is displayed
      And the Location Profile is created
  Scenario: Location Profile is not created because required fields are missing
     When the user clicks on 'System'
      And the user clicks on 'Manage Location Profiles' in the dropdown menu
      And the user clicks on 'Create Location Profile'
      And the user clicks on 'Save'
     Then the following error messages are displayed
       | Name - Property is required but was missing   |
  Scenario: Location Profile is created without providing dimensions
     When the user clicks on 'System'
      And the user clicks on 'Manage Location Profiles' in the dropdown menu
      And the user clicks on 'Create Location Profile'
      And the user fills in 'Name'
      And the user clicks on 'Save'
     Then the 'Location Profile' created message is displayed
      And the following message is displayed
        | Please note, dimension units, depth, height and width are all required by the space calculator. Locations will be omitted from the results if any of these values are missing. |
