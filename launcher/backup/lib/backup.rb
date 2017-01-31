require 'cgi'
require 'fileutils'
require 'pathname'
require 'solr_snapshotter'
require 'config/config-distribution'
require_relative '../../launcher_init'
require_relative 'trollop'
require 'zip/zip'
require 'tempfile'
require 'uri'
require 'net/http'
require 'asutils'

class ArchivesSpaceBackup

  def to_archive_path(path, basedir)
    base_path = Pathname.new(basedir)
    File.join(File.basename(basedir),
              Pathname.new(path).relative_path_from(base_path).to_path)
  end


  def add_whole_directory(dir, zipfile)
    Dir.glob(File.join(dir, "**", "*")).each do |path|
      zipfile.add(to_archive_path(path, dir), path)
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
          return outfile
        end
      rescue
        $stderr.puts "mysqldump not run: #{$!}"
      end
    end

    nil
  end


  def create_demodb_snapshot
    if AppConfig[:db_url] == AppConfig.demo_db_url
      File.write(AppConfig[:demodb_snapshot_flag], "")
      Net::HTTP.post_form(URI(URI.join(AppConfig[:backend_url], "/system/demo_db_snapshot")), {})
    end
  end


  def backup(output_file, do_mysqldump = false)
    output_file = File.absolute_path(output_file, ENV['ORIG_PWD'])

    if File.exists?(output_file)
      puts "Output file '#{output_file}' already exists!  Aborting"
      return 1
    end

    puts "#{Time.now}: Writing backup to #{output_file}"

    demo_db_backups = AppConfig[:backup_directory]
    solr_backups = AppConfig[:solr_backup_directory]
    config_dir = File.dirname(AppConfig.find_user_config) if AppConfig.find_user_config

    solr_snapshot_id = "backup-#{$$}-#{Time.now.to_i}"
    begin
      SolrSnapshotter.snapshot(solr_snapshot_id) if AppConfig[:enable_solr]
    rescue
      puts "Solr snapshot failed (#{$!}).  Aborting!"
      return 1
    end

    solr_snapshot = File.join(AppConfig[:solr_backup_directory], "solr.#{solr_snapshot_id}")

    mysql_tempfile = ASUtils.tempfile('mysqldump')

    begin
      mysql_dump = create_mysql_dump(mysql_tempfile) if do_mysqldump
      create_demodb_snapshot

      Zip::ZipFile.open(output_file, Zip::ZipFile::CREATE) do |zipfile|
        add_whole_directory(solr_snapshot, zipfile) if AppConfig[:enable_solr]
        add_whole_directory(demo_db_backups, zipfile) if Dir.exists?(demo_db_backups)
        add_whole_directory(config_dir, zipfile) if config_dir
        zipfile.add("mysqldump.sql", mysql_dump) if mysql_dump
      end
    ensure
      mysql_tempfile.close
      mysql_tempfile.delete
      FileUtils.rm_rf(File.join(AppConfig[:solr_backup_directory],
                                "solr.#{solr_snapshot_id}")) if AppConfig[:enable_solr]
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
