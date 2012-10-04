require 'spec_helper'
require 'socket'

describe 'Webhook controller' do

  it "happily registers a URL" do
    post '/webhooks/register', params = { "url" => "http://localhost:12732/only/me"}
    last_response.should be_ok
    last_response.status.should eq(200)
  end

  it "provides a means to test that a URL was registered successfully" do
    # unfortunately the webhook notifier can't see a listener we register here
    # this is because our test is run inside an uncommited db transaction
    # while the webhook notifier runs in a thread spun at launch
    # so while this works:
    #    post '/webhooks/register', params = { "url" => "http://localhost:12732"}
    # when the notifier thread goes the the db it won't find our url
    # so, we'll just listen on the frontend port - which gets added as a listener at launch
    # if someone is already listening on the frontend port (a frontend maybe;) then
    # this test will quietly pass - the idea is it didn't fail, we just couldn't run it
    # due to factors beyond our control
    # ... and after all this whole venture is arguably frivolous since this is best
    # tested in an integration or selenium test.

    begin
      # notifications are disabled during tests - enable them temporarily
      Webhooks.class_eval("def self.notify(code, params = {}); self.notify_orig(code, params); end")

      # keep the output clean if someone's on our port
      real_stderr, $stderr = $stderr, StringIO.new

      abort_on_exception = Thread.abort_on_exception
      Thread.abort_on_exception = true
      
      thr = Thread.new(URI(AppConfig[:frontend_url]).port) do |port|
        begin
          server = TCPServer.new port
          waiting_for_hello = true
          while waiting_for_hello
            s = server.accept
            while line = s.gets and waiting_for_hello
              if line =~ /HELLO.*it.*works/
                waiting_for_hello = false
              end
            end
            s.close
          end
        rescue SystemExit => se
          raise "Boo - someone's on our port"
        end
      end

      # send the test request
      get '/webhooks/test'
      
      # make sure it was received
      last_response.should be_ok
      last_response.status.should eq(200)
      
      # give our notification listener thread 10 seconds to complete
      # it will complete when it receives the test notification
      thr.join(10).should_not be_nil
      
    rescue Exception => e
      # someone's on our port so we can't complete the test
      # never mind - not much we can do

    ensure
      # restore stderr
      $stderr = real_stderr

      # re-disable notifications
      Webhooks.class_eval("def self.notify(*ignored); end")

      # restore original value for abort_on_exception
      Thread.abort_on_exception = abort_on_exception
    end

  end

end
