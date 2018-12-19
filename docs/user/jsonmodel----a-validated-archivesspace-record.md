---
title: JSONModel -- a validated ArchivesSpace record
layout: en
permalink: /user/jsonmodel----a-validated-archivesspace-record/
---
The ArchivesSpace system is concerned with managing a number of
different archival record types.  Each record can be expressed as a
set of nested key/value pairs, and associated with each record type is
a number of rules that describe what it means for a record of that
type to be valid:

  * some fields are mandatory, some optional
  * some fields can only take certain types
  * some fields can only take values from a constrained set
  * some fields are dependent on other fields
  * some record types can be nested within other record types
  * some record types may be related to others through a hierarchy
  * some record types form a relationship graph with other record
    types

The JSONModel class provides a common language for expressing these
rules that all parts of the application can share.  There is a
JSONModel class instance for each type of record in the system, so:

    JSONModel(:digital_object)

is a class that knows how to take a hash of properties and make sure
those properties conform to the specification of a Digital Object:

    JSONModel(:digital_object).from_hash(myhash)

If it passes validation, a new JSONModel(:digital\_object) instance is
returned, which provides accessors for accessing its values, and
facilities for round-tripping between JSON documents and regular Ruby
hashes:

     obj = JSONModel(:digital_object).from_hash(myhash)

     obj.title  # or obj['title']
     obj.title = 'a new title'  # or obj['title'] = 'a new title'

     obj.\_exceptions  # Validates the object and reports any issues

     obj.to_hash  # Turn the JSONModel object back into a regular hash
     obj.to_json  # Serialize the JSONModel object into JSON


Much of the validation performed by JSONModel is provided by the JSON
schema definitions listed in the `common/schemas` directory.  JSON
schemas provide a standard way of declaring which properties a record
may and may not contain, along with their types and other
restrictions.  ArchivesSpace uses these schemas to capture the
validation rules defining each record type in a declarative and
relatively self-documenting fashion.

JSONModel instances are the primary data interchange mechanism for the
ArchivesSpace system: the API consumes and produces JSONModel
instances (in JSON format), and much of the user interface's life is
spent turning forms into JSONModel instances and shipping them off to
the backend.

## JSONModel::Client -- A high-level API for interacting with the ArchivesSpace backend

To save the need for a lot of HTTP request wrangling, ArchivesSpace
ships with a module called JSONModel::Client that simplifies the
common CRUD-style operations.  Including this module just requires
passing an additional parameter when initializing JSONModel:

     JSONModel::init(:client_mode => true, :url => @backend_url)
     include JSONModel

If you'll be working against a single repository, it's convenient to
set it as the default for subsequent actions:

     JSONModel.set_repository(123)

Then, several additional JSONModel methods are available:

     # As before, get a paginated list of accessions (GET)
     JSONModel(:accession).all(:page => 1)

     # Create a new accession (POST)
     obj = JSONModel(:accession).from_hash(:title => "A new accession", ...)
     obj.save

     # Get a single accession by ID (GET)
     obj = JSONModel(:accession).find(123)

     # Update an existing accession (POST)
     obj = JSONModel(:accession).find(123)
     obj.title = "Updated title"
     obj.save
