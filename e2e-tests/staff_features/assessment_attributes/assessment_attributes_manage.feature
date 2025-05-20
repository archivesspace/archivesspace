Feature: Assessment Attributes manage
  Background:
    Given an administrator user is logged in
  Scenario:Add additional ratings
     When the user clicks on the gear icon
      And the user clicks on 'Manage Assessment Attributes'
      And the user clicks on the plus icon in the Ratings form
      And the user fills in the input field in the Repository Ratings section
      And the user clicks on 'Save Assessment Attributes'
     Then the 'Assessment Attributes' updated message is displayed
      And the new attribute is added to the Repository Ratings
  Scenario:Delete additional ratings
    Given a Rating Attribute has been added to the Repository Ratings
     When the user clicks on the gear icon
      And the user clicks on 'Manage Assessment Attributes'
      And the user clicks on the remove icon in the Ratings form
      And the user clicks on 'Save Assessment Attributes'
     Then the 'Assessment Attributes' updated message is displayed
      And the Rating Attribute is removed from the Repository Ratings
  Scenario: Search Records associated with a rating
    Given an Assessment with a rating has been created
     When the user clicks on the gear icon
      And the user clicks on 'Manage Assessment Attributes'
      And the user clicks on the magnifying glass icon of the rating
     Then the record associated with the assessment rating is in the search results
