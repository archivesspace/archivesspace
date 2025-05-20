Feature: Agent View
  Background:
    Given an administrator user is logged in
  Scenario: Search Agent by name
    Given an Agent has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Agents'
      And the user filters by text with the Agent name
     Then the Agent is in the search results
  Scenario: View Agent from the search results
    Given an Agent has been created
     When the user clicks on 'Browse'
      And the user clicks on 'Agents'
      And the user filters by text with the Agent name
      And the user clicks on 'View'
     Then the Agent view page is displayed
  Scenario: Sort Agents by name
    Given two Agents have been created with a common keyword in their name
      And the two Agents are displayed sorted by ascending name
     When the user clicks on 'Name'
     Then the two Agents are displayed sorted by descending name
  Scenario: Sort Agents by type
    Given two Agents have been created with a common keyword in their name
      And the two Agents are displayed sorted by ascending name
     When the user clicks on 'Agent Type'
     Then the two Agents are displayed sorted by ascending type
  Scenario: Sort Agents by Authority ID
    Given two Agents have been created with a common keyword in their name
      And the two Agents are displayed sorted by ascending name
     When the user clicks on 'Authority ID'
     Then the two Agents are displayed sorted by ascending Authority ID
  Scenario: Sort Agents by Source
    Given two Agents have been created with a common keyword in their name
      And the two Agents are displayed sorted by ascending name
     When the user clicks on 'Source'
     Then the two Agents are displayed sorted by ascending source
  Scenario: Sort Agents by Rules
    Given two Agents have been created with a common keyword in their name
      And the two Agents are displayed sorted by ascending name
     When the user clicks on 'Rules'
     Then the two Agents are displayed sorted by ascending rule
  Scenario: Sort Agents by date created
    Given two Agents have been created with a common keyword in their name
      And the two Agents are displayed sorted by ascending name
     When the user clicks on 'Name Ascending'
      And the user hovers on 'Created' in the dropdown menu
      And the user clicks on 'Ascending' in the dropdown menu
     Then the two Agents are displayed sorted by ascending created date
  Scenario: Sort Agents by modified date
    Given two Agents have been created with a common keyword in their name
      And the two Agents are displayed sorted by ascending name
     When the user clicks on 'Name Ascending'
      And the user hovers on 'Modified' in the dropdown menu
      And the user clicks on 'Ascending' in the dropdown menu
     Then the two Agents are displayed sorted by ascending modified date
