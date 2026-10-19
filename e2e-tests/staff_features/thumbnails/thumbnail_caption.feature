Feature: Caption for the thumbnail or generic icon of Digital Objects (ANW-3007)
  As an archivist I want to associate a caption with the thumbnail or generic icon
  in displays for digital objects in the staff and public interface

  Background:
    Given an administrator user is logged in

  Scenario: The caption of the File Version shown as the thumbnail is used
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File       | Published | Marked as         | Caption           |
      | an image   | yes       | Display Thumbnail | Thumbnail caption |
      | a document | yes       | Display Link      | Link caption      |
     When the user views the 'Photograph' in the staff interface
     Then the thumbnail has the caption 'Thumbnail caption'
     When the user views the 'Photograph' in the public interface
     Then the thumbnail has the caption 'Thumbnail caption'

  Scenario: The caption of the File Version shown as the generic icon is used
    Given a Digital Object 'Report' has been created with the following File Versions
      | File             | Published | Marked as         | Caption          |
      | a document       | yes       | Display Thumbnail | Document caption |
      | another document | yes       | Display Link      | Link caption     |
     When the user views the 'Report' in the public interface
     Then the thumbnail has the caption 'Document caption'

  Scenario: Without a caption on the thumbnail File Version, the caption of the Display Link File Version is used
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File       | Published | Marked as         | Caption      |
      | an image   | yes       | Display Thumbnail |              |
      | a document | yes       | Display Link      | Link caption |
     When the user views the 'Photograph' in the staff interface
     Then the thumbnail has the caption 'Link caption'
     When the user views the 'Photograph' in the public interface
     Then the thumbnail has the caption 'Link caption'

  Scenario: Without captions, the title of the Digital Object is used
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File       | Published | Marked as         | Caption |
      | an image   | yes       | Display Thumbnail |         |
      | a document | yes       | Display Link      |         |
     When the user views the 'Photograph' in the staff interface
     Then the thumbnail caption is the title of 'Photograph'
     When the user views the 'Photograph' in the public interface
     Then the thumbnail caption is the title of 'Photograph'

  Scenario: Without captions or a title, the display string of the Digital Object Component is used
    Given a Digital Object 'Album' has been created without File Versions
      And the Digital Object 'Album' has a Digital Object Component with Label 'Page', the date '1950' and no Title with the following File Versions
        | File     | Published | Marked as         | Caption |
        | an image | yes       | Display Thumbnail |         |
     When the user views the 'Page' in the staff interface
     Then the thumbnail caption is the display string of 'Page', with its label and date
     When the user views the 'Page' in the public interface
     Then the thumbnail caption is the display string of 'Page', with its label and date
