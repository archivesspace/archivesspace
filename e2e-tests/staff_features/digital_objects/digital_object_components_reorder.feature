Feature: Digital Object Component Reorder
  Background:
    Given an administrator user is logged in
  Scenario: Activate reorder mode
    Given a Digital Object with two Digital Object Components has been created
      And the Digital Object is opened in edit mode
     When the user clicks on 'Enable Reorder Mode'
     Then the button has text 'Disable Reorder Mode'
  Scenario: Cut and Paste a Digital Object Component
    Given a Digital Object with two Digital Object Components has been created
      And the Digital Object is opened in edit mode
     When the user clicks on 'Enable Reorder Mode'
      And the user selects the second Digital Object Component
      And the user clicks on 'Cut'
      And the user selects the first Digital Object Component
      And the user clicks on 'Paste'
     Then the second Digital Object Component is pasted as a child of the Digital Object Component
  Scenario: Move a Digital Object Component up a level
    Given a Digital Object with two nested Digital Object Components has been created
     When the user selects the second Digital Object Component
     When the user clicks on 'Enable Reorder Mode'
      And the user clicks on 'Move'
      And the user clicks on 'Up a Level' in the dropdown menu
     Then the second Digital Object Component moves a level up
  Scenario: Move a Digital Object Component up
    Given a Digital Object with two Digital Object Components has been created
      And the Digital Object is opened in edit mode
     When the user selects the second Digital Object Component
      And the user clicks on 'Enable Reorder Mode'
      And the user clicks on 'Move'
      And the user clicks on 'Up' in the dropdown menu
     Then the second Digital Object Component moves one position up
  Scenario: Move Down Into a Digital Object Component
    Given a Digital Object with two Digital Object Components has been created
      And the Digital Object is opened in edit mode
     When the user selects the second Digital Object Component
      And the user clicks on 'Enable Reorder Mode'
      And the user clicks on 'Move'
      And the user clicks on 'Down Into' in the dropdown menu
      And the user selects the first Digital Object Component from the dropdown menu
     Then the second Digital Object Component moves as a child into the first Digital Object Component
