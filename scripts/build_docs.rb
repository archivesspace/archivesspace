require 'fileutils'

outdir = "./docs/user/"
FileUtils::mkdir_p outdir
FileUtils.cp("API.md", "./docs/slate/source/index.md")



[ "CUSTOMIZING_THEMING.md", "ARCHITECTURE.md","README_TUNING.md", "./build/BUILD_README.md", "./selenium/SELENIUM_README.md", "README.md", "UPGRADING.md", "README_HTTPS.md",  "README_PREFIX.md", "README_SOLR.md",
  "./plugins/PLUGINS_README.md", "README_RELEASE.md", "plugins/newrelic/README_NEWRELIC.md" ].each do |file|
  IO.read(open(file)).split(/^\# /).each do |sec|
      begin 
        next unless sec.length > 0 
        title = sec.lines.first.chomp
        puts "Processing #{title} ..." 
        next unless title.length > 0 
        permalink = "/user/#{title.downcase.gsub(" ", "-")}/"
        File.open(File.join(outdir, "#{title.downcase.gsub(" ", "-")}.md"), 'w') do |outfile|
          md = <<EOF
---
title: #{title} 
layout: en
permalink: #{permalink} 
---
EOF
          outfile << md 
          outfile << sec.lines.to_a[1..-1].join
          if permalink == "/user/configuring-archivesspace/"
            outfile << "```ruby\n\n"
            outfile << IO.read("common/config/config-defaults.rb") 
            outfile << "```"
          end
        end
      rescue => e
        puts outfile
        puts e.backtrace
      end
    end
end

$stderr.puts "*" * 100
$stderr.puts "You're documentation is almost ready. Now you must build slate and jekyll."
$stderr.puts "For Slate:"
$stderr.puts "$ rm -r docs/api && cd docs/slate && ./bin/middleman build && mv build ../api && cd -"
$stderr.puts "And then Jekyll:"
$stderr.puts "$ cd docs && ./bin/jekyll build && cd -"
$stderr.puts "Then push it to GH and profit!"
$stderr.puts "*" * 100
