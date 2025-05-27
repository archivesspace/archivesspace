Feature: Resource calculate dates
  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode
  Scenario: Dates sub record is added to the Resource
     When the user clicks on 'More'
      And the user clicks on 'Calculate Dates'
      And the user selects 'Calculate for all dates' in the modal
      And the user clicks on 'Calculate Date Record' in the modal
      And the user selects 'Single' from 'Type' in the modal
      And the user fills in 'Begin' with '2022' in the modal
      And the user clicks on 'Create Date Record' in the modal
      And the user clicks on 'Save'
     Then the 'Resource' updated message is displayed
      And a new Date is added to the Resource with the following values
        | Label | Creation |
        | Type  | Single   |
        | Begin | 2022     |
