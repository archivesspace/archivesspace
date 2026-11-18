Feature: Agent Edit Default Values
  Background:
    Given an administrator user is logged in
      And the Pre-populate Records option is checked in Repository Preferences
  Scenario: Edit Default Values of Agent Person
    Given an Agent Person has been created
      And the user is on the Agents page
     When the user clicks on 'Edit Default Values'
      And the user clicks on 'Person' in the dropdown menu
      And the user clicks on 'Add Record ID'
      And the user fills in 'Record Identifier' with 'Test Record Identifier'
      And the user clicks on 'Save Person'
     Then the 'Defaults' updated message is displayed
      And the new Agent Person form has the following default values
        | form_section | form_field           | form_value              |
        | Record IDs   | Record Identifier    | Test Record Identifier  |
  Scenario: Edit Default Values of Agent Family
    Given an Agent Family has been created
      And the user is on the Agents page
     When the user clicks on 'Edit Default Values'
      And the user clicks on 'Family' in the dropdown menu
      And the user clicks on 'Add Contact'
      And the user fills in 'Contact Name' with 'Test Contact Name'
      And the user selects 'Ms.' from 'Salutation'
      And the user clicks on 'Save Family'
     Then the 'Defaults' updated message is displayed
      And the new Agent Family form has the following default values
        | form_section    | form_field    | form_value        |
        | Contact Details | Contact Name  | Test Contact Name |
        | Contact Details | Salutation    | Ms                |
  Scenario: Edit Default Values of Agent Corporate Entity
    Given an Agent Corporate Entity has been created
      And the user is on the Agents page
     When the user clicks on 'Edit Default Values'
      And the user clicks on 'Corporate Entity' in the dropdown menu
      And the user clicks on 'Other Agency Codes'
      And the user clicks on 'Add Agency Code'
      And the user fills in 'Maintenance Agency' with 'Test Agency'
      And the user clicks on 'Save Corporate Entity'
     Then the 'Defaults' updated message is displayed
      And the new Agent Corporate Entity form has the following default values
        | form_section       | form_field         | form_value  |
        | Other Agency Codes | Maintenance Agency | Test Agency |
  Scenario: Edit Default Values of Agent Software
    Given an Agent Software has been created
      And the user is on the Agents page
     When the user clicks on 'Edit Default Values'
      And the user clicks on 'Software' in the dropdown menu
      And the user clicks on 'Contact Details'
      And the user clicks on 'Add Contact'
      And the user fills in 'Contact Name' with 'Test Contact'
      And the user clicks on 'Save Software'
     Then the 'Defaults' updated message is displayed
      And the new Agent Software form has the following default values
        | form_section    | form_field   | form_value   |
        | Contact Details | Contact Name | Test Contact |
