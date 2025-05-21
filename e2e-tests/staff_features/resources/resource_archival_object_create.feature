Feature: Resource Archival Object create
  Background:
    Given an administrator user is logged in
  Scenario: Create a Child Archival Object
    Given a Resource has been created
      And the Resource is opened in edit mode
     When the user clicks on 'Add Child'
      And the user fills in 'Title' with 'Archival Object Title Child'
      And the user selects 'File' from 'Level of Description'
      And the user clicks on 'Save'
     Then the 'Archival Object' created message is displayed
      And the Archival Object with Title 'Archival Object Title Child' is saved as a child of the Resource
  Scenario: Create a Sibling Archival Object
    Given a Resource with an Archival Object has been created
      And the Resource is opened in edit mode
     When the user selects the Archival Object
      And the user clicks on 'Add Sibling'
      And the user fills in 'Title' with 'Archival Object Title Sibling'
      And the user selects 'File' from 'Level of Description'
      And the user clicks on 'Save'
     Then the 'Archival Object' created message is displayed
      And the Archival Object with Title 'Archival Object Title Sibling' is saved as a sibling of the selected Archival Object
  Scenario: Duplicate Archival Object
    Given a Resource with an Archival Object has been created
      And the Resource is opened in edit mode
     When the user selects the Archival Object
      And the user clicks on 'Add Duplicate'
     Then the New Archival Object page is displayed
      And the 'Archival Object' duplicated message is displayed
      And the following Archival Object forms have the same values as the Archival Object
        | Basic Information  |
        | Languages          |
        | Dates              |
        | Extents            |
        | Agent Links        |
        | Accession Links    |
        | Subjects           |
        | Notes              |
        | External Documents |
        | Rights Statements  |
