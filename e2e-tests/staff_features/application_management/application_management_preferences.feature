Feature: Global, Repository, and Default Repository preferences can be edited
  Background: 
    Given an administrator user is logged in
  Scenario: User edits Global Preferences
     When the user clicks on 'Global Preferences (admin)' in the User Menu Dropdown
      And the user updates the Accession Browse Column 6 to Acquisition Type
     Then the 'Preferences' updated message is displayed
      And Acquisition Type is included as a column on the Accessions Browse page
  Scenario: User edits Repository Preferences
     When the user clicks on 'Repository Preferences (admin)' in the User Menu Dropdown
      And the user updates the Accession Browse Column 6 to Acquisition Type
     Then the 'Preferences' updated message is displayed
      And Acquisition Type is included as a column on the Accessions Browse page
  Scenario: User edits Default Repository Preferences
     When the user clicks on 'Default Repository Preferences' in the User Menu Dropdown
      And the user updates the Accession Browse Column 6 to Acquisition Type
     Then the 'Preferences' updated message is displayed
      And Acquisition Type is included as a column on the Accessions Browse page

