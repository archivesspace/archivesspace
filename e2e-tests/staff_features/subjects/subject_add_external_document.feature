Feature: Subject External Documemt
  Background:
    Given an administrator user is logged in
      And a Subject has been created
      And the Subject is opened in edit mode
  Scenario: Add External Document
     When the user clicks on 'External Documents'
      And the user clicks on 'Add External Document'
      And the user fills in 'Title' with 'Test title'
      And the user fills in 'Location' with 'Test location'
      And the user clicks on 'Save Subject'
     Then the 'Subject' saved message is displayed
      And a new External Document is added to the Subject with the following values
       | Title    | Test title    |
       | Location | Test location |
  Scenario: External Document is not added because required fields are missing
     When the user clicks on 'External Documents'
      And the user clicks on 'Add External Document'
      And the user clicks on 'Save Subject'
     Then the following error messages are displayed
        | Title - Property is required but was missing    |
        | Location - Property is required but was missing |

