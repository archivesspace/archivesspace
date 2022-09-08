namespace :doc do

  desc "Generate the documentation"
  task :yard do
    puts "Generating YARD documentation"
    system(File.join("..", "build", "run"), "doc:yardoc")
  end



  desc 'Rename the YARD index file to avoid problems with Jekyll'
  task :rename_index do
    puts "Renaming the YARD index file"
    Dir.chdir('../docs') do
      files = Dir.glob('doc/**/*')
      files.each do |f|
        if File::file?(f)
          content = File.read(f)
          content.gsub!('"_index.html"', '"alpha_index.html"')
          content.gsub!('/_index.html', '/alpha_index.html')
          File.open(f, "w") do |io|
            io.write content
          end
        end
      end
      `mv doc/_index.html doc/alpha_index.html`
    end
  end

  desc 'This generates all documentation and publishes it to the doc folder'
  task :gen do
    require 'fileutils'

    puts "Removing old documentation"
    FileUtils.rm_rf("./docs/doc")

    Rake::Task["doc:yard"].invoke
    Rake::Task["doc:rename_index"].invoke

  end


end
