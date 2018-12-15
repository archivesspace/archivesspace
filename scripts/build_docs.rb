require 'fileutils'
require 'find'

indir = "./tech_docs"
outdir = "./docs/user"
FileUtils.rm_rf("#{outdir}")

# For API documentation
FileUtils.cp("API.md", "./docs/slate/source/index.md")

FileUtils::mkdir_p outdir

file_list = []
Find.find("#{indir}") do |f|
  file_list << f if f.match(/\.md\Z/)
end

file_list.each do |file|
  IO.read(open(file)).split(/^\# /).each do |sec|
      begin
        next unless sec.length > 0
        title = sec.lines.first.chomp
        puts "Processing #{title} ..."
        next unless title.length > 0
        title.gsub!("\/", " ")
        title.gsub!(/[&;?$<>#%{}|\\^~\[\]`@=:+,!\']/, "")
        permalink = "/user/#{title.downcase.gsub(" ", "-")}/"
        File.open(File.join(outdir, "#{title.downcase.gsub(" ", "-")}.md"), 'w') do |outfile|
          md = "---
title: #{title}
layout: en
permalink: #{permalink}
---"
          outfile.write(md)
          outfile.write(sec.lines.to_a[1..-1].join)
          # if permalink == "/user/configuring-archivesspace/"
          #   outfile << "```ruby\n\n"
          #   outfile << IO.read("common/config/config-defaults.rb")
          #   outfile << "```"
          # end
        end
      rescue => e
        puts outfile
        puts e.backtrace
      end
    end
end
