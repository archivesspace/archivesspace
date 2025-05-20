Feature: Agent merge
  Background:
    Given an administrator user is logged in
     And two Agents A & B have been created
  Scenario: Merge two Agents by browsing
    Given the Agent A is opened in edit mode
     When the user clicks on 'Merge'
      And the user clicks on the dropdown in the merge dropdown form
      And the user clicks on 'Browse' in the merge dropdown form
      And the user filters by text with the Agent B name in the modal
      And the user selects the Agent B from the search results in the modal
      And the user clicks on 'Link' in the modal
      And the user clicks on 'Merge' in the merge dropdown form
      And the user clicks on 'Compare Agents' in the modal
      And the user clicks on 'Merge' in the Compare Agents form
     Then the 'Agent(s)' merged message is displayed
      And the Agent B is deleted
  Scenario: Merge two Agents by searching
    Given the Agent A is opened in edit mode
     When the user clicks on 'Merge'
      And the user fills in and selects the Agent B in the merge dropdown form
      And the user clicks on 'Merge' in the merge dropdown form
      And the user clicks on 'Compare Agents' in the modal
      And the user clicks on 'Merge' in the Compare Agents form
     Then the 'Agent(s)' merged message is displayed
      And the Agent B is deleted
