Feature: Digital Object Component Edit Default Values
  Background:
    Given an administrator user is logged in
      And the Pre-populate Records option is checked in Repository Preferences
      And a Digital Object has been created
      And the user is on the Digital Objects page
  Scenario: Edit Default Values of Digital Object Component
     When the user clicks on 'Edit Default Values'
      And the user clicks on 'Digital Object Component' in the dropdown menu
     When the user fills in 'Label' with 'Test label'
      And the user fills in 'Title' with 'Test title'
      And the user clicks on 'Save Digital Object Component'
     Then the 'Defaults' updated message is displayed
      And the new Digital Object Component form has the following default values
        | form_section      | form_field | form_value |
        | Basic Information | Label      | Test label |
        | Basic Information | Title      | Test title |
