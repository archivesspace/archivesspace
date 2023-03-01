require 'cgi'
require 'fileutils'
require 'pathname'
require 'config/config-distribution'
require_relative '../../launcher_init'
require_relative 'trollop'
require 'tempfile'
require 'uri'
require 'ashttp'
require 'asutils'

class ArchivesSpaceBackup

  def to_archive_path(path, basedir)
    base_path = Pathname.new(basedir)
    result = File.join(File.basename(basedir),
                       Pathname.new(path).relative_path_from(base_path).to_path)

    # Directory names end in a slash
    if File.directory?(path) && !result.end_with?('/')
      result += '/'
    end

    result
  end


  def add_single_entry(dir, path, zipfile, entry_name = nil)
    entry_name ||= to_archive_path(path, dir)
    entry = zipfile.put_next_entry(java.util.zip.ZipEntry.new(entry_name))

    unless File.directory?(path)
      fh = java.io.FileInputStream.new(path)

      begin
        buf = Java::byte[4096].new
        while (len = fh.read(buf)) >= 0
          zipfile.write(buf, 0, len)
        end
      ensure
        fh.close
      end
    end
  end

  def add_whole_directory(dir, zipfile)
    Dir.glob(File.join(dir, "**", "*")).each do |path|
      add_single_entry(dir, path, zipfile)
    end
  end

  def create_mysql_dump(outfile)
    if AppConfig[:db_url] =~ /jdbc:mysql/
      db_uri = URI.parse(AppConfig[:db_url][5..-1])

      params = CGI::parse(db_uri.query)

      host     = db_uri.host
      port     = db_uri.port
      username = params['user'].first
      password = params['password'].first
      database = db_uri.path.gsub('/', '')

      mysqldump_cmd = [
        "mysqldump",
        "--host=#{host}",
        "--port=#{port}",
        "--user=#{username}",
        "--password=#{password}",
        "--routines",
        "--single-transaction",
        "--quick",
      ]
      mysqldump_cmd << "--master-data=2" if AppConfig[:mysql_binlog]
      mysqldump_cmd << database
      begin
        IO.popen(mysqldump_cmd) do |io|
          while true
            chunk = io.read(4096)
            break if chunk.nil?
            outfile.write(chunk)
          end
        end

        outfile.close

        if $? == 0
          return outfile.path
        end
      rescue
        $stderr.puts "mysqldump not run: #{$!}"
      end
    end

    nil
  end

  def backup(output_file, do_mysqldump = false)
    output_file = File.absolute_path(output_file, ENV['ORIG_PWD'])

    if File.exist?(output_file)
      puts "Output file '#{output_file}' already exists!  Aborting"
      return 1
    end

    puts "#{Time.now}: Writing backup to #{output_file}"
    puts "NOTICE: Solr snapshotting is no longer supported as of version 3.2"

    demo_db_backups = AppConfig[:backup_directory]
    config_dir = File.dirname(AppConfig.find_user_config) if AppConfig.find_user_config

    mysql_tempfile = ASUtils.tempfile('mysqldump')

    begin
      mysql_dump = create_mysql_dump(mysql_tempfile) if do_mysqldump

      zipfile = java.util.zip.ZipOutputStream.new(java.io.FileOutputStream.new(output_file))
      begin
        add_whole_directory(demo_db_backups, zipfile) if Dir.exist?(demo_db_backups)
        add_whole_directory(config_dir, zipfile) if config_dir
        add_single_entry(File.dirname(mysql_dump), mysql_dump, zipfile, "mysqldump.sql") if mysql_dump
      ensure
        zipfile.close
      end
    ensure
      mysql_tempfile.close
      mysql_tempfile.delete
    end

    0
  end

end


def main
  p = Trollop::Parser.new do
    opt :output, "Output filename (/path/to/somename.zip)", :type => :string
    opt :mysqldump, "If specified, run mysqldump and include its output in the backup .zip file"
  end

  opts = Trollop::with_standard_exception_handling p do
    raise Trollop::HelpNeeded if ARGV.empty?
    p.parse(ARGV)
  end

  if opts[:output].nil?
    puts "You must specify an output file with the --output option"
    return 0
  end

  ArchivesSpaceBackup.new.backup(opts[:output], opts[:mysqldump])
end


exit(main || 0)
