require 'selenium-webdriver'

module DriverMixin
  def click_and_wait_until_gone(*selector)
    element = self.find_element(*selector)
    element.click

    begin
      try = 0
      while self.find_element_orig(*selector).equal? element
        if try < Selenium::Config.retries
          try += 1
          $sleep_time += 0.1
          sleep 0.5
          puts "click_and_wait_until_gone: #{try} hits selector '#{selector}'.  Retrying..." if (try % 5) == 0
        else
          raise "Failed to remove: #{selector.inspect}"
        end
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError
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
    Selenium::Config.retries.times do
      begin
        elt = self.find_element_orig(*selector)
        elt.clear
        elt.send_keys(keys)
        break
      rescue
        $sleep_time += 0.1
        sleep 0.3
      end
    end
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

        start_page = self.current_url

        try = 0
        while true

          begin
            elt = self.find_element_orig(*selectors)

            if not elt.displayed?
              raise Selenium::WebDriver::Error::NoSuchElementError.new("Not visible (yet?)")
            end

            return elt

          rescue Selenium::WebDriver::Error::NoSuchElementError
            puts "#{test_group_prefix}find_element failed: trying to turn the page"
            self.find_element_orig(:css => "a[title='Next']").click
            retry
          rescue Selenium::WebDriver::Error::NoSuchElementError
            if try < Selenium::Config.retries
              try += 1
              sleep 0.5
              self.navigate.to(start_page)
              puts "#{test_group_prefix}find_paginated_element: #{try} misses on selector '#{selectors}'.  Retrying..." if (try > 0) && (try % 5) == 0
            else
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
            elt = find_element_orig(*selectors)

            if not elt.displayed?
              raise Selenium::WebDriver::Error::NoSuchElementError.new("Not visible (yet?)")
            end

            return elt
          rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError => e
            if try < Selenium::Config.retries
              try += 1
              $sleep_time += 0.5
              sleep 0.5
              puts "#{test_group_prefix}find_element: #{try} misses on selector '#{selectors}'.  Retrying..." if (try > 0) && (try % 5) == 0

            else
              puts "Failed to find #{selectors}"
              raise e
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

        find_elements(*selectors)
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
        rescue Selenium::WebDriver::Error::StaleElementReferenceError
          if tries < Selenium::Config.retries
            tries += 1
            $sleep_time += 0.5
            sleep 0.5

            retry
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


      def open_rde_add_row_dropdown
        modal = self.find_element(:id => "rapidDataEntryModal")
        3.times do
          begin 
            modal.find_element(:css, ".btn.add-rows-dropdown").click
            modal.find_element_orig(:css => '.add-rows-form input').click
            break 
          rescue
            $stderr.puts "hmmm...can't find the input..lets try and reopen the dropdown.. " 
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
        self.find_elements(:tag_name => "option").each do |option|
          if option.attribute("value") === value
            option.click
            return
          end
        end

        raise "Couldn't select value: #{value}"
      end


      def select_option_with_text(value)
        self.find_elements(:tag_name => "option").each do |option|
          if option.text === value
            option.click
            return
          end
        end

        raise "Couldn't select value: #{value}"
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
        result = find_elements(*selectors)

        result[result.length - 1]
      end


      def find_element_with_text(xpath, pattern, noError = false, noRetry = false)
        Selenium::Config.retries.times do |try|
          matches = self.find_elements(:xpath => xpath)

          begin
            matches.each do | match |
              return match if match.text =~ pattern
            end
          rescue
            # Ignore exceptions and retry
          end

          if noRetry
            return nil
          end

          $sleep_time += 0.5
          sleep 0.5
          puts "find_element_with_text: #{try} misses on selector ':xpath => #{xpath}'.  Retrying..." if (try > 0) && (try % 10) == 0
        end

        return nil if noError

        raise Selenium::WebDriver::Error::NoSuchElementError.new("Could not find element for xpath: #{xpath} pattern: #{pattern}")
      end

      alias :find_element_orig :find_element
      def find_element(*selectors)

        try = 0
        while true
          begin
            elt = find_element_orig(*selectors)

            if not elt.displayed?
              raise Selenium::WebDriver::Error::NoSuchElementError.new("Not visible (yet?)")
            end

            return elt
          rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError => e
            if try < Selenium::Config.retries
              try += 1
              $sleep_time += 0.1
              sleep 0.5
              puts "#{test_group_prefix}find_element: #{try} misses on selector '#{selectors}'.  Retrying..." if (try > 0) && (try % 5) == 0

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

    end
  end
end
