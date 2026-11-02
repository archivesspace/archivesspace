Feature: Link for the thumbnail of Digital Objects and Digital Object Components (ANW-3005)
  As an archivist I want to associate a link with the thumbnail in displays
  for digital objects and digital object components in the staff and public interface

  Background:
    Given an administrator user is logged in

  # Also covers ANW-3003: a renderable Display Thumbnail on another File Version shows the thumbnail instead of a generic icon
  # Also covers ANW-3001: Display Thumbnail file version is renderable, separate file version is Display Link
  Scenario: The thumbnail links to the File URI of the Display Link File Version
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File             | Published | Marked as         | Caption |
      | an image         | yes       | Display Thumbnail |         |
      | a document       | yes       | Display Link      |         |
      | another document | yes       |                   |         |
     When the user views the 'Photograph' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to 'a document'
     When the user views the 'Photograph' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to 'a document'
      And the File Versions list lists only the following files
        | another document |

  Scenario: The thumbnail of a Digital Object Component links to the File URI of the Display Link File Version
    Given a Digital Object 'Album' has been created without File Versions
      And the Digital Object 'Album' has a Digital Object Component 'Page' with the following File Versions
        | File       | Published | Marked as         | Caption |
        | an image   | yes       | Display Thumbnail |         |
        | a document | yes       | Display Link      |         |
     When the user views the 'Page' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to 'a document'
     When the user views the 'Page' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to 'a document'

  # Also covers ANW-3001: Display Thumbnail file version is renderable, no other marked file versions
  Scenario: Without a Display Link File Version the thumbnail has no link
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File       | Published | Marked as         | Caption |
      | an image   | yes       | Display Thumbnail |         |
      | a document | yes       |                   |         |
     When the user views the 'Photograph' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail has no link
     When the user views the 'Photograph' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail has no link
      And the File Versions list lists only the following files
        | a document |
