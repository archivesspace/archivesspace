#!/usr/bin/env ruby
require 'optparse'

options = {:dry => false,
           :debug => false,
           :relaxed => false,
           :repo_id => 2,
           :vocab_id => 1}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: import.rb [options] IMPORTER_ARGS"

  opts.on( '-d', '--debug', 'Debug mode' ) do
    options[:debug] = true
  end
  opts.on( '-f', '--flags FLAG(,FLAG)*', Array, 'Importer-specific flags' ) do|flags|
    options[:importer_flags] = flags
  end
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
  opts.on( '-i', '--importer KEY', 'Select an importer' ) do|importer|
    options[:importer] = importer
  end
  opts.on( '-l', '--list-importers', 'List available importers') do
    options[:list] = true
  end
  opts.on( '-n', '--dry-run', 'Do a dry run' ) do
    options[:dry] = true
  end

  opts.on( '-p', '--batch-path PATH', 'Make a snapshot of the batch request at PATH') do |path|
    options[:batch_path] = options[:dry] && path
  end

  opts.on( '-q', '--quiet', 'No logging' ) do
    options[:quiet] = true
  end
  opts.on( '-r', '--repository REPO-ID', 'Override default repository id') do|repo_id|
    options[:repo_id] = repo_id
  end
  opts.on( '-w', '--vocabulary VOCAB-ID', 'Override default vocabulary id') do|vocab_id|
    options[:vocab_id] = repo_id
  end
  opts.on( '-s', '--source-file PATH', 'Import from file at PATH' ) do|path|
    options[:input_file] = path
  end
end

optparse.parse!

unless options[:importer] || options[:list]
  puts "No importer specified; try using the --help option to see script parameters"
  exit
end

if options[:dry] || options[:list]
  $dry_mode = true
end

require_relative 'lib/bootstrap'

if options[:debug]
  $log.level = Logger::DEBUG
end

options[:log] = $log


if options[:list]
  puts ASpaceImport::Importer.list
  exit
end


if options[:importer]
  ASpaceImport::Importer.create_importer(options).run_safe do |message|
    if message.has_key?('saved')
      puts "Saved #{message['saved'].length} records."
      message['saved'].each do |logical_uri, uri_and_id|
        puts "#{uri_and_id[0]}\n"
      end
    else
      puts "Server response: #{message.to_s}"
    end
  end
end





