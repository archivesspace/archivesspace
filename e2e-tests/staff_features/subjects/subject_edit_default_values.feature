Feature: Subject Edit Default Values
  Background:
    Given an administrator user is logged in
      And the Pre-populate Records option is checked in Repository Preferences
      And the user is on the Subjects page
  Scenario: Edit Default Values
     When the user clicks on 'Edit Default Values'
      And the user fills in 'Authority ID' with 'Test ID'
      And the user fills in 'Scope Note' with 'Text'
      And the user clicks on 'Save'
     Then the 'Defaults' updated message is displayed
      And the new Subject form has the following default values
       | form_section      | form_field   | form_value |
       | Basic Information | Authority ID | Test ID    |
       | Basic Information | Scope Note   | Text       |
