# frozen_string_literal: true

source 'https://rubygems.org'

# Gemfile for supporting rake tasks
gem 'git'
gem 'github_api'
gem 'rake'

gem 'rubocop', :group => :rubocop
gem 'thor', :group => [:docs, :thor]
gem 'yard', :group => :docs
gem 'erb', :group => :docs
gem 'cgi', '0.3.1', :group => :docs
gem 'csv', :group => :docs

backend_gemfile = File.expand_path('./backend/Gemfile', File.dirname(__FILE__))

if File.exist?(backend_gemfile)
  self.instance_eval(File.read(backend_gemfile), backend_gemfile, 1)
else
  raise "Cannot find backend Gemfile"
end

# Convert LESS to SCSS
gem 'less2sass'
