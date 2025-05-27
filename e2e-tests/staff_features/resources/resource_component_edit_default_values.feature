Feature: Resource Component Edit Default Values
  Background:
    Given an administrator user is logged in
      And the Pre-populate Records option is checked in Repository Preferences
      And the user is on the Resources page
  Scenario: Open Resource Component Edit Default values page
     When the user clicks on 'Edit Default Values'
      And the user clicks on 'Resource Component' in the dropdown menu
     Then the Component Record Defaults page is displayed
  Scenario: Edit Default Values of Resource Component
    Given a Resource has been created
      And the user is on the Component Record Default page
     When the user fills in 'Title' with 'Default Component Test'
      And the user selects 'File' from 'Level of Description'
      And the user clicks on 'Save'
     Then the 'Defaults' updated message is displayed
      And the new Resource Component form has the following default values
       | form_section       | form_field                    | form_value                      |
       | Basic Information  | Title                         | Default Component Test          |
       | Basic Information  | Level of Description          | File                            |
