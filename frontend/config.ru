# This file is used by Rack-based servers to start the application.

require "aspace_gems"
ASpaceGems.setup

require ::File.expand_path('../config/environment',  __FILE__)
require 'multipart_buffer_setter'

module Rack
  class Server
    alias :options_pre_mizuno :options

    # It seems like there should be an easier way to pass options to the
    # underlying server, but I'm yet to find it.  So here's this.
    def options
      result = options_pre_mizuno
      result[:reuse_address] = true
      result
    end
  end
end

use MultipartBufferSetter
run ArchivesSpace::Application
