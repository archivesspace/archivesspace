Feature: File Versions list of Digital Objects in the public interface (ANW-3011)
  As an archivist I want all published file version links that are not solely thumbnails to be
  accessible to public interface users, either through the link associated with the
  thumbnail/generic icon or through a File Versions List

  Background:
    Given an administrator user is logged in

  Scenario: Unmarked published File Versions are listed, the Display Link is used for the thumbnail and the Display Thumbnail is not a link
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File             | Published | Marked as         | Caption |
      | an image         | yes       | Display Thumbnail |         |
      | a document       | yes       | Display Link      |         |
      | another document | yes       |                   |         |
      | a third document | yes       |                   |         |
     When the user views the 'Photograph' in the public interface
     Then the File Versions list lists only the following files
       | another document |
       | a third document |
      And the thumbnail shows 'an image'
      And the thumbnail links to 'a document'
      And no link on the page points to 'an image'

  Scenario: Without a Display Link or Display Thumbnail all published File Versions are listed
    Given a Digital Object 'Report' has been created with the following File Versions
      | File             | Published | Marked as | Caption |
      | a document       | yes       |           |         |
      | another document | yes       |           |         |
      | a third document | no        |           |         |
     When the user views the 'Report' in the public interface
     Then the File Versions list lists only the following files
       | a document       |
       | another document |
      And no thumbnail or generic icon is shown

  Scenario: With only a Display Thumbnail the thumbnail has no link and all other File Versions are listed
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File             | Published | Marked as         | Caption |
      | an image         | yes       | Display Thumbnail |         |
      | a document       | yes       |                   |         |
      | another document | yes       |                   |         |
     When the user views the 'Photograph' in the public interface
     Then the File Versions list lists only the following files
       | a document       |
       | another document |
      And the thumbnail shows 'an image'
      And the thumbnail has no link
      And no link on the page points to 'an image'

  Scenario: With only a Display Link the generic icon links to it and all other File Versions are listed
    Given a Digital Object 'Report' has been created with the following File Versions
      | File             | Published | Marked as    | Caption |
      | a document       | yes       | Display Link |         |
      | another document | yes       |              |         |
      | a third document | yes       |              |         |
     When the user views the 'Report' in the public interface
     Then the File Versions list lists only the following files
       | another document |
       | a third document |
      And the thumbnail shows the generic icon
      And the thumbnail links to 'a document'

  Scenario: With every published File Version marked there is no File Versions list
    Given a Digital Object 'Photograph' has been created with the following File Versions
      | File       | Published | Marked as         | Caption |
      | an image   | yes       | Display Thumbnail |         |
      | a document | yes       | Display Link      |         |
     When the user views the 'Photograph' in the public interface
     Then there is no File Versions list
