Feature: User can modify and configure Controlled Value Lists appropriately
  Background: 
    Given an administrator user is logged in
  Scenario: Add a value to a configurable controlled value list
     When the user clicks on 'System'
      And the user clicks on 'Manage Controlled Value Lists'
      And the user selects 'Subject Source (subject_source)' in the List Name dropdown menu
      And the user clicks on 'Create Value'
      And the user fills in 'enumeration_value_' with 'Homosaurus' in the modal
      And the user clicks on 'Create Value' in the modal
     Then the 'Value' created message is displayed
      And the value 'Homosaurus' is added to the list
  Scenario: User cannot add a value to a non-configurable controlled value list
     When the user clicks on 'System'
      And the user clicks on 'Manage Controlled Value Lists'
      And the user selects 'Language ISO 639-2 (language_iso639_2)' in the List Name dropdown menu
     Then the 'Create Value' button is not present on the page
