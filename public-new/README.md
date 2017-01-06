# Running a devserver using JRuby

Check out this repository, then:

     # Run the ArchivesSpace devserver on port 4567
     cd /path/to/archivesspace; build/run devserver

     # Now run the PUI application's devserver
     cd pui-checkout-dir

     # Download JRuby and gems
     build/run bootstrap

     # Run the devserver listening on port 4000
     build/run devserver

If you prefer MRI Ruby, it should run using that too.  You might just
need to remove `Gemfile.lock` prior to running bundler to install the
gems.  Maybe there's a way we can get these to peacefully coexist...

# Using Pry

One disadvantage of launching the devserver from Ant is that it messes
with your console, disabling input echo.  If you're trying to use
interactive tools like Pry, that's a bit of an inconvenience.

To get around this, running `build/run devserver` will also write out
a shell script (to `build/devserver.sh`) that captures the command,
working directory and environment variables needed to run a
devserver.  As long as you run `build/run devserver` once, you can run
`build/devserver.sh` thereafter to have a more normal console
experience.

# Configuration and Text Customization

At the top-level of this project, there is a configuration file called
`config/config.rb` whose format matches that of ArchivesSpace.  Here
you can add (or override) configuration options for your local
install.

To see the full list of available options, see the file
[`app/archivesspace-public/app/lib/config_defaults.rb`](app/archivesspace-public/app/lib/config_defaults.rb)

See the [`config/config.rb.example`](config/config.rb.example) file for implementation examples.

In addition, you can override some default text values found in [`app/archivesspace-public/config/locales`](app/archivesspace-public/config/locales) -- for example, the site title -- by creating an 
`app/archivesspace-public/config/custom/locales` directory, and placing the appropriate `.yml` files[s] there.  

## Preserving Patron Privacy

The **:block_referrer** key in the configuration file (default: **true**) determines whether the full referring URL is 
transmitted when the user clicks a link to a website outside the web domain of your instance of ArchivesSpace.  This 
protects your patrons from tracking by that site.

## Main Navigation Menu

You can choose not to display one or more of the links on the main (horizontal) navigation menu, 
either globally or by repository, if you have more than one repository.  You manage this through the
`config/config.rb` file; [`config/config.rb.example`](config/config.rb.example) shows examples of these.

## Repository Customization

### Display of "badges" on the Repository page

You can configure which badges appear on the Repository page, both globally or by repository.  Again,
[`config/config.rb.example`](config/config.rb.example) shows examples.

### Addition of a "lead paragraph"
 
You can also use the custom `.yml` files, described above, to add a custom "lead paragraph" (including html markup) for one or more of your repositories, keyed to the repository's code.  

For example, if your repository, `My Wonderful Repository` has a code of `MWR`, this is what you might see in the
custom `en.yml`:
```
en:
  repos:
    mwr:
      lead_graph: This <strong>amazing</strong> repository has so much to offer you!
```


## Activation of the "Request" button on archival object pages

You can configure, both globally or by repository, whether the "Request" button is active on 
archival object pages for objects that don't have an associated Top Container.
See [`config/config.rb.example`](config/config.rb.example) for examples.


## License

ArchivesSpace is released under the [Educational Community License,
version 2.0](http://opensource.org/licenses/ecl2.php). See the
[COPYING](COPYING) file for more information.
