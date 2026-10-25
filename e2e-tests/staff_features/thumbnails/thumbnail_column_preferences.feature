Feature: Thumbnail column in the search and browse column preferences (ANW-3016)
  As an archivist I want the column for the thumbnail/generic icon shown for a digital object,
  digital object component, accession, resource, or archival object to be configurable in
  search and browse columns through the preferences areas

  Background:
    Given an administrator user is logged in

  Scenario Outline: Thumbnail is an option for the browse columns but not for the default sort column
     When the user is on the '<Preferences>' page
     Then Thumbnail is an option for each 'Digital Object' browse column but not for its default sort column
      And Thumbnail is an option for each 'Digital Object Component' browse column but not for its default sort column
      And Thumbnail is an option for each 'Accession' browse column but not for its default sort column
      And Thumbnail is an option for each 'Resource' browse column but not for its default sort column
      And Thumbnail is an option for each 'Archival Object' browse column but not for its default sort column
      And Thumbnail is an option for each 'Search' browse column but not for its default sort column
        Examples:
          | Preferences                    |
          | Global Preferences             |
          | Repository Preferences         |
          | Default Repository Preferences |

  @thumbnail_column_preference
  Scenario: The Thumbnail column shows the thumbnail in the browse results
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File     | Published | Marked as         | Caption |
      | an image | yes       | Display Thumbnail |         |
     When the user selects Thumbnail for 'Digital Object' browse column 3 in the Repository Preferences
      And the user browses the Digital Objects filtered by 'Photograph'
     Then the Thumbnail column shows 'an image' for 'Photograph'
