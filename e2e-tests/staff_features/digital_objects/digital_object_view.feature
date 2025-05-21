Feature: Digital Object View
  Background:
    Given an administrator user is logged in
  Scenario: Search Digital Object by title
    Given a Digital Object has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Digital Objects'
      And the user filters by text with the Digital Object title
     Then the Digital Object is in the search results
  Scenario: View Digital Object from the search results
    Given a Digital Object has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Digital Objects'
      And the user filters by text with the Digital Object title
      And the user clicks on 'View'
     Then the Digital Object view page is displayed
  Scenario: Sort Digital Objects by title
    Given two Digital Objects have been created with a common keyword in their title
      And the two Digital Objects are displayed sorted by ascending title
     When the user clicks on 'Title'
     Then the two Digital Objects are displayed sorted by descending title
  Scenario: Sort Digital Objects by Digital Object ID
    Given two Digital Objects have been created with a common keyword in their title
      And the two Digital Objects are displayed sorted by ascending title
     When the user clicks on 'Digital Object ID'
     Then the two Digital Objects are displayed sorted by ascending Digital Object ID
  Scenario: Digital Objects table download CSV
    Given two Digital Objects have been created with a common keyword in their title
      And the two Digital Objects are displayed in the search results
     When the user clicks on 'Download CSV'
     Then a CSV file is downloaded with the the two Digital Objects
