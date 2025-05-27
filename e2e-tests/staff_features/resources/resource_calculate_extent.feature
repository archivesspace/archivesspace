Feature: Calculate Extent of a resource
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Extent sub record is added to the Resource
     When the user clicks on 'More'
      And the user clicks on 'Calculate Extent'
      And the user selects 'Whole' from 'Portion' in the modal
      And the user fills in 'Number' with '123456789' in the modal
      And the user selects 'Cassettes' from 'Type' in the modal
      And the user clicks on 'Create Extent' in the modal
      And the user clicks on 'Save'
     Then the 'Resource' updated message is displayed
      And a new Extent is added to the Resource with the following values
        | Portion      | Whole           |
        | Number       | 123456789       |
        | Type         | Cassettes       |
