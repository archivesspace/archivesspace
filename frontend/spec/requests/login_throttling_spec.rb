# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'Staff login throttling', type: :request do
  let(:login_path) { "#{AppConfig[:frontend_proxy_prefix]}login" }
  let(:username_limit) { 2 }
  let(:ip_limit) { 3 }
  let(:backstop_limit) { 4 }
  let(:failed_response) do
    instance_double(Net::HTTPResponse, code: '403', body: '{"error": "Login failed"}')
  end
  let(:successful_response) do
    instance_double(Net::HTTPResponse, code: '200', body: '{"session": "abc"}')
  end
  let(:error_response) do
    instance_double(Net::HTTPResponse, code: '500', body: '{"error": "Server error"}')
  end

  before do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:frontend_login_throttle_limit).and_return(username_limit)
    allow(AppConfig).to receive(:[]).with(:frontend_login_ip_throttle_limit).and_return(ip_limit)
    allow(AppConfig).to receive(:[]).with(:frontend_login_username_backstop_limit).and_return(backstop_limit)
    fail_logins
    Rack::Attack.reset!
  end

  def fail_logins
    allow(User).to receive(:login_response).and_return(failed_response)
  end

  def succeed_logins
    allow(User).to receive(:login_response).and_return(successful_response)
    allow(User).to receive(:establish_session)
  end

  def attempt_login(username, ip)
    post login_path, params: { username: username, password: 'pw' }, env: { 'REMOTE_ADDR' => ip }
    response.status
  end

  def attempt_login_via_proxy(username, proxy_addr, client_ip)
    post login_path, params: { username: username, password: 'pw' },
                     env: { 'REMOTE_ADDR' => proxy_addr, 'HTTP_X_FORWARDED_FOR' => client_ip }
    response.status
  end

  describe 'per username and IP' do
    it 'blocks a username from one IP after the limit of failed logins' do
      expect(attempt_login('user1', '10.0.0.1')).to eq(200)
      expect(attempt_login('USER1', '10.0.0.1')).to eq(200)
      expect(attempt_login('user1', '10.0.0.1')).to eq(429)
      expect(JSON.parse(response.body)['session']).to be_nil
    end

    it 'does not block the username from other IPs' do
      2.times { attempt_login('user1', '10.0.0.1') }
      expect(attempt_login('user1', '10.0.0.2')).to eq(200)
    end

    it 'does not call the backend when the username is blocked' do
      3.times { attempt_login('user1', '10.0.0.1') }
      expect(User).to have_received(:login_response).twice
    end

    it 'does not block other usernames' do
      2.times { attempt_login('user1', '10.0.0.1') }
      expect(attempt_login('user2', '10.0.0.1')).to eq(200)
    end

    context 'with a higher IP limit' do
      let(:ip_limit) { 10 }

      it 'resets the count after a successful login' do
        attempt_login('user1', '10.0.0.1')
        succeed_logins
        attempt_login('user1', '10.0.0.1')
        fail_logins
        expect(attempt_login('user1', '10.0.0.1')).to eq(200)
        expect(attempt_login('user1', '10.0.0.1')).to eq(200)
        expect(attempt_login('user1', '10.0.0.1')).to eq(429)
      end
    end

    context 'when the username limit is 0' do
      let(:username_limit) { 0 }

      it 'does not block' do
        expect(Array.new(3) { attempt_login('user1', '10.0.0.1') }).to eq([200, 200, 200])
      end
    end
  end

  describe 'per username, from any IP' do
    it 'blocks a username from every IP after the backstop limit of failed logins' do
      expect(Array.new(4) { |i| attempt_login('user1', "10.0.0.#{i}") }).to eq([200] * 4)
      expect(attempt_login('USER1', '10.0.0.9')).to eq(429)
    end

    it 'does not block other usernames' do
      4.times { |i| attempt_login('user1', "10.0.0.#{i}") }
      expect(attempt_login('user2', '10.0.0.9')).to eq(200)
    end

    it 'resets the count after a successful login' do
      3.times { |i| attempt_login('user1', "10.0.0.#{i}") }
      succeed_logins
      attempt_login('user1', '10.0.0.8')
      fail_logins
      expect(Array.new(4) { |i| attempt_login('user1', "10.0.1.#{i}") }).to eq([200] * 4)
      expect(attempt_login('user1', '10.0.0.9')).to eq(429)
    end

    context 'when the backstop limit is 0' do
      let(:backstop_limit) { 0 }

      it 'does not block' do
        expect(Array.new(5) { |i| attempt_login('user1', "10.0.0.#{i}") }).to eq([200] * 5)
      end
    end
  end

  describe 'per IP' do
    it 'blocks an IP after the limit of failed logins, for any username' do
      expect(Array.new(3) { |i| attempt_login("user#{i}", '10.0.0.1') }).to eq([200, 200, 200])
      expect(attempt_login('user9', '10.0.0.1')).to eq(429)
    end

    it 'does not block other IPs' do
      3.times { |i| attempt_login("user#{i}", '10.0.0.1') }
      expect(attempt_login('user9', '10.0.0.2')).to eq(200)
    end

    it 'does not count successful logins' do
      succeed_logins
      expect(Array.new(5) { |i| attempt_login("user#{i}", '10.0.0.1') }).to eq([200] * 5)
    end

    it 'does not reset the IP count after a successful login' do
      2.times { |i| attempt_login("user#{i}", '10.0.0.1') }
      succeed_logins
      attempt_login('user3', '10.0.0.1')
      fail_logins
      expect(attempt_login('user4', '10.0.0.1')).to eq(200)
      expect(attempt_login('user5', '10.0.0.1')).to eq(429)
    end

    # Jetty reports IPv6 loopback in Java's format, for example 0:0:0:0:0:0:0:1.
    ['0:0:0:0:0:0:0:1', '[0:0:0:0:0:0:0:1]', '::1', '127.0.0.1'].each do |proxy_addr|
      it "counts failed logins per client IP behind a local proxy at #{proxy_addr}" do
        expect(Array.new(3) { |i| attempt_login_via_proxy("user#{i}", proxy_addr, '203.0.113.1') }).to eq([200] * 3)
        expect(attempt_login_via_proxy('user8', proxy_addr, '203.0.113.2')).to eq(200)
        expect(attempt_login_via_proxy('user9', proxy_addr, '203.0.113.1')).to eq(429)
      end
    end

    context 'when the IP limit is 0' do
      let(:ip_limit) { 0 }

      it 'does not block' do
        expect(Array.new(5) { |i| attempt_login("user#{i}", '10.0.0.1') }).to eq([200] * 5)
      end
    end
  end

  describe 'when the proxy does not send X-Forwarded-For' do
    ['0:0:0:0:0:0:0:1', '[0:0:0:0:0:0:0:1]', '::1', '127.0.0.1'].each do |proxy_addr|
      it "does not count failed logins per IP for clients of a local proxy at #{proxy_addr}" do
        expect(Array.new(5) { |i| attempt_login("user#{i}", proxy_addr) }).to eq([200] * 5)
      end

      it "still applies the username backstop for clients of a local proxy at #{proxy_addr}" do
        expect(Array.new(4) { attempt_login('user1', proxy_addr) }).to eq([200] * 4)
        expect(attempt_login('user1', proxy_addr)).to eq(429)
      end
    end

    context 'with trusted proxies configured' do
      before { allow(AppConfig).to receive(:[]).with(:trusted_proxies).and_return('10.0.0.5, 127.0.0.1') }

      it 'does not count failed logins per IP for clients of a trusted proxy' do
        expect(Array.new(5) { |i| attempt_login("user#{i}", '10.0.0.5') }).to eq([200] * 5)
      end

      it 'counts failed logins per IP for other clients' do
        expect(Array.new(3) { |i| attempt_login("user#{i}", '10.0.0.1') }).to eq([200] * 3)
        expect(attempt_login('user9', '10.0.0.1')).to eq(429)
      end
    end
  end

  describe 'backend errors' do
    it 'does not count a backend error as a failed login' do
      allow(User).to receive(:login_response).and_return(error_response)
      expect(Array.new(5) { attempt_login('user1', '10.0.0.1') }).to eq([200] * 5)
      fail_logins
      expect(attempt_login('user1', '10.0.0.1')).to eq(200)
    end
  end

  describe 'with settings that turn the limits off' do
    [nil, false, '0', 'off'].each do |value|
      context "when both limits are #{value.inspect}" do
        let(:username_limit) { value }
        let(:ip_limit) { value }
        let(:backstop_limit) { value }

        it 'does not raise or block' do
          expect(Array.new(5) { attempt_login('user1', '10.0.0.1') }).to eq([200] * 5)
        end
      end
    end

    [nil, 0].each do |value|
      context "when the periods are #{value.inspect}" do
        before do
          allow(AppConfig).to receive(:[]).with(:frontend_login_throttle_period).and_return(value)
          allow(AppConfig).to receive(:[]).with(:frontend_login_username_backstop_period).and_return(value)
        end

        it 'does not raise or block, and a successful login works' do
          expect(Array.new(5) { attempt_login('user1', '10.0.0.1') }).to eq([200] * 5)
          succeed_logins
          expect(attempt_login('user1', '10.0.0.1')).to eq(200)
        end
      end
    end
  end
end

describe LoginThrottle do
  describe '.trusted_proxies' do
    [nil, [], '', ' , '].each do |value|
      it "is nil for #{value.inspect}, to keep the Rails default" do
        allow(AppConfig).to receive(:[]).with(:trusted_proxies).and_return(value)
        expect(LoginThrottle.trusted_proxies).to be_nil
      end
    end

    it 'reads an array of IPs and ranges' do
      allow(AppConfig).to receive(:[]).with(:trusted_proxies).and_return(['127.0.0.1', '10.0.0.0/8'])
      expect(LoginThrottle.trusted_proxies).to eq([IPAddr.new('127.0.0.1'), IPAddr.new('10.0.0.0/8')])
    end

    it 'reads a comma separated string, as set from an environment variable' do
      allow(AppConfig).to receive(:[]).with(:trusted_proxies).and_return('127.0.0.1, ::1')
      expect(LoginThrottle.trusted_proxies).to eq([IPAddr.new('127.0.0.1'), IPAddr.new('::1')])
    end
  end
end
