require 'rbconfig'
require 'socket'
require 'ashttp'
require 'asutils'
require 'English'
require 'securerandom'
require File.expand_path('indexer/app/lib/periodic_indexer', ASUtils.find_base_directory)
require File.expand_path('indexer/app/lib/pui_indexer', ASUtils.find_base_directory)


# A set of utils to start/stop the various servers that make up Aspace.
# Used for running tests.
# rubocop:disable Lint/HandleExceptions, Lint/RescueWithoutErrorClass
module TestUtils
  def self.kill(pid)
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      system("taskkill /pid #{pid} /f /t")
    else
      begin
        Process.kill(15, pid)
        Process.waitpid(pid)
      rescue
        # Already dead.
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def self.wait_for_url(url, out = nil)
    24.times do |idx|
      begin
        uri = URI(url)
        req = Net::HTTP::Get.new(uri.request_uri)
        ASHTTP.start_uri(uri, open_timeout: 60, read_timeout: 60) do |http|
          http.request(req)
        end
        break
      rescue
        # Keep trying
        raise "Giving up waiting for #{url}" if idx > 22
        puts "Waiting for #{url} (#{$ERROR_INFO.inspect})"
        if idx == 10 && !out.nil? && File.file?(out)
          puts "Server is taking a long time to startup, dumping last 50 lines of log:"
          puts IO.readlines(out)[-50..-1]
        end
        sleep(5)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def self.build_config_string(config)
    java_opts = ENV.fetch('JAVA_OPTS', '')
    config.each do |key, value|
      java_opts += " -Daspace.config.#{key}=#{value}"
    end

    # Pass through any system properties from the parent JVM too
    java.lang.System.getProperties.each do |property, value|
      next unless property =~ /aspace.config.(.*)/
      key = Regexp.last_match(1)
      java_opts += " -Daspace.config.#{key}=#{value}" unless config.key?(key)
    end

    ' ' + java_opts
  end

  def self.find_ant
    fullpath = ''
    [nil, '..', '../..'].each do |root|
      base = ASUtils.find_base_directory(root)
      fullpath = File.join(File.realpath(base), 'build', 'run')
      break if File.exist? fullpath
    end
    fullpath
  end

  def self.start_backend(port, config = {}, config_file = nil)
    db_url = config.delete(:db_url)
    java_opts = build_config_string(config)
    java_opts += " -Daspace.config=#{config_file}" if config_file

    # although we are testing, we need to pass the db we are using
    # through as aspace.db_url.dev because the backend:devserver
    # ant task is hardcoded to used that build arg
    build_args = ['backend:devserver:integration',
                  "-Daspace.backend.port=#{port}",
                  '-Daspace_integration_test=1',
                  "-Daspace.db_url.dev=#{db_url}"]
    java_opts += ' -Xmx1024m'

    puts "Spawning backend with opts: #{java_opts}"
    logfile = File.join(ASUtils.find_base_directory, "ci_logs", "backend_test_log.out")
    process_log = File.join(ASUtils.find_base_directory, "ci_logs", "backend_process.out")
    process_options = { :out => process_log, :err => process_log }
    env = { 'JAVA_OPTS' => java_opts, 'APPCONFIG_BACKEND_LOG' => logfile, 'INTEGRATION_LOGFILE' => process_log }
    pid = Process.spawn(env, find_ant, *build_args, process_options)

    TestUtils.wait_for_url("http://localhost:#{port}", logfile)
    puts "Backend started with pid: #{pid}"

    pid
  end

  def self.start_frontend(port, backend_url, config = {}, config_file = nil)
    java_opts = "-Daspace.config.backend_url=#{backend_url}"
    java_opts += build_config_string(config)
    java_opts += " -Daspace.config=#{config_file}" if config_file

    build_args = ['frontend:devserver:integration',
                  "-Daspace.frontend.port=#{port}"]
    java_opts += ' -Xmx1512m'

    puts "Spawning frontend with opts: #{java_opts}"
    pid = Process.spawn({ 'JAVA_OPTS' => java_opts, 'TEST_MODE' => 'true' },
                        find_ant, *build_args)

    TestUtils.wait_for_url("http://localhost:#{port}")
    puts "Frontend started with pid: #{pid}"

    pid
  end

  def self.start_public(port, backend_url, config = {})
    java_opts = "-Daspace.config.backend_url=#{backend_url}"
    config.each do |key, value|
      java_opts += " -Daspace.config.#{key}=#{value}"
    end

    pid = Process.spawn({ 'JAVA_OPTS' => java_opts, 'TEST_MODE' => 'true' },
                        find_ant, 'public:devserver:integration',
                        "-Daspace.public.port=#{port}")

    TestUtils.wait_for_url("http://localhost:#{port}")
    puts "Public started with pid: #{pid}"

    pid
  end

  def self.free_port_from(port)
    server = TCPServer.new('127.0.0.1', port)
    server.close
    port
  rescue Errno::EADDRINUSE
    port += 1
    retry
  end

  # the first time a factory is created, backend session will be set;
  # rather than have the indexer login, use the same session
  module SpecIndexing
    def self.get_indexer
      @periodic ||= PeriodicIndexer.new(AppConfig[:backend_url]).instance_eval do
        def login
          @current_session = JSONModel::HTTP.current_backend_session
          @current_session
        end

        self
      end
    end

    def self.get_pui_indexer
      @pui ||= PUIIndexer.new(AppConfig[:backend_url]).instance_eval do
        def login
          @current_session = JSONModel::HTTP.current_backend_session
          @current_session
        end

        self
      end
    end

    # A periodic round queries every record type in every repository, so rounds
    # slow down as a run creates repositories. Once enabled, a round only scans
    # the repositories written to through JSONModel::HTTP since that indexer's
    # last round, plus the first one (global types are indexed with it), or all
    # of them after a write outside a repository. A skipped repository keeps its
    # indexer mtimes, so its next scan still picks up everything since.
    module WrittenRepositories
      @lock = Mutex.new
      @pending = Hash.new { |h, k| h[k] = :all }

      class << self
        attr_accessor :enabled

        def record_write(path)
          repo_id = path[%r{\A/repositories/(\d+)/}, 1]
          return if repo_id.nil? && path.start_with?('/users/')

          @lock.synchronize do
            @pending.each do |indexer, scope|
              if scope == :all
                next
              elsif repo_id
                scope << repo_id.to_i
              else
                @pending[indexer] = :all
              end
            end
          end
        end

        def scan(indexer)
          return yield unless enabled

          scope = @lock.synchronize do
            taken = @pending[indexer]
            @pending[indexer] = Set.new
            taken
          end
          Thread.current[:spec_index_repository_scope] = scope
          yield
        ensure
          Thread.current[:spec_index_repository_scope] = nil
        end
      end

      module HTTPHook
        def do_http_request(url, req, &block)
          WrittenRepositories.record_write(url.path) unless req.is_a?(Net::HTTP::Get)
          super
        end
      end

      module RepositoryListFilter
        def all(*args)
          repositories = super
          scope = Thread.current[:spec_index_repository_scope]
          return repositories if scope.nil? || scope == :all

          repositories.select.with_index { |repository, i| i.zero? || scope.include?(repository.id) }
        end
      end
    end

    def self.scan_written_repositories_only
      require 'set'
      JSONModel::HTTP.singleton_class.prepend(WrittenRepositories::HTTPHook)
      JSONModel(:repository).singleton_class.prepend(WrittenRepositories::RepositoryListFilter)
      WrittenRepositories.enabled = true
    end

    module Methods
      def run_indexer
        indexer = SpecIndexing.get_indexer
        WrittenRepositories.scan(:staff) { indexer.run_index_round }
      end

      def run_indexers
        run_indexer
        indexer = SpecIndexing.get_pui_indexer
        WrittenRepositories.scan(:pui) { indexer.run_index_round }
      end
    end
  end

  module SpecBatchCreate
    BatchCreatedRecord = Struct.new(:id, :uri)

    # Creates `count` sibling tree records (archival objects, digital object
    # components or classification terms) in the current repository with a
    # single batch import request, instead of one request per record.  The
    # records are positioned in creation order under `parent` (or at the top
    # level of `root`), so `result[i]` is the (i + 1)th sibling.  `root_key` is
    # the record's link to its root (e.g. :resource).  An optional block
    # receives the index and returns extra values for that record.
    def batch_create_tree_children(factory, count, root_key:, root:, parent: nil, **values)
      repo_id = JSONModel.repository
      records = Array.new(count) do |i|
        record = build(factory, {
          root_key => {'ref' => root.uri},
          parent: parent && {'ref' => parent.uri},
          position: i
        }.compact.merge(values).merge(block_given? ? yield(i) : {}))

        record.to_hash(:raw).merge(
          'uri' => "/repositories/#{repo_id}/#{record.class.record_type}s/import_#{SecureRandom.hex(8)}"
        )
      end

      url = URI("#{JSONModel::HTTP.backend_url}/repositories/#{repo_id}/batch_imports")
      response = JSONModel::HTTP.post_json(url, records.to_json)
      results = ASUtils.json_parse(response.body).last
      if response.code != '200' || results['errors']
        raise "Batch import failed (#{response.code}): #{results['errors'] || response.body}"
      end

      records.map do |record|
        uri, id = results['saved'].fetch(record['uri'])
        BatchCreatedRecord.new(id, uri)
      end
    end
  end
end
