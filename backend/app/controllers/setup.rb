class ArchivesSpaceService < Sinatra::Base

  URL_FORMATS = {
    'mysql' => "jdbc:mysql://{:hostname}:{:port}/{:database}?user={:username}&password={:password}"
  }


  def load_state
    AppConfig.reload

    @state = {:errors => {}}
    @state[:using_demo_db] = (AppConfig[:db_url] == AppConfig.demo_db_url)
    @state[:config_path] = AppConfig.get_preferred_config_path

    if not @state[:using_demo_db]
      @state = @state.merge(parse_jdbc_url(AppConfig[:db_url]))
    end

    if test_database(AppConfig[:db_url])[:ok]
      db = Sequel.connect(AppConfig[:db_url])
      @state[:needs_migration] = DBMigrator.needs_updating?(db)
    else
      @state[:connection_failed] = true
    end
  end


  def build_jdbc_url(settings)
    url = URL_FORMATS[params[:db_type]]

    settings.each do |p, v|
      url = url.gsub(/{:#{p}}/, v)
    end

    url
  end


  def parse_jdbc_url(url)
    URL_FORMATS.each do |type, template|
      keys = template.scan(/{:(\w+?)}/).flatten

      pattern = Regexp.quote(template)
      keys.each do |p|
        pattern = pattern.gsub(/\\{:#{p}\\}/, '(.+)')
      end

      vals = url.scan(Regexp.compile(pattern)).flatten.reject {|v| not v or v.empty?}

      if keys.length == vals.length
        return Hash[keys.zip(vals)]
      end
    end

    {}
  end


  def test_database(url)
    begin
      Sequel.connect(url, :test => true)
      return {:ok => true}
    rescue
      return {:ok => false, :msg => "#{$!}"}
    end
  end


  def extract_settings(params)
    settings = {}

    [:db_type, :hostname, :port, :database, :username, :password].each do |p|
      settings[p] = params[p]
    end

    settings
  end


  def save_settings(settings, path)
    if File.exists?(path)
      FileUtils.copy(path, "#{path}.tmp")
    end

    File.open(path + ".tmp", 'a') do |f|
      f.puts "\n# These lines automatically added by the setup program"
      settings.each do |config, val|
        f.puts "AppConfig[:#{config}] = \"#{val}\""
      end
    end

    FileUtils.mv("#{path}.tmp", path)
  end


  get '/setup' do
    redirect to('setup/')
  end


  get '/setup/' do
    load_state
    erb :setup
  end


  post '/setup/set_database' do
    load_state

    settings = extract_settings(params)
    @state = @state.merge(settings)

    @state[:errors] = {}

    settings.each do |p, value|
      if not value or value.empty?
        @state[:errors][p] = "Required field"
      end
    end

    if @state[:errors].empty?

      url = build_jdbc_url(settings)

      @state[:url] = url

      db = test_database(url)
      if db[:ok]
        save_settings({:db_url => url}, @state[:config_path])

        # Reload
        load_state

        @state[:message] = {:class => "ok", :text => "Settings saved"}
      else
        @state[:message] = {:class => "error", :text => "Database connection failed: #{db[:msg]}"}
      end
    else
      @state[:message] = {:class => "error", :text => "Some fields weren't quite right"}
    end

    erb :setup

  end


  post '/setup/update_schema' do
    load_state

    if test_database(AppConfig[:db_url])
      db = Sequel.connect(AppConfig[:db_url], :test => true)

      puts "Setting up database..."

      begin
        DBMigrator.setup_database(db)
      rescue
        puts "FAILED: #{$!}"
        puts $@.join("\n")
      end
    end

    redirect to('setup/')
  end

end
