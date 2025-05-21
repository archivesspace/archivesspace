Feature: Resource Create
  Background:
    Given an administrator user is logged in
  Scenario: Resource is created
    Given the user is on the New Resource page
     When the user fills in 'Title'
      And the user fills in 'Identifier'
      And the user selects 'Class' from 'Level of Description'
      And the user fills in 'Language' with 'English' and selects 'English' in the 'Languages' form
      And the user fills in 'Script' with 'Old Hungarian' and selects 'Old Hungarian (Hungarian Runic)' in the 'Languages' form
      And the user selects 'Single' from 'Type' in the 'Dates' form
      And the user fills in 'Begin' with '2000-01-01' in the 'Dates' form
      And the user fills in 'Number' with '123456789' in the 'Extents' form
      And the user selects 'Cassettes' from 'Type' in the 'Extents' form
      And the user fills in 'Language of Description' with 'English' and selects 'English' in the 'Finding Aid Data' form
      And the user fills in 'Script of Description' with 'Old Hungarian' and selects 'Old Hungarian (Hungarian Runic)' in the 'Finding Aid Data' form
      And the user clicks on 'Save'
     Then the 'Resource' created message is displayed
      And the 'Title' has a unique value
      And the 'Identifier' has a unique value
      And the Resource form has the following values
        | form_section       | form_field                    | form_value                      |
        | Basic Information  | Level of Description          | Class                           |
        | Languages          | Language                      | English                         |
        | Languages          | Script                        | Old Hungarian (Hungarian Runic) |
        | Dates              | Type                          | Single                          |
        | Dates              | Begin                         | 2000-01-01                      |
        | Extents            | Number                        | 123456789                       |
        | Extents            | Type                          | Cassettes                       |
        | Finding Aid Data   | Language of Description       | English                         |
        | Finding Aid Data   | Script of Description         | Old Hungarian (Hungarian Runic) |
  Scenario: Resource is not created because required fields are missing
    Given the user is on the New Resource page
     When the user clicks on 'Save'
     Then the following error messages are displayed
       | Number - Property is required but was missing                    |
       | Type - Property is required but was missing                      |
       | Type - Property is required but was missing                      |
       | Title - Property is required but was missing                     |
       | Identifier - Property is required but was missing                |
       | Level of Description - Property is required but was missing      |
       | Language of Description - Property is required but was missing   |
       | Script of Description - Property is required but was missing     |
