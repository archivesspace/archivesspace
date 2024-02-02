require 'thor'

class Misc < Thor

  desc "print_env", "print env vars"
  option :out, :required => false
  def print_env
    out = if options[:out]
            File.open(File.join(Dir.pwd, '/', options[:out]), 'w')
          else
            $stderr
          end

    ENV.each do |k, v|
      out << "#{k.ljust(30)} #{v}\n"
    end
    out.close
  end
end
