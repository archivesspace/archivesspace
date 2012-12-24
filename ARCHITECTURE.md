
# The ArchivesSpace API

ArchivesSpace is implemented as two major pieces: the backend, which
exposes the major workflows and data types of the system via a
web-service API, and the user interface (or frontend), which makes use
of the backend's API to provide a web application interface to end
users.

Before looking at the implementation of these pieces, it may help to
give context by looking at the parts that are common to both.  We'll
begin with a summary of JSONModel, the primary way archival records
are represented by the system, then look briefly at the system's API,
which governs how the user interface (and others) interact with the
ArchivesSpace backend.


## JSONModel -- a validated ArchivesSpace record

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

The flexibility afforded by representing records as trees of key/value
pairs is convenient--particularly as there is so much variability
between the record types--but ensuring that these satisfy the
validation rules for a given record type is challenging, and it would
be unfortunate if every section of code that worked with archival
records had to supply its own validation logic.

The JSONModel class avoids this situation by providing a lightweight
wrapper around the nested key/value pairs we want--essentially: a
regular Ruby hash plus validation.  There is a JSONModel class
instance for each type of record in the system, so:

    JSONModel(:digital_object)

is a class that knows how to take a hash of properties and make sure
those properties conform to the specification of a Digital Object:

    JSONModel(:digital_object).from_hash(myhash)

If it passes validation, a new JSONModel(:digital\_object) instance is
returned, which provides accessors for accessing its value, and
facilities for round-tripping between JSON documents and regular Ruby
hashes:

     obj = JSONModel(:digital_object).from_hash(myhash)

     obj.title  # or obj['title']
     obj.title = 'a new title'  # or obj['title'] = 'a new title']

     obj._exceptions  # Validates the object and reports any issues

     obj.to_hash  # Turn the JSONModel object back into a regular hash
     obj.to_json  # Serialise the JSONModel object into JSON


Much of the validation performed by JSONModel is provided by the JSON
schema definitions listed in the `common/schemas` directory.  JSON
schemas provide a standard way of declaring which properties a
document may and may not contain, along with their types and other
restrictions.  ArchivesSpace uses and extends these schemas to capture
the validation rules defining each record type in a declarative and
relatively self-documenting fashion.

JSONModel instances are the primary data interchange mechanism for the
ArchivesSpace system: the API consumes and produces JSONModel
instances (in JSON format), and much of the user interface's life is
spent turning forms into JSONModel instances and shipping them off to
the backend.


## Working with the ArchivesSpace API

### Authentication

Most actions against the backend require you to be logged in as a user
with the appropriate permissions.  By sending a request like:

     POST /users/admin/login?password=login

your authentication request will be validated, and a session token
will be returned in the JSON response for your request.  To remain
authenticated, provide this token with subsequent requests in the
X-ArchivesSpace-Session header.  For example:

     X-ArchivesSpace-Session: 8e921ac9bbe9a4a947eee8a7c5fa8b4c81c51729935860c1adfed60a5e4202cb


### CRUD

The ArchivesSpace API provides CRUD-style interactions for a number of
different "top-level" record types.  Working with records follows a
fairly standard pattern:

     # Get a paginated list of accessions from repository '123'
     GET /repositories/123/accessions?page=1

     # Create a new accession
     POST /repositories/123/accessions
     {... a JSON document satisfying JSONModel(:accession) here ...}

     # Get a single accession by ID (returned as a JSONModel(:accession)
     # instance)
     GET /repositories/123/accessions/456

     # Update an existing accession
     POST /repositories/123/accessions/456
     {... a JSON document satisfying JSONModel(:accession) here ...}



## JSONModel::Client -- A high-level API for interacting with the ArchivesSpace backend

To save the need for a lot of HTTP request wrangling, ArchivesSpace
ships with a module called JSONModel::Client that simplifies the
common CRUD-style operations.  Including this module just requires
passing an additional parameter when initialising JSONModel:

     JSONModel::init(:client_mode => true, :url => @backend_url)
     include JSONModel

If you'll be working against a single repository, it's convenient to
set it as the default for subsequent actions:

     JSONModel.set_repository(123)

Then, several additional JSONModel methods are available:

     # As before, get a paginated list of accessions
     JSONModel(:accession).all(:page => 1)

     # Create a new accession
     obj = JSONModel(:accession).from_hash(:title => "A new accession", ...)
     obj.save

     # Get a single accession by ID
     obj = JSONModel(:accession).find(123)

     # Update an existing accession
     obj = JSONModel(:accession).find(123)
     obj.title = "Updated title"
     obj.save



# The ArchivesSpace backend

