Feature: Assessment Delete
  Background:
    Given an administrator user is logged in
      And an Assessment has been created
  Scenario: Assessment is deleted from the search results
     When the user clicks on 'Browse'
      And the user clicks on 'Assessments'
      And the user filters by text with the Assessment record
      And the user checks the checkbox of the Assessment
      And the user clicks on 'Delete'
      And the user clicks on 'Delete Records'
     Then the 'Assessments' deleted message is displayed
      And the Assessment is deleted
  Scenario: Assessment is deleted from the view page
    Given the user is on the Assessment view page
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the Assessments page is displayed
      And the 'Assessment' deleted message is displayed
      And the Assessment is deleted
  Scenario: Cancel Assessment delete from the view page
    Given the user is on the Assessment view page
     When the user clicks on 'Delete'
      And the user clicks on 'Cancel'
     Then the user is still on the Assessment view page
