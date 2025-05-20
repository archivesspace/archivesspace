Feature: Top container Search
  Background:
    Given an administrator user is logged in
  Scenario: Search Top Container associated with a Resource
    Given a Resource with a Top Container has been created
     When the user clicks on the gear icon
      And the user clicks on 'Manage Top Containers'
      And the user fills in 'Keyword' with the Resource title
      And the user clicks on 'Search'
     Then the Top Container associated with the Resource is in the search results
  Scenario: Search Top Container associated with an Accession
    Given an Accession with a Top Container has been created
     When the user clicks on the gear icon
      And the user clicks on 'Manage Top Containers'
      And the user fills in 'Keyword' with the Accession title
      And the user clicks on 'Search'
     Then the Top Container associated with the Accession is in the search results
