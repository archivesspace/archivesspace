Feature: Digital Object Edit Default Values
  Background:
    Given an administrator user is logged in
      And the Pre-populate Records option is checked in Repository Preferences
      And a Digital Object has been created
      And the user is on the Digital Objects page
  Scenario: Edit Default Values
     When the user clicks on 'Edit Default Values'
      And the user clicks on 'Digital Object' in the dropdown menu
      And the user fills in 'Title' with 'Test Digital Object'
      And the user selects 'Text' from 'Digital Object Type'
      And the user clicks on 'Save'
     Then the 'Defaults' updated message is displayed
      And the new Digital Object form has the following default values
        | form_section      | form_field          | form_value          |
        | Basic Information | Title               | Test Digital Object |
        | Basic Information | Digital Object Type | Text                |
