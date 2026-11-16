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
  Scenario: Merge two Agents when Agent A holds a suppressed name source
    Given a value has been added to the 'Name Source (name_source)' controlled value list
      And the Agent A is opened in edit mode
      And the user selects the added controlled value from 'Source' in the 'Name Forms' form
      And the user clicks on 'Save'
      And the 'Agent' saved message is displayed
      And the added controlled value is suppressed
      And the Agent A is opened in edit mode
     When the user clicks on 'Merge'
      And the user fills in and selects the Agent B in the merge dropdown form
      And the user clicks on 'Merge' in the merge dropdown form
      And the user clicks on 'Compare Agents' in the modal
      And the user clicks on 'Merge Preview'
     Then the merge preview shows the Agent A
     When the user clicks on 'Continue' in the modal
      And the user clicks on 'Merge' in the Compare Agents form
     Then the 'Agent(s)' merged message is displayed
     When the Agent A is opened in edit mode
     Then the 'Source' has the suppressed controlled value selected in the 'Name Forms' form
