Feature: Search and browse table View/Edit buttons position
  Background:
    Given an administrator user is logged in
  Scenario: View/Edit buttons are on the left by default for search
     When the user performs a search
     Then the View/Edit buttons column is the first column of the results table
  Scenario: View/Edit buttons are on the left by default for browse
     When the user clicks on 'Browse'
      And the user clicks on 'Accessions'
     Then the View/Edit buttons column is just to the right of the checkboxes in the results table
  @action_buttons_position_preference
  Scenario Outline: User changes the View/Edit buttons position to the right
     When the user clicks on '<Preferences>' in the User Menu Dropdown
      And the user changes the Accession Action Buttons (View/Edit) Position to Right
      And the user clicks on 'Save'
     Then the 'Preferences' updated message is displayed
     When the user clicks on 'Browse'
      And the user clicks on 'Accessions'
     Then the View/Edit buttons column is the last column of the results table
       Examples:
         | Preferences                     |
         | Global Preferences (admin)      |
         | Repository Preferences (admin)  |
         | Default Repository Preferences  |
