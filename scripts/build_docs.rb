require 'fileutils'

outdir = "./docs/user/"
FileUtils::mkdir_p outdir


[ "CUSTOMIZING_THEMING.md", "ARCHITECTURE.md","README_TUNING.md", "./build/BUILD_README.md", "./selenium/SELENIUM_README.md", "README.md", "UPGRADING.md", "README_HTTPS.md",  "README_PREFIX.md", "README_SOLR.md",
  "./plugins/PLUGINS_README.md", "plugins/newrelic/README_NEWRELIC.md" ].each do |file|
  IO.read(open(file)).split(/^\# /).each do |sec|
      begin 
        next unless sec.length > 0 
        title = sec.lines.first.chomp
        puts "Processing #{title} ..." 
        next unless title.length > 0 
        permalink = "/user/#{title.downcase.gsub(" ", "-")}/"
        File.open(File.join(outdir, "#{title.downcase.gsub(" ", "-")}.md"), 'w') do |file|
          md = <<EOF
---
title: #{title} 
layout: en
permalink: #{permalink} 
---
EOF
          file << md 
          file << sec.lines.to_a[1..-1].join
        end
      rescue => e
        puts file
        puts e.backtrace
      end
    end
end

# now let's take the config and add it to the configuration file.
config = IO.read('common/config/config-defaults.rb')
intro = "\nBelow are the configuration settings with their default values:\n"
File.open(File.join(outdir, "configuring-archivesspace.md") , 'a' ) { |f| f << "#{intro}\n```ruby\n#{config}\n```" }

msg = <<EOF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The documentation has been generated. You made need to rebuild the Jekyll and 
Slate pages. These cannot use jRuby, so you have to use a CRuby. For Jekyll, in 
the ./docs directly, use the :
$ ./bin/jekyll build

command. For Slate, in the docs/slate director, use: 
$ ./bin/middleman build

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EOF

puts msg

