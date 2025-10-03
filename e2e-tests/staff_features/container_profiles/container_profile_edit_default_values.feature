Feature: Container Profile Edit Default Values
  Background:
    Given an administrator user is logged in
      And the Pre-populate Records option is checked in Repository Preferences
      And the user is on the Container Profiles page
  Scenario: Edit Default Values of Container Profile with Width as Extent Dimension
     When the user clicks on 'Edit Default Values'
      And the user fills in 'Name' with 'DEFAULT BOX'
      And the user selects 'Width' from 'Extent Dimension'
      And the user fills in 'Depth' with '12'
      And the user fills in 'Height' with '15'
      And the user fills in 'Width' with '10'
      And the user selects 'Inches' from 'Dimension Units'
      And the user clicks on 'Save Container Profile'
     Then the 'Defaults' updated message is displayed
      And the new Container Profile form has the following default values
       | form_section       | form_field        | form_value   |
       | Basic Information  | Name              | DEFAULT BOX  |
       | Basic Information  | Extent Dimension  | Width        |
       | Basic Information  | Depth             | 12           |
       | Basic Information  | Height            | 15           |
       | Basic Information  | Width             | 10           |
       | Basic Information  | Dimension Units   | Inches       |

  Scenario: Change Container Profile Default from Width to Height
    Given a Container Profile Default has been set with Width as Extent Dimension
      And the user is on the Container Profiles page
     When the user clicks on 'Edit Default Values'
      And the user selects 'Height' from 'Extent Dimension'
      And the user clicks on 'Save Container Profile'
     Then the 'Defaults' updated message is displayed
      And the new Container Profile form has the following default values
       | form_section       | form_field        | form_value   |
       | Basic Information  | Name              | DEFAULT BOX  |
       | Basic Information  | Extent Dimension  | Height       |
       | Basic Information  | Depth             | 12           |
       | Basic Information  | Height            | 15           |
       | Basic Information  | Width             | 10           |
       | Basic Information  | Dimension Units   | Inches       |
