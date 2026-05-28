Feature: User can modify and configure Controlled Value Lists appropriately
  Background: 
    Given an administrator user is logged in
  Scenario: Add a value to a configurable controlled value list
     When the user clicks on 'System'
      And the user clicks on 'Manage Controlled Value Lists'
      And the user selects 'Subject Source (subject_source)' in the List Name dropdown menu
      And the user clicks on 'Create Value'
      And the user fills in 'Value' with 'Homosaurus' in the Create Value modal
      And the user clicks on 'Create Value' in the modal
     Then the 'Value' created message is displayed
      And the value 'Homosaurus' is added to the list
