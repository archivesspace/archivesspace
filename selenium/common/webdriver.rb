require 'selenium-webdriver'

require 'pry'


module DriverMixin
  def click_and_wait_until_gone(*selector)
    element = self.find_element(*selector)
    element.click

    begin
      try = 0
      while element.displayed?
        if try < Selenium::Config.retries
          try += 1
          sleep_time = (0.1 * try) + 0.1 
          $sleep_time += sleep_time
          sleep sleep_time
          puts "click_and_wait_until_gone: #{try} hits selector '#{selector}'.  Retrying..." if (try % 20) == 0
        else
          raise "Failed to remove: #{selector.inspect}"
        end
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError
      # Great!  It's gone.
    end

    wait_for_page_ready
  end


  def click_and_wait_until_element_gone(element)
    element.click

    begin
      Selenium::Config.retries.times do |try|
        break unless element.displayed? || self.find_element_orig(*selector)
        sleep 0.1

        if try == Selenium::Config.retries - 1
          puts "wait_until_element_gone never saw element go: #{element.inspect}"
        end
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError
    end

    wait_for_page_ready
  end


  def wait_for_page_ready
    loop do
      ready_state = execute_script("return document.readyState")
      jquery_state = execute_script("return typeof jQuery != 'undefined' && !jQuery.active")
      break if ready_state == 'complete' && jquery_state
      sleep 0.1
    end
  end


  def wait_until_gone(*selector)
      timeout = 10
      wait = Selenium::WebDriver::Wait.new(timeout: timeout)
      wait.until { !self.find_element_orig(*selector).displayed? }
      sleep 0.5 
  end


  def test_group_prefix
    if ENV['TEST_ENV_NUMBER']
      number = ENV['TEST_ENV_NUMBER'].empty? ? 1 : ENV['TEST_ENV_NUMBER']
      "[#{number}] "
    else
      ""
    end
  end


  def clear_and_send_keys(selector, keys)
    elt = self.find_element(*selector)
    elt.clear
    elt.send_keys(keys)
  end
end



module Selenium
  module WebDriver
    module Firefox
      class Binary

        # Searching the registry causes a EXCEPTION_ACCESS_VIOLATION under
        # Windows 7.  Skip this step and just look for Firefox in the usual
        # places.
        def self.windows_registry_path
          nil
        end
      end
    end

