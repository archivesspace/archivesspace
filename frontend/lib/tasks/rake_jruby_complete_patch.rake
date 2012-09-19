# Icky to have to do this, but had trouble with the recursive calls to Rake
# running under Windows with jruby-complete.jar.


if Config::CONFIG['host_os'] =~ /mswin/

  $rake_cmd = ["java",
                   "-cp", File.join(Rails.root, "..", "build", "jruby*.jar"),
                   "org.jruby.Main", "--1.9", "-S", "rake"]


  namespace :assets do
    def ruby_rake_task(task, fork = true)
      env    = ENV['RAILS_ENV'] || 'production'
      groups = ENV['RAILS_GROUPS'] || 'assets'
      args   = [task,"RAILS_ENV=#{env}","RAILS_GROUPS=#{groups}"]

      if fork
        sh(($rake_cmd + args).join(" "))
      else
        Kernel.exec(*$rake_cmd, *args)
      end
    end
  end
end