The backend is responsible for implementing the ArchivesSpace API, and
supports the sort of access patterns shown in the previous section.
We've seen that the backend must support CRUD operations against a
number of different record types, and that the format for expressing
those records is through JSON documents produced from instances of
JSONModel classes.

The following sections address how the backend fits together.


## main.rb -- load and initialise the system

The `main.rb` program is responsible for starting the ArchivesSpace
system: loading all controllers and models, creating
users/groups/permissions as needed, and preparing the system to handle
requests.

When the system starts up, the `main.rb` program performs the
following actions:

  * Initialises JSONModel--triggering it to load all record schemas
    from the filesystem and generate the classes that represent each
    record type.

  * Connects to the database

  * Loads all backend models--the system's domain objects and
    persistence layer

  * Loads all controllers--defining the system's REST endpoints

  * Starts the job scheduler--handling scheduled tasks such as backups
    of the demo database (if used)

  * Runs the "bootstrap ACLs" process--creates the admin user and
    group if they don't already exist; creates the hidden global
    repository; creates the user and group used by the search indexer

  * Fires the "backend started" webhook notification to any registered
    observers.


In addition to handling the system startup, `main.rb` also provides
the following facilities:

  * Top-level exception handling--catches exceptions originating from
    the lower system layers and maps them to an appropriate HTTP
    status code and JSON response.

  * Wraps each request in a database transaction, ensuring automatic
    rollback of any changes should part of the request fail and throw
    an exception.

  * Request logging--logs the parameters and response for each
    request.

  * Session handling--tracks authenticated backend sessions using the
    token extracted from the `X-ArchivesSpace-Session` request header.

  * Helper methods for accessing the current user and current session
    of each request.


## rest.rb -- Request and response handling for REST endpoints

The `rest.rb` module provides the mechanism used to define the API's
REST endpoints.  Each endpoint definition includes:

  * The URI and HTTP request method used to access the endpoint

  * A list of typed parameters that are permissible for that endpoint

  * Documentation for the endpoint, each parameter, and each possible
    response that may be returned

  * Permission checks--predicates that the current user must satisfy
    to be able to use the endpoint

Each controller in the system consists of one or more of these
endpoint definitions.  By using the endpoint syntax provided by
`rest.rb`, the controllers can declare the interface they provide, and
are freed of having to perform the sort of boilerplate associated
with request handling--check parameter types, coerce values from
strings into other types, and so on.

The `main.rb` and `rest.rb` components work together to insulate the
controllers from much of the complexity of request handling.  By the
time a request reaches the code of a controller:

  * It can be sure that all required parameters are present and of the
    correct types.

  * The body of the request has been fetched, parsed into the
    appropriate type (usually a JSONModel instance--see below) and
    made available as a request parameter.

  * Any parameters provided by the client that weren't present in the
    endpoint definition have been dropped.

  * The user's session has been retrieved, and any defined access
    control checks have been carried out.

  * A connection to the database has been assigned to the request, and
    a transaction has been opened.  If the controller throws an
    exception, the transaction will be automatically rolled back.


## Controllers

As touched upon in the previous section, controllers implement the
functionality of the ArchivesSpace API by registering one or more
endpoints.  Each controller endpoint accepts a HTTP request for a
given URI, carries out the request and returns a JSON response (if
successful) or throws an exception (if something goes wrong).

Each controller lives in its own file, and these can be found in the
`backend/app/controllers` directory.  Since most of the request
handling logic is captured by the `rest.rb` module, controllers
generally don't do much more than coordinate the classes from the
model layer and send a response back to the client.


### crud_helpers.rb -- capturing common CRUD controller actions

Even though controllers are quite thin, there's still a lot of overlap
in their behaviour.  Each record type in the system supports the same
set of CRUD operations, and from the controller's point of view
there's not much difference between an update request for an accession
and an update request for a digital object (for example).

So, the `crud_helpers.rb` module pulls this commonality into a set of
helper methods that are invoked by each controller, providing methods
for the standard operations of the system.


## Models

The backend's model layer is where the action is.  The model layer's
role is to bridge the gap between the high-level JSONModel objects
(complete with their properties, nested records, references to other
records, etc.) and the underlying relational database (via the Sequel
database toolkit).  As such, the model layer is mainly concerned with
mapping JSONModel instances to database tables in a way that preserves
everything and allows them to be queried efficiently.

As with controllers, each record type has a corresponding model class,
but the individual model definitions are often quite sparse.  This is
because the different record types differ in the following ways:

  * The set of properties they allow (and their types, valid values,
    etc.)

  * The types of nested records they may contain

  * The types of relationships they may have with other record types

