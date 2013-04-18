require 'net/http'

class SolrSnapshotter

  def self.expire_snapshots
    backups = []
    backups_dir = AppConfig[:solr_backup_directory]

    Dir.foreach(backups_dir) do |filename|
      if filename =~ /^solr\.[0-9]+$/
        backups << File.join(backups_dir, filename)
      end
    end

    victims = backups.sort.reverse.drop(AppConfig[:solr_backup_number_to_keep])

    victims.each do |backup_dir|

      if File.exists?(File.join(backup_dir, "indexer_state"))
        Log.info("Expiring old Solr snapshot: #{backup_dir}") if defined?(Log)
        FileUtils.rm_rf(backup_dir)
      else
        Log.warn("Too cowardly to delete: #{backup_dir}") if defined?(Log)
      end
    end

  end


  def self.snapshot(identifier = nil)
    identifier ||= Time.now.to_i

    target = File.join(AppConfig[:solr_backup_directory], "solr.#{identifier}")

    FileUtils.mkdir_p(target)

    FileUtils.cp_r(File.join(AppConfig[:data_directory], "indexer_state"),
                   target)

    response = Net::HTTP.get_response(URI.join(AppConfig[:solr_url],
                                               "/replication?command=backup&numberToKeep=1"))

    if response.code == '200'
      latest = Dir.glob(File.join(AppConfig[:solr_index_directory], "snapshot.*")).sort.last

      FileUtils.mv(latest, target)

      self.expire_snapshots
    else
      FileUtils.rm_rf(target)
      raise "Solr snapshot failed: #{response.body}"
    end
  end

end
