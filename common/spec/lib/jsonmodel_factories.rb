require 'jsonmodel'
require 'factory_bot'


module JSONModel

  def self.init_with_factories(opts)
    self.init(client_mode: true,
              url: opts[:url],
              priority: :high)

    Factories::init(opts)
  end

  module Factories

    def self.init(opts = {})
      @@inited ||= false

      if @@inited
        return true
      end

      @@backend_url = opts[:backend_url] || AppConfig[:backend_url]

      # legacy factory definitions. todo:
      # break out definitions to their own file
      require 'spec/lib/factory_bot_helpers'

      FactoryBot.define do

        to_create {|instance|
          try_again = true
          begin
            instance.save
          rescue Exception => e
            if e.class.name == "AccessDeniedException" && try_again
              try_again = false
              url = URI.parse(@@backend_url + "/users/admin/login")
              request = Net::HTTP::Post.new(url.request_uri)
              request.set_form_data("expiring" => "false",
                                    "password" => "admin")
              response = JSONModel::HTTP.do_http_request(url, request)

              if response.code == '200'
                auth = ASUtils.json_parse(response.body)

                JSONModel::HTTP.current_backend_session = auth['session']
                retry
              else
                raise "Authentication to backend failed: #{response.body}"
              end
            else
              raise e
            end
          end
        }
      end


      @@inited = true
    end
  end
end
