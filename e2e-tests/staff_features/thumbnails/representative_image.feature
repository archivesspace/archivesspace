Feature: Representative image on Accessions, Resources and Archival Objects (ANW-3008)
  As an archivist I want to show a representative image on accessions, resources,
  or archival objects with a digital object instance

  Background:
    Given an administrator user is logged in
      And a Digital Object 'Photograph' has been created with the following File Versions
        | File       | Published | Marked as         | Caption          |
        | an image   | yes       | Display Thumbnail | Photograph image |
        | a document | yes       | Display Link      |                  |

  Scenario: An Accession shows the image of its representative Digital Object instance, linked to the Digital Object
    Given an Accession 'Donation' has been created with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Donation' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
     When the user views the 'Donation' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'

  Scenario: An Archival Object shows the image of its representative Digital Object instance, linked to the Digital Object
    Given a Resource 'Collection' has been created
      And the Resource 'Collection' has an Archival Object 'Folder' with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Folder' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
     When the user views the 'Folder' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'

  Scenario: A Resource shows the image of its representative Digital Object instance and the number of its Digital Objects
    Given a Resource 'Collection' has been created with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Collection' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
     When the user views the 'Collection' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
      And the public interface offers to browse 1 digital object in the collection

  Scenario: A Resource whose representative instance shows no image shows the image of the next representative instance of its Archival Objects
    Given a Digital Object 'Report' has been created with the following File Versions
      | File       | Published | Marked as    | Caption |
      | a document | yes       | Display Link |         |
      And a Resource 'Collection' has been created with the Digital Object 'Report' as its representative instance
      And the Resource 'Collection' has an Archival Object 'Folder' with the Digital Object 'Photograph' as its representative instance
     When the user views the 'Collection' in the staff interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
     When the user views the 'Collection' in the public interface
     Then the thumbnail shows 'an image'
      And the thumbnail links to the Digital Object 'Photograph'
      And the thumbnail has the caption 'Photograph image'
      And the public interface offers to browse 2 digital objects in the collection

  Scenario: A Digital Object instance that is not marked representative shows no image
    Given an Accession 'Donation' has been created with the Digital Object 'Photograph' as an instance that is not representative
     When the user views the 'Donation' in the staff interface
     Then no thumbnail or generic icon is shown
     When the user views the 'Donation' in the public interface
     Then no thumbnail or generic icon is shown
