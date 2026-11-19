Feature: Calculate Extent of a resource

  Background:
    Given an administrator user is logged in
      And a Resource has been created
      And the Resource is opened in edit mode

  Scenario: Extent sub record is added to the Resource
     When the user clicks on 'More'
      And the user clicks on 'Calculate Extent'
      And the user selects 'Whole' from 'Portion' in the modal
      And the user fills in 'Number' with '123456789' in the modal
      And the user selects 'Cassettes' from 'Type' in the modal
      And the user clicks on 'Create Extent' in the modal
      And the user clicks on 'Save'
     Then the 'Resource' updated message is displayed
      And a new Extent is added to the Resource with the following values
        | Portion | Whole     |
        | Number  | 123456789 |
        | Type    | Cassettes |

  @many_extent_types
  Scenario: Extent type is kept when the Type field is a combobox
    Given the Extent Type list is long enough that the Type field is a combobox
     When the user clicks on 'More'
      And the user clicks on 'Calculate Extent'
      And the user selects 'Whole' from 'Portion' in the modal
      And the user fills in 'Number' with '42' in the modal
      And the user selects 'Gigabytes' from 'Type' in the modal
      And the user clicks on 'Create Extent' in the modal
     Then the new Extent has the 'Gigabytes' Type selected
     When the user clicks on 'Save'
     Then the 'Resource' updated message is displayed
      And the new Extent has the 'Gigabytes' Type selected
