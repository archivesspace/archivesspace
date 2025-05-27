Feature: Resource Digital Object

  Background:
    Given an administrator user is logged in
      And a Resource has been created
  Scenario: Add Digital Object by creating it
    Given the Resource is opened in edit mode
     When the user clicks on 'Instances'
      And the user clicks on 'Add Digital Object'
      And the user clicks on the first dropdown in the 'Instances' form
      And the user clicks on 'Create' in the dropdown menu in the 'Instances' form
      And the user fills in 'Title' with 'Test Digital Object' in the modal
      And the user fills in 'Identifier' with a unique identifier in the modal
      And the user clicks on 'Create and Link' in the modal
      And the user clicks on 'Save Resource'
     Then the 'Resource' updated message is displayed
      And a new instance with a link to the Digital Object is added to the Resource
  Scenario: Add Digital Object by browsing it
    Given a Digital Object has been created
      And the Resource is opened in edit mode
     When the user clicks on 'Add Digital Object'
      And the user clicks on the first dropdown in the 'Instances' form
      And the user clicks on 'Browse' in the dropdown menu in the 'Instances' form
      And the user searches and selects the Digital Object in the modal
      And the user clicks on 'Link' in the modal
      And the user clicks on 'Save Resource'
     Then the 'Resource' updated message is displayed
      And a new instance with a link to the Digital Object is added to the Resource
