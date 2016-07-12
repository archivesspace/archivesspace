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

## Configuration

At the top-level of this project, there is a configuration file called
`config/config.rb` whose format matches that of ArchivesSpace.  Here
you can add (or override) configuration options for your local
install.

To see the full list of available options, see the file
[`app/archivesspace-public/app/lib/config_defaults.rb`](app/archivesspace-public/app/lib/config_defaults.rb)
