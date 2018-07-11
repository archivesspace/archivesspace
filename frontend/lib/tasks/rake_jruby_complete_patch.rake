# Icky to have to do this, but had trouble with the recursive calls to Rake
# running with jruby-complete.jar.

classpath = [File.join(Rails.root, "..", "common")]
classpath << Dir.glob(File.join(Rails.root, "..", "build", "jruby*complete*.jar")).first


$rake_cmd = ["java",
             "-XX:MaxPermSize=128m", "-Xmx256m",
             "-cp", classpath.join(java.io.File.pathSeparator),
             "org.jruby.Main", "-X-C", "-S", "rake"]


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
