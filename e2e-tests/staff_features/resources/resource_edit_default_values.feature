Feature: Resource Edit Default Values
  Background:
    Given an administrator user is logged in
      And the Pre-populate Records option is checked in Repository Preferences
      And a Resource has been created
      And the user is on the Resources page
  Scenario: Open Resource Edit Default values page
     When the user clicks on 'Edit Default Values'
      And the user clicks on 'Resource' in the dropdown menu
     Then the Resource Record Defaults page is displayed
  Scenario: Edit Default Values
    Given the user is on the Resource Record Default page
     When the user fills in 'Title' with 'Default Test Title'
      And the user selects 'File' from 'Level of Description'
      And the user clicks on 'Save'
     Then the 'Defaults' updated message is displayed
      And the new Resource form has the following default values
        | form_section       | form_field                    | form_value                      |
        | Basic Information  | Title                         | Default Test Title              |
        | Basic Information  | Level of Description          | File                            |