The first of these--the set of allowable properties--is already
captured by the JSONModel schema definitions, so the model layer
doesn't have to enforce these restrictions.  Each model can simply
take the values supplied by the JSONModel object it is passed and
assume that everything that needs to be there is there, and that
validation has already happened.

The remaining two aspects *are* enforced by the model layer, but
generally don't pertain to just a single record type.  For example, an
accession may be linked to zero or more subjects, but so can several
other record types, so it doesn't make sense for the `Accession` model
to contain the logic for handling subjects.

In practice we tend to see very little functionality that belongs
exclusively to a single record type, and as a result there's not much
to put in each corresponding model.  Instead, models are generally
constructed by combining a number of mix-ins (Ruby modules) to satisfy
the requirements of the given record type.  Features à la carte!


### ASModel and other mix-ins

At a minimum, every model includes the `ASModel` mix-in, which provides
base versions of the following methods:

  * `Model.create_from_json` -- Take a JSONModel instance and create a
    model instance (a subclass of Sequel::Model) from it.  Returns the
    instance.

  * `model.update_from_json` -- Update the target model instance with
    the values from a given JSONModel instance.

  * `model.to_json` -- Return a JSONModel instance of the appropriate
    type whose values are taken from the target model instance.
    Model classes are declared to correspond to a particular JSONModel
    instance when created, so this method can automatically return a
    JSONModel instance of the appropriate type.

These methods comprise the primary interface of the model layer:
virtually every mix-in in the model layer overrides one or all of
these to add behaviour in a modular way.

For example, the 'notes' mix-in adds support for multiple notes to be
added to a record type--by mixing this module into a model class, that
class will automatically accept a JSONModel property called 'notes'
that will be stored and retrieved to and from the database as needed.
This works by overriding the three methods as follows:

  * `Model.create_from_json` -- Call 'super' to delegate the creation to
    the next mix-in in the chain.  When it returns the newly created
    object, extract the notes from the JSONModel instance and attach
    them to the model instance (saving them in the database).

  * `model.update_from_json` -- Call 'super' to save the other updates
    to the database, then replace any existing notes entries for the
    record with the ones provided by the JSONModel.

  * `model.to_json` -- Call 'super' to have the next mix-in in the chain
    create a JSONModel instance, then pull the stored notes from the
    database and poke them into it.

All of the mix-ins follow this pattern: call 'super' to delegate the
call to the next mix-in in the chain (eventually reaching ASModel),
then manipulate the result to implement the desired behaviour.


### Nested records

Some record types, like accessions, digital objects, and subjects, are
*top-level records*, in the sense that they are created independently
of any other record and are addressable via their own URI.  However,
there are a number of records that can't exist in isolation, and only
exist in the context of another record.  Other records can appear both
as top-level records and within another record.  When one record can
contain instances of another record, we call them *nested records*.

To give an example, the `date` record type is nested within an
`accession` record (the `dates` property contains a list of `date`
records).  When the model layer is asked to save a JSONModel instance
containing nested records, it must pluck out those records, save them
in the appropriate database table, and ensure that linkages are
created within the database to allow them to be retrieved later.

This happens often enough that it would be tedious to write code for
each model to handle its nested records, so the ASModel mix-in
provides a declaration to handle this automatically.  For example, the
`accession` model uses a definition like:

     base.def_nested_record(:the_property => :dates,
                            :contains_records_of_type => :date,
                            :corresponding_to_association  => :date,
                            :always_resolve => true)

which instructs the `Accession` model to look for a property in the
JSONModel instance called 'dates' and save them to the database in the
manner described above.  The `always_resolve` parameter tells it how
to handle these records when turning them back into JSONModel
instances: when `true`, the full record is inlined into the parent
document, and then `false`, just a URI reference is included.


### Relationships

Relationships are similar enough to nested records to be worrying, but
have so far resisted assimilation attempts.  A relationship is a link
between two top-level records where the link has zero or more
properties of its own.  For example, the `Event` model can be related
to several different types of records:

     define_relationship(:name => :link,
                         :json_property => 'linked_records',
                         :contains_references_to_types => proc {[Accession, Resource, ArchivalObject]})

The JSONModel schema for events states that the 'linked_records'
property must look like:

    linked_records: [{ref: '/repositories/123/accessions/456', role: 'authorizer'}, ...]

That is, it must be an array of objects with 'ref' and 'role' keys set
to suitable values.  The `define_relationship` definition
automatically makes use of the appropriate join tables in the database
to store this relationship and retrieve it later as needed. 


=======================================================================

Topics worth talking about:

  - optimistic concurrency control
  - validations
  - the global repository
  - the permissions model
  - webhooks
  - the indexer
  - migrations
