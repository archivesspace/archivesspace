Feature: Accessions Search
  Background:
    Given an administrator user is logged in
  Scenario: Search Accession by title
    Given an Accession has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Accessions'
      And the user filters by text with the Accession title
     Then the Accession is in the search results
  Scenario: View Accession from the search results
    Given an Accession has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Accessions'
      And the user filters by text with the Accession title
      And the user clicks on 'View'
     Then the Accession view page is displayed
  Scenario: Sort Accessions by title
    Given two Accessions have been created with a common keyword in their title
      And the two Accessions are displayed sorted by ascending title
     When the user clicks on 'Title'
     Then the two Accessions are displayed sorted by descending title