# hack to allow Selenium to run offline
    module Platform
      class << self
        alias :ip_orig :ip

        def ip
          begin
            self.ip_orig
          rescue SocketError #JRuby raises this instead of Errno::ENETUNREACH
          end
        end
      end
    end


    class Driver
      include DriverMixin

      def wait_for_dropdown
        # Tried EVERYTHING to avoid needing this sleep.  Buest guess at the moment:
        # JS hasn't been wired up to the click event and we get in too quickly.
        sleep 1
      end

      def wait_for_ajax
        max_ajax_sleep_seconds = 20
        ajax_sleep_duration = 0.05

        max_tries = max_ajax_sleep_seconds / ajax_sleep_duration

        try = 0
        while (self.execute_script("return document.readyState") != "complete" or
               not self.execute_script("return window.$ == undefined || $.active == 0"))
          if (try > max_tries)
            puts "Retry limit hit on wait_for_ajax.  Going ahead anyway."
            break
          end

          $sleep_time += ajax_sleep_duration
          sleep(ajax_sleep_duration)
          try += 1
        end

        raise_javascript_errors
      end

      def find_paginated_element(*selectors)
        try = 0
        while true
          begin
            elt = self.find_element_orig(*selectors)
            return elt
          rescue Selenium::WebDriver::Error::NoSuchElementError
            puts "#{test_group_prefix}find_element failed: trying to turn the page"

            begin
              click_and_wait_until_element_gone(self.find_element_orig(:css => "a[title='Next']"))
            rescue Selenium::WebDriver::Error::NoSuchElementError
              puts "Failed to turn the page!"
              raise Selenium::WebDriver::Error::NoSuchElementError.new(selectors.inspect)
            end
          end
        end
      end


      def element_finder(*selectors)
        lambda {
          self.find_element(*selectors)
        }
      end


      def scroll_into_view(elt)
        self.execute_script("arguments[0].scrollIntoView(true);", elt)

        # Wait for the element to appear in our viewport
        Selenium::Config.retries.times do |try|
          in_viewport = self.execute_script("
            var rect = arguments[0].getBoundingClientRect();
            return (
              rect.top >= 0 &&
              rect.left >= 0 &&
              rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
              rect.right <= (window.innerWidth || document.documentElement.clientWidth)
            );
          ", elt)
          break if in_viewport
          sleep 0.1
        end

        # If it's still not in the viewport we're optimistically charging ahead
        # here and assuming that the calling test will fail if it really
        # matters...
        elt
      end


      alias :find_element_orig :find_element

      def find_element(*selectors)
        wait_for_ajax

        try = 0
        while true
          begin
            matched = find_elements(*selectors)
            elt = matched.find {|elt| elt.displayed?}

            if elt.nil?
              raise Selenium::WebDriver::Error::NoSuchElementError.new("Not visible (yet?)")
            end

            return elt
          rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError => e
            if try < Selenium::Config.retries
              try += 1
              $sleep_time += 0.1
              sleep 0.1
              if (try > 0) && (try % 20) == 0
                puts "#{test_group_prefix}find_element: #{try} misses on selector '#{selectors}'.  Retrying..."
                puts caller.take(10).join("\n")
              end
            else
              puts "Failed to find #{selectors}"

              if ENV['ASPACE_TEST_WITH_PRY']
                puts "Starting pry"
                binding.pry
              else
                raise e
              end
            end
          end
        end
      end

      def find_hidden_element(*selectors)
        wait_for_ajax

        try = 0
        while true
          begin
            elt = find_element_orig(*selectors)

            if elt.nil?
              raise Selenium::WebDriver::Error::NoSuchElementError.new("Element not found")
            end

            return elt
          rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError => e
            if try < Selenium::Config.retries
              try += 1
              $sleep_time += 0.1
              sleep 0.1
              if (try > 0) && (try % 20) == 0
                puts "#{test_group_prefix}find_element: #{try} misses on selector '#{selectors}'.  Retrying..."
                puts caller.take(10).join("\n")
              end
            else
              puts "Failed to find #{selectors}"

              if ENV['ASPACE_TEST_WITH_PRY']
                puts "Starting pry"
                binding.pry
              else
                raise e
              end
            end
          end
        end
      end



      def find_last_element(*selectors)
        result = blocking_find_elements(*selectors)

        result[result.length - 1]
      end


      def blocking_find_elements(*selectors)
        # Hit with find_element first to invoke our usual retry logic
        find_element(*selectors)

        find_elements(*selectors).select {|elt| elt.displayed?}
      end


      def ensure_no_such_text(xpath, pattern, noError = false, noRetry = true )
        wait_for_ajax
        begin
          element = self.find_element(:tag_name => "body").find_element_with_text(xpath, pattern, noError, noRetry)

          if element.nil? or !element.displayed?
            true
          else
            raise "Element was supposed to be absent: #{xpath} #{pattern}"
          end
        rescue Selenium::WebDriver::Error::NoSuchElementError => e
          return true
        end
      end


      def ensure_no_such_element(*selectors)
        wait_for_ajax

        begin
          element = find_element_orig(*selectors)

          if element.displayed?
            raise "Element was supposed to be absent: #{selectors}"
          else
            true
          end
        rescue Selenium::WebDriver::Error::NoSuchElementError => e
          return true
        end
      end


      def generate_4part_id
        Digest::MD5.hexdigest("#{Time.now}#{SecureRandom.uuid}#{$$}").scan(/.{6}/)[0...1]
      end

      def complete_4part_id(pattern, accession_id = nil)
        # Was 4, but now that the input boxes are disabled this wasn't filling out the last 3.
        accession_id ||= generate_4part_id
        accession_id.each_with_index do |elt, i|
          self.clear_and_send_keys([:id, sprintf(pattern, i)], elt)
        end

        accession_id
      end


      def find_element_with_text(xpath, pattern, noError = false, noRetry = false)
        tries = 0

        begin
          self.find_element(:tag_name => "body").find_element_with_text(xpath, pattern, noError, noRetry)
        rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
          if tries < Selenium::Config.retries && !noRetry
            tries += 1
            $sleep_time += 0.1
            sleep 0.1
            retry
          elsif noError
            return nil
          else
            raise e
          end
        end
      end


      def raise_javascript_errors
        errors = self.execute_script("return window.hasOwnProperty('TEST_ERRORS') ? TEST_ERRORS : []")
        raise "Javascript errors present: #{errors.inspect}" if errors.length > 0
      end


      # Convenient when using the console to update tests
      def test_find_element(*selectors)
        begin
          elt = find_element_orig(*selectors)

          if elt.displayed?
            return elt
          else
            raise "Can't find #{selectors}"
          end
        rescue Exception => e
          puts e
        end
      end

      # for some reason, find :css sometimes doesn't like names with [ ] 
      def find_input_by_name( name )
        find_elements(:css, "input" ).each do |input|
          return input if ( input.attribute("name") == name )
        end
        raise Selenium::WebDriver::Error::NoSuchElementError 
      end

      # adds to an input and selects a the first value provided by a typeahead 
      def typeahead_and_select(token_input, value, try = 0 )
        raise Selenium::WebDriver::Error::NoSuchElementError if try == 10
        token_input.clear
        # token_input.click
        token_input.send_keys(value)
        if token_input["value"] == value
          begin
            wait_for_dropdown 
            find_element_orig(:css, "li.token-input-dropdown-item2").click
          rescue Selenium::WebDriver::Error::NoSuchElementError => e
            sleep try
            case try += 1
            when 5 #corny but sometimes the ajax hangs. let re-enter and see if retrigger helps
              typeahead_and_select(token_input, value, try )
            when 0..10
              retry
            else
              raise e
            end
          end
        else # for whatever reason, the input didn't get put in correctly. so let's try again
          $stderr.puts "Input did not have value #{value}, found value #{token_input['value']}. trying to enter input again.." 
          typeahead_and_select(token_input, value, retries - 1 )        
        end 
      end

      def open_rde_add_row_dropdown
        modal = self.find_element(:id => "rapidDataEntryModal")
        3.times do |try|
          begin 
            modal.find_element(:css, ".btn.add-rows-dropdown").click
            modal.find_element_orig(:css => '.add-rows-form input').click
            break 
          rescue
            # $stderr.puts "hmmm...can't find the input..lets try and reopen the dropdown.. " 
            next 
          end 
        end
      end

    end


    class Element
      include DriverMixin

      def wait_for_class(className)
        try = 0
        while !self.attribute('class').split(" ").include? className
          if (try > Selenium::Config.retries)
            puts "Retry limit hit on wait_for_class.  Going ahead anyway."
            break
          end
        end
        sleep(0.5)
        try += 1
      end


      def select_option(value)
        self.click

        self.find_elements(:tag_name => "option").each do |option|
          begin
            if option.attribute("value") === value
              Selenium::Config.retries.times do |try|
                return if option.attribute('selected')

                option.click
                sleep 0.1
              end
            end
          rescue Selenium::WebDriver::Error::StaleElementReferenceError
            # Assume that the click triggered a reload!
            return
          end
        end

        raise "Couldn't select value: #{value}"
      end


      def select_option_with_text(value)
        self.find_element( :xpath,  "./*[contains( text(), '#{value.strip}' )]").click
      end

      def get_select_value
        self.find_elements(:tag_name => "option").each do |option|
          return option.attribute("value") if option.attribute("checked")
        end

        return ""
      end

      def nearest_ancestor(xpath)
        self.find_element(:xpath => './ancestor-or-self::' + xpath + '[1]')
      end


      def containing_subform
        nearest_ancestor('div[contains(@class, "subrecord-form-fields")]')
      end


      def find_last_element(*selectors)
        result = blocking_find_elements(*selectors)

        result[result.length - 1]
      end


      def blocking_find_elements(*selectors)
        # Hit with find_element first to invoke our usual retry logic
        find_element(*selectors)

        find_elements(*selectors).select {|elt| elt.displayed?}
      end


      def find_element_with_text(xpath, pattern, noError = false, noRetry = false)
        Selenium::Config.retries.times do |try|
          begin
            matches = self.find_elements(:xpath => xpath)
            matches.each do | match |
              return match if match.text.chomp.strip =~ pattern
            end
          rescue => e
            return nil if noError && noRetry
            raise e if noRetry
            # Ignore exceptions and retry
          end

          # we got here and there's nothing..
          # raise an error unless we're told not to
          if noRetry
            return nil if noError
            raise Selenium::WebDriver::Error::NoSuchElementError
          end

          $sleep_time += 0.1
          sleep 0.1
          if (try > 0) && (try % 20) == 0
            puts "find_element_with_text: #{try} misses on selector ':xpath => #{xpath}'.  Retrying..."
            puts caller.take(10).join("\n")
          end
        end

        return nil if noError

        raise Selenium::WebDriver::Error::NoSuchElementError.new("Could not find element for xpath: #{xpath} pattern: #{pattern}")
      end

      alias :find_element_orig :find_element
      def find_element(*selectors)

        try = 0
        while true
          begin
            elt = find_elements(*selectors).find {|elt| elt.displayed?}

            if elt.nil?
              raise Selenium::WebDriver::Error::NoSuchElementError.new("Not visible (yet?)")
            end

            return elt
          rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError => e
            if try < Selenium::Config.retries
              try += 1
              $sleep_time += 0.1
              sleep 0.1
              if (try > 0) && (try % 20) == 0
                puts "#{test_group_prefix}find_element: #{try} misses on selector '#{selectors}'.  Retrying..."
                puts caller.take(10).join("\n")
              end
            else
              puts "Failed to find #{selectors}"

              raise e
            end
          end
        end
      end

      # Convenient when using the console to update tests
      def test_find_element(*selectors)
        begin
          elt = find_element_orig(*selectors)

          if elt.displayed?
            return elt
          else
            raise "Can't find #{selectors}"
          end
        rescue Exception => e
          puts e
        end
      end


      def execute_script(script, *args)
        bridge.execute_script(script, *args)
      end
    end
  end
end
