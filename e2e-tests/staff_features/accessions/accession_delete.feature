Feature: Accession Delete
  Background:
    Given an administrator user is logged in
      And an Accession has been created
  Scenario: Accession is deleted from the search results
     When the user clicks on 'Browse'
      And the user clicks on 'Accessions'
      And the user filters by text with the Accession title
      And the user checks the checkbox of the Accession
      And the user clicks on 'Delete'
      And the user clicks on 'Delete Records'
     Then the 'Records' deleted message is displayed
      And the Accession is deleted
  Scenario: Accession is deleted from the view page
    Given the user is on the Accession view page
     When the user clicks on 'Delete'
      And the user clicks on 'Delete' in the modal
     Then the Accessions page is displayed
      And the 'Accession' deleted message is displayed
      And the Accession is deleted
  Scenario: Cancel Accession delete from the view page
    Given the user is on the Accession view page
     When the user clicks on 'Delete'
      And the user clicks on 'Cancel'
     Then the user is still on the Accession view page
