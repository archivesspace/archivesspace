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

## Configuration

At the top-level of this project, there is a configuration file called
`config/config.rb` whose format matches that of ArchivesSpace.  Here
you can add (or override) configuration options for your local
install.

To see the full list of available options, see the file
[`app/archivesspace-public/app/lib/config_defaults.rb`](app/archivesspace-public/app/lib/config_defaults.rb)

See the [`config/config.rb.example`](config/config.rb.example) file for implementation examples.

### Main Navigation Menu

You can choose not to display one or more of the links on the main (horizontal) navigation menu, 
either globally or by repository, if you have more than one repository.  

### Display of "badges" on the Repository page

You can configure which badges appear on the Repository page, both globally or by repository.

### Activation of the "Request" button on archival object pages

You can configure, both globally or by repository, whether the "Request" button is active on 
archival object pages for objects that don't have an associated Top Container.



## License

ArchivesSpace is released under the [Educational Community License,
version 2.0](http://opensource.org/licenses/ecl2.php). See the
[COPYING](COPYING) file for more information.
