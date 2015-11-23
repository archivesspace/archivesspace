require 'fileutils'

outdir = "./docs/user/"
FileUtils::mkdir_p outdir


[ "CUSTOMIZING_THEMING.md", "ARCHITECTURE.md", "./build/BUILD_README.md", "./selenium/SELENIUM_README.md", "README.md", "UPGRADING.md", "README_HTTPS.md",  "README_PREFIX.md", "README_SOLR.md",
  "./plugins/PLUGINS_README.md", "plugins/newrelic/README_NEWRELIC.md" ].each do |file|
    IO.read(open(file)).split(/^\# /).each do |sec|
      begin 
        next unless sec.length > 0 
        title = sec.lines.first.chomp
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
