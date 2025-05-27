Feature: Resource Tree navigate
  Background:
    Given an administrator user is logged in
      And a Resource with two Archival Objects has been created
  Scenario: View the Resource Record tree
     When the Resource is opened in edit mode
     Then the Resource is displayed as the top level of the navigation tree
      And the Resource is highlighted in the tree
      And only the top-level Archival Objects are displayed
  Scenario: Expand all levels of the tree
    Given the Resource is opened in edit mode
      And only the first-level Archival Objects are displayed
     When the user clicks on 'Auto-Expand All'
     Then all Archival Objects are displayed
      And the button has text 'Disable Auto-Expand'
      And the expand arrows are disabled
  Scenario: Disable auto-expand
    Given the Resource is opened in edit mode
      And all levels of hierarchy in the tree are expanded
     When the user clicks on 'Disable Auto-Expand'
     Then the button has text 'Auto-Expand All'
      And the expand arrows are enabled
  Scenario: Collapse all levels of the tree
    Given the Resource is opened in edit mode
      And all levels of hierarchy in the tree are expanded
     When the user clicks on 'Collapse Tree'
     Then only the top-level Archival Objects are displayed
