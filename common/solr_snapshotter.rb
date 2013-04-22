require 'net/http'

class SolrSnapshotter

  def self.log(level, msg)
    if defined?(Log)
      Log.send(level, msg)
    else
      $stderr.puts("#{level.to_s.upcase}: #{msg}")
    end
  end

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
        log(:info, "Expiring old Solr snapshot: #{backup_dir}")
        FileUtils.rm_rf(backup_dir)
      else
        log(:info, "Too cowardly to delete: #{backup_dir}")
      end
    end

  end


  def self.latest_snapshot
    latest = Dir.glob(File.join(AppConfig[:solr_index_directory], "snapshot.*")).sort.last
  end


  def self.snapshot_locked?(snapshot)
    !Dir.glob(File.join(snapshot, "*.lock")).empty?
  end


  def self.snapshot(identifier = nil)
    identifier ||= Time.now.to_i

    target = File.join(AppConfig[:solr_backup_directory], "solr.#{identifier}")

    FileUtils.mkdir_p(target)

    FileUtils.cp_r(File.join(AppConfig[:data_directory], "indexer_state"),
                   target)

    most_recent = self.latest_snapshot

    response = Net::HTTP.get_response(URI.join(AppConfig[:solr_url],
                                               "/replication?command=backup&numberToKeep=1"))

    if response.code == '200'
      10.times do
        break if self.latest_snapshot != most_recent
        log(:info, "waiting for new Solr snapshot to be created")
        sleep 5
      end

      raise "Snapshot wasn't created" if self.latest_snapshot == most_recent

      snapshot = self.latest_snapshot
      max_wait_time = 1 * 60 * 60
      started_waiting_at = Time.now.to_i

      while (snapshot_locked?(snapshot) &&
             (Time.now.to_i - started_waiting_at) < max_wait_time)
        log(:info, "waiting for snapshot to finish writing")
        sleep 5
      end

      raise "Snapshot is still locked!" if snapshot_locked?(snapshot)

      FileUtils.mv(snapshot, target)

      self.expire_snapshots
    else
      FileUtils.rm_rf(target)
      raise "Solr snapshot failed: #{response.body}"
    end
  end

end
