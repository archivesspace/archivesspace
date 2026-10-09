Feature: Digital Object IIIF viewer
  The embedded IIIF viewer comes from the manifest File Version and the thumbnail only from
  the Make Display Thumbnail and Make Display Link flags, so both can show on the same page

  Background:
    Given an administrator user is logged in

  Scenario: In the staff interface the viewer is in the manifest File Version and the thumbnail shows the Display Thumbnail
    Given a Digital Object 'Book' has been created with the following File Versions
      | File            | Published | Marked as         | Caption |
      | a IIIF manifest | yes       |                   |         |
      | an image        | yes       | Display Thumbnail |         |
     When the user views the 'Book' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail has no link
     When the user expands the File Version
     Then the bundled Universal Viewer is embedded
      And the viewer renders the IIIF manifest

  Scenario: In the public interface the viewer and the thumbnail show together
    Given a Digital Object 'Book' has been created with the following File Versions
      | File            | Published | Marked as         | Caption |
      | a IIIF manifest | yes       |                   |         |
      | an image        | yes       | Display Thumbnail |         |
     When the user views the 'Book' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail has no link
      And the bundled Universal Viewer is embedded
      And the viewer renders the IIIF manifest
      And the File Versions list lists only the following files
        | a IIIF manifest |

  Scenario: A manifest marked as Display Link is the link of the thumbnail
    Given a Digital Object 'Book' has been created with the following File Versions
      | File            | Published | Marked as         | Caption |
      | a IIIF manifest | yes       | Display Link      |         |
      | an image        | yes       | Display Thumbnail |         |
     When the user views the 'Book' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to 'a IIIF manifest'
     When the user views the 'Book' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to 'a IIIF manifest'
      And the bundled Universal Viewer is embedded
      And there is no File Versions list

  Scenario: A manifest marked as Display Thumbnail shows the generic icon, as a browser cannot display it as an image
    Given a Digital Object 'Book' has been created with the following File Versions
      | File            | Published | Marked as         | Caption |
      | a IIIF manifest | yes       | Display Thumbnail |         |
      | a document      | yes       | Display Link      |         |
     When the user views the 'Book' in the staff interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a IIIF manifest'
      And the thumbnail links to 'a document'
     When the user views the 'Book' in the public interface
     Then the thumbnail falls back to the generic icon because the browser cannot render 'a IIIF manifest'
      And the thumbnail links to 'a document'
      And the bundled Universal Viewer is embedded

  Scenario: An unpublished manifest is only embedded in the staff interface
    Given a Digital Object 'Book' has been created with the following File Versions
      | File            | Published | Marked as         | Caption |
      | a IIIF manifest | no        |                   |         |
      | an image        | yes       | Display Thumbnail |         |
     When the user views the 'Book' in the public interface
     Then the thumbnail shows 'an image'
      And no IIIF viewer is embedded
     When the user views the 'Book' in the staff interface
     Then the thumbnail shows 'an image'
     When the user expands the File Version
     Then the bundled Universal Viewer is embedded
