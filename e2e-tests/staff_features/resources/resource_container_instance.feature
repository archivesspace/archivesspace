Feature: Resource Container Instance
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Add container instance
     When the user clicks on 'Instances'
      And the user clicks on 'Add Container Instance'
      And the user selects 'Accession' from 'Type' in the 'Instances' form
      And the user clicks on the first dropdown in the "Instances" form
      And the user clicks on "Create" in the dropdown menu in the "Instances" form
      And the user fills in 'Indicator' with 'Top Container Indicator' in the modal
      And the user clicks on 'Create and Link' in the modal
      And the user clicks on 'Save Resource'
     Then the 'Resource' updated message is displayed
      And a new Instance is added to the Resource with the following values
        | Type             | Accession               |
        | Top Container    | Top Container Indicator |
