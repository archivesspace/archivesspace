require 'json'
require 'ashttp'

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

      if File.exist?(File.join(backup_dir, "indexer_state"))
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


  def self.last_snapshot_status
    response = ASHTTP.get_response(URI.join(AppConfig[:solr_url],
                                            "/replication?command=details&wt=json"))

    if response.code != '200'
      raise "Problem when getting snapshot details: #{response.body}"
    end

    status = JSON.parse(response.body)

    Hash[Array(status.fetch('details', {})['backup']).each_slice(2).to_a]
  end


  def self.snapshot(identifier = nil)
    retries = 5

    retries.times do |i|
      begin
        SolrSnapshotter.do_snapshot(identifier)
        break
      rescue
        log(:error, "Solr snapshot failed (#{$!}) - attempt #{i}")

        if (i + 1) == retries
          raise "Solr snapshot failed after #{retries} retries: #{$!}"
        end
      end
    end
  end


  def self.wait_for_snapshot_to_finish(starting_status, starting_snapshot)
    while true
      raise "Concurrent snapshot detected.  Bailing out!" if self.latest_snapshot != starting_snapshot

      status = self.last_snapshot_status
      break if status != starting_status

      # Wait for the backup status to be updated
      sleep 5
    end
  end


  def self.do_snapshot(identifier = nil)
    identifier ||= Time.now.to_i

    target = File.join(AppConfig[:solr_backup_directory], "solr.#{identifier}")

    FileUtils.mkdir_p(target)

    FileUtils.cp_r(File.join(AppConfig[:data_directory], "indexer_state"),
                   target)

    begin
      most_recent_status = self.last_snapshot_status
      most_recent_snapshot = self.latest_snapshot
      log(:info, "Previous snapshot status: #{most_recent_status}; snapshot: #{most_recent_snapshot}")


      response = ASHTTP.get_response(URI.join(AppConfig[:solr_url],
                                                 "/replication?command=backup&numberToKeep=1"))


      raise "Error from Solr: #{response.body}" if response.code != '200'


      # Wait for a new snapshot directory to turn up
      60.times do
        break if most_recent_snapshot != self.latest_snapshot
        log(:info, "Waiting for new snapshot directory")
        sleep 1
      end

      if most_recent_snapshot == self.latest_snapshot
        raise "No new snapshot directory appeared"
      end

      wait_for_snapshot_to_finish(most_recent_status, self.latest_snapshot)
      new_snapshot = self.latest_snapshot

      FileUtils.mv(new_snapshot, target).inspect
      self.expire_snapshots
    rescue
      raise "Solr snapshot failed: #{$!}: #{$@}"
      begin
        FileUtils.rm_rf(target)
      rescue
      end
    end
  end

end
