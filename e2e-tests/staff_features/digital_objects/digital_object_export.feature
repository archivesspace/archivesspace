Feature: Digital Object Export
  Background:
    Given an administrator user is logged in
      And a Digital Object has been created
      And the Digital Object is opened in edit mode
  Scenario: Digital Object export MODS
     When the user clicks on 'Export'
      And the user clicks on 'Download MODS' in the dropdown menu
     Then a MODS XML file is downloaded
  Scenario: Digital Object export METS
     When the user clicks on 'Export'
      And the user clicks on 'Download METS' in the dropdown menu
     Then a METS XML file is downloaded
  Scenario: Digital Object export DC
     When the user clicks on 'Export'
      And the user clicks on 'Download DC' in the dropdown menu
     Then a DC XML file is downloaded
