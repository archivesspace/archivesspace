Feature: Display thumbnail for Digital Objects and Digital Object Components (ANW-3001)
  As an archivist I want to designate an image to show as a thumbnail on designated displays
  for digital objects and digital object components in the staff and public interface

  Background:
    Given an administrator user is logged in

  Scenario: The image of the Display Thumbnail File Version shows on a Digital Object
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File     | Published | Marked as         | Caption |
      | an image | yes       | Display Thumbnail |         |
     When the user views the 'Photograph' in the staff interface
     Then the thumbnail shows 'an image'
     When the user views the 'Photograph' in the public interface
     Then the thumbnail shows 'an image'

  Scenario: The image of the Display Thumbnail File Version shows on a Digital Object Component
    Given a Digital Object 'Album' has been created without File Versions
      And the Digital Object 'Album' has a Digital Object Component 'Page' with the following File Versions
        | File     | Published | Marked as         | Caption |
        | an image | yes       | Display Thumbnail |         |
     When the user views the 'Page' in the staff interface
     Then the thumbnail shows 'an image'
     When the user views the 'Page' in the public interface
     Then the thumbnail shows 'an image'

  Scenario: A Display Thumbnail image that the browser cannot render shows a generic icon
    Given a Digital Object 'Lost Photograph' has been created with the following File Versions
      | File           | Published | Marked as         | Caption |
      | a broken image | yes       | Display Thumbnail |         |
     When the user views the 'Lost Photograph' in the staff interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a broken image'
     When the user views the 'Lost Photograph' in the public interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a broken image'

  Scenario Outline: The generic icon reflects the Digital Object Type
    Given a Digital Object 'Digital Material' of type '<Type>' has been created with the following File Versions
      | File       | Published | Marked as    | Caption |
      | a document | yes       | Display Link |         |
     When the user views the 'Digital Material' in the staff interface
     Then the thumbnail shows the generic icon for a '<Type>' Digital Object
     When the user views the 'Digital Material' in the public interface
     Then the thumbnail shows the generic icon for a '<Type>' Digital Object
       Examples:
         | Type                          |
         | Moving Image                  |
         | Sound Recording               |
         | Sound Recording (Musical)     |
         | Sound Recording (Non-musical) |
         | Still Image                   |
         | Text                          |
         | Cartographic                  |
         | Mixed Materials               |
         | Notated Music                 |
         | Software, Multimedia          |

  Scenario: Make Display Thumbnail and Make Display Link are only available on a published File Version
    Given a Digital Object 'Photograph' has been created without File Versions
     When the user opens the 'Photograph' in edit mode
      And the user adds a File Version for 'an image'
      And the user unpublishes the last File Version
     Then the 'Make Display Thumbnail' button of the last File Version is disabled
      And the 'Make Display Link' button of the last File Version is disabled
     When the user publishes the last File Version
     Then the 'Make Display Thumbnail' button of the last File Version is enabled
      And the 'Make Display Link' button of the last File Version is enabled
