require 'fileutils'
require 'find'

FileUtils.rm_rf("./docs/doc")

git_url = "git@github.com:archivesspace/tech-docs.git"
localFolder = "./tech_docs"

FileUtils.rm_rf("#{localFolder}") if File.directory?("#{localFolder}")

system("git clone #{git_url} #{localFolder}")

FileUtils.rm_rf("#{localFolder}/_REMOVED")
FileUtils.rm_rf("#{localFolder}/.git")
FileUtils.rm("#{localFolder}/.gitignore")
FileUtils.rm("#{localFolder}/LICENSE")
FileUtils.cp_r("#{localFolder}/images/.", './docs/assets/images')
FileUtils.cp_r("#{localFolder}/development/license_agreements/.", './docs/assets')
FileUtils.rm_rf("#{localFolder}/images")
FileUtils.rm_rf("#{localFolder}/development/license_agreements")

Find.find("#{localFolder}") do |f|
  FileUtils.rm(f) if ((f.include? "_original") || (f.include? "_ORIGINAL"))
end
