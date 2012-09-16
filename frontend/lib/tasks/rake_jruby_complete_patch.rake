# Icky to have to do this, but had trouble with the recursive calls to Rake
# running under Windows with jruby-complete.jar.


if Config::CONFIG['host_os'] =~ /mswin/
  namespace :assets do
    def ruby_rake_task(task, fork = true)
      env    = ENV['RAILS_ENV'] || 'production'
      groups = ENV['RAILS_GROUPS'] || 'assets'
      args   = [task,"RAILS_ENV=#{env}","RAILS_GROUPS=#{groups}"]

      if fork
        ruby(*args)
      else
        Kernel.exec("java", "-cp", File.join(Rails.root, "..", "build", "jruby*.jar"),
                    "org.jruby.Main", "--1.9",  "-S", "rake", *args)
      end
    end
  end
end
