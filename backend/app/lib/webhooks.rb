require 'thread'
require 'json'
require 'java'
require 'net/http'
require 'set'
require_relative '../../../common/jsonmodel'

class Webhooks

  extend JSONModel

  @@queue = Queue.new

  def self.add_listener(url)
    DB.open do |db|
      begin
        db[:webhook_endpoint].insert(:url => url)
      rescue
        # Ignore dupes
      end
    end
  end


  def self.notify(code, params = {})
    @@queue << [code, params]
  end


  def self.start
    Thread.new do

      while true
        begin
          # A short delay to give duplicate events the change to batch together
          sleep 0.5

          messages = []

          # Wait for at least one element to show up
          messages << @@queue.pop

          until @@queue.empty?
            messages << @@queue.pop
          end

          events = {}
          messages.each do |code, params|
            events[code] = {"code" => code, "params" => params}
          end

          notification = JSONModel(:webhook_notification).from_hash(:events => events.values)

          listeners = DB.open do |db|
            db[:webhook_endpoint].select(:url).map {|row| row[:url]}
          end

          listeners.each do |url|
            Thread.new do
              begin
                uri = URI(url)
                http = Net::HTTP.new(uri.host, uri.port)

                http.open_timeout = 2
                http.read_timeout = 2

                req = Net::HTTP::Post.new(uri.request_uri)
                req.form_data = {"notification" => notification.to_json(:mode => :trusted)}

                http.start do |http|
                  http.request(req) do |response|
                  end
                end
              rescue
                # Oh well!
              end
            end
          end
        rescue
          puts "Webhook delivery failure: #{$!}"
          sleep 30
        end
      end
    end
  end
end
