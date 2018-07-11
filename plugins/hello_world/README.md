# Hello World Plug-in

The `hello_world` exemplar plug-in may be referenced as a model plug-in for implementing an ArchivesSpace customization that overrides or extends the application without changing the core codebase. `hello_world` modifies the 
ArchivesSpace backend, frontend, and indexer applications, in addition to modifying the ArchivesSpace database and JSONModel schema.

This README provides an explanation for each file that makes up the `hello_world` plug-in, arranged in alphabetical order by directory. For a more general explanation of how plug-ins can be configured in ArchivesSpace, refer to 
the [ArchivesSpace Plug-ins README](http://archivesspace.github.io/archivesspace/user/archivesspace-plug-ins-readme/)

## backend

Overrides or extends the ArchivesSpace backend application.

### controllers

ArchivesSpace backend controllers define backend API endpoints.

    plugins/hello_world/backend/controllers/hello_world.rb

This file adds two ArchivesSpace API endpoints. 

The first, `/helloworld`, accepts a single parameter, `who`. The controller calls the `WhoSaidHello` model to create an entry in the ArchivesSpace database and returns a reply saying "Hello" followed by the value of the `who` 
parameter. 

The second, `/whosaidhello`, calls the `WhoSaidHello` model to return all of the entries from the `whosaidhello` table in the ArchivesSpace database using the `hello_world` JSONModel schema.

### model

ArchivesSpace backend models define database mapping models.

    plugins/hello_world/backend/model/mixins/hello_worlds.rb

This file defines a `HelloWorlds` module, which can be used as a mixin to extend other models to add a `:hello_worlds` property, containing an array of `:hello_world` records, to that model.

    plugins/hello_world/backend/model/accession.rb

This file extends the default ArchivesSpace accession model to include the `HelloWorlds` mixin.

    plugins/hello_world/backend/model/digital_object.rb

This file extends the default ArchivesSpace digital object model to include the `HelloWorlds` mixin.

    plugins/hello_world/backend/model/resource.rb

This file extends the default ArchivesSpace resource model to include the `HelloWorlds` mixin.

    plugins/hello_world/backend/model/who_said_hello.rb

This file defines a `WhoSaidHello` model, corresponding to the `:whosaidhello` table in the database and the `:hello_world` JSONModel schema.

## frontend

Overrides or extends the ArchivesSpace staff interface.

### assets

The assets directory contains static files, such as images, CSS, and JavaScript, to be used in the staff interface.

    plugins/hello_world/frontend/assets/earth.jpg

This file adds a static asset, in this case a JPEG image of the planet Earth, to be used in the staff interface.

### controllers

    plugins/hello_world/frontend/controllers/hello_world_controller.rb

This file defines a `HelloWorldController` for the staff interface. The controller defines two actions, `index` and `new`. 

When the `HelloWorldController::index` action is invoked by a page on the staff interface, the application loads the `plugins/hello_world/frontend/views/hello_world/index.html.erb` page and establishes a `@whosaidhello` variable, 
containing the reponse of a call to the `/whosaidhello` API endpoint, for use on the `index` page.

When the `HelloWorldController::new` action is invoked by a page on the staff interface, the controller makes a call to the `/helloworld` API endpoint, passing the name of the current logged in user as the `who` parameter, 
establishes a `@whosaidhello` variable containing the response of a call to the `/whosaidhello` API endpoint, and then renders the `hello_world` index page.

### locales

The locales directory contains locale translations for use in the staff interface.

    plugins/hello_world/frontend/locales/en.yml

This file contains English language translations for labels, tooltips, actions, and other components of the staff interface.

    plugins/hello_world/frontend/locales/fr.yml

This file contains French language translations for labels, tooltips, actions, and other components of the staff interface.

### views

    plugins/hello_world/frontend/views/hello_world/index.html.erb

This file contains the `hello_world` index page that is rendered by the `HelloWorldController::index` action. The page loads the `earth.jpg` file from the `frontend/assets` directory. It then displays a toolbar with a button that 
will invoke the `HelloWorldController::new`. Finally, the page renders a table displaying entries from the `:whosaidhello` table, including who said hello and when.

    plugins/hello_world/frontend/views/hello_worlds

This directory includes two files: `_show.html.erb` and `_template.html.erb` that use the ArchivesSpace plugin architecture to add subrecords to the record types that are configured as parents of `hello_worlds` (accessions, 
resources, and digital objects) in the `plugins/config.yml` file detailed below. The respective show and form ERB templates for each parent record type include calls to the `PluginHelper` module's `show_plugins_for` and 
`form_plugins_for` functions, which locate the `_show.html.erb` and `_template.html.erb` templates for plugins that are configured as children of that record type.

## indexer

Overrides or extends the ArchivesSpace indexer application.

    plugins/hello_world/indexer/hello_world_indexer.rb

This file uses the ArchivesSpace `IndexerCommon` class's `add_indexer_initialize_hook` function to add a new hook to the ArchivesSpace indexer application that will index each entry in a record's `hello_worlds` array to facilitate 
searching across `hello_world` entries in the staff interface. 

## migrations

Overrides or extends the ArchivesSpace database.

    plugins/hello_world/migrations/001_hello_world_schema.rb

This file establishes a database migration that will create the `:whosaidhello` table, including a `who` column and foreign keys for the record types with which a `hello_world` subrecord might be associated (accessions, resources, 
and digital objects). This is the table that is referenced in the first line of the `plugins/hello_world/backend/model/who_said_hello.rb` file, establishing the relationship between the `:hello_world` JSONModel schema and the 
`:whosaidhello` database table.

```ruby
class WhoSaidHello < Sequel::Model(::whosaidhello)
```

## schemas

Overrides or extends the ArchivesSpace JSONModel schema.

    plugins/hello_world/schemas/accession_ext.rb

This file extends the JSONModel schema found at `common/schemas/accession.rb` to add a `hello_worlds` property containing an array of `:hello_world` objects.

    plugins/hello_world/schemas/digital_object_ext.rb

This file extends the JSONModel schema found at `common/schemas/digital_object.rb` to add a `hello_worlds` property containing an array of `:hello_world` objects.

    plugins/hello_world/schemas/hello_world.rb

This file defines the `:hello_world` JSONModel schema object, which contains two properties: `uri` and `who`. This is the definition for the object that is added to the `hello_worlds` array in the `accession_ext.rb`, 
`digital_object_ext.rb`, and `resource_ext.rb` files located within the `schemas` directory.

    plugins/hello_world/schemas/resource_ext.rb

This file extends the JSONModel schema found at `common/schemas/resource.rb` to add a `hello_worlds` property containing an array of `:hello_world` objects.

## config
    
    plugins/hello_world/config.yml

This file configures the `hello_world` plugin. It names `hello_world` as a `repository_menu_controller`, which will add an entry to the Plug-ins menu of the frontend application's Repository toolbar that will invoke the  
`HelloWorldController::index` action, detailed above in `plugins/hello_world/frontend/controllers/hello_world_controller.rb`. The `config.yml` file further configures `hello_worlds` as a child of the `accession`, `resource`, and 
`digital_object`, which is the method by which the `_show.html.erb` and `_template.html.erb` located in `plugins/frontend/app/views/hello_worlds` are added to the respective record type's show and form templates as described 
above.
