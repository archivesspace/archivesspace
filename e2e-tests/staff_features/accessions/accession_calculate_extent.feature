Feature: Calculate Extent of an accession
  Background:
   Given an administrator user is logged in
     And an Accession has been created
     And the Accession is opened in edit mode
  Scenario: Extent sub record is added to the Accession
    When the user clicks on 'More'
     And the user clicks on 'Calculate Extent'
     And the user selects 'Whole' from 'Portion' in the modal
     And the user fills in 'Number' with '123456789' in the modal
     And the user selects 'Cassettes' from 'Type' in the modal
     And the user clicks on 'Create Extent' in the modal
     And the user clicks on 'Save'
    Then the 'Accession' updated message is displayed
     And a new Extent is added to the Accession with the following values
       | Portion      | Whole           |
       | Number       | 123456789       |
       | Type         | Cassettes       |
