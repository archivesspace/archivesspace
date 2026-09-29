# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe 'PUI login throttling', type: :request do
  let(:login_path) { "#{AppConfig[:public_proxy_prefix]}login" }
  let(:username_limit) { 2 }
  let(:ip_limit) { 3 }
  let(:failed_response) do
    instance_double(Net::HTTPResponse, code: '403', body: '{"error": "Login failed"}')
  end
  let(:successful_response) do
    instance_double(Net::HTTPResponse, code: '200',
                    body: { 'session' => 'abc', 'user' => { 'username' => 'user1' } }.to_json)
  end

  before do
    allow(AppConfig).to receive(:[]).and_call_original
    allow(AppConfig).to receive(:[]).with(:pui_require_authentication).and_return(true)
    allow(AppConfig).to receive(:[]).with(:pui_login_throttle_limit).and_return(username_limit)
    allow(AppConfig).to receive(:[]).with(:pui_login_ip_throttle_limit).and_return(ip_limit)
    fail_logins
    Rack::Attack.reset!
  end

  def fail_logins
    allow(JSONModel::HTTP).to receive(:post_form).and_return(failed_response)
  end

  def succeed_logins
    allow(JSONModel::HTTP).to receive(:post_form).and_return(successful_response)
  end

  def attempt_login(username, ip)
    post login_path, params: { user_name: username, password: 'pw' }, env: { 'REMOTE_ADDR' => ip }
    response.status
  end

  def attempt_login_via_proxy(username, proxy_addr, client_ip)
    post login_path, params: { user_name: username, password: 'pw' },
                     env: { 'REMOTE_ADDR' => proxy_addr, 'HTTP_X_FORWARDED_FOR' => client_ip }
    response.status
  end

  describe 'per username' do
    it 'blocks a username after the limit of failed logins, from any IP' do
      expect(attempt_login('user1', '10.0.0.1')).to eq(200)
      expect(attempt_login('USER1', '10.0.0.2')).to eq(200)
      expect(attempt_login('user1', '10.0.0.3')).to eq(429)
      expect(response.body).to include('Too many failed login attempts')
    end

    it 'does not call the backend when the username is blocked' do
      3.times { |i| attempt_login('user1', "10.0.0.#{i}") }
      expect(JSONModel::HTTP).to have_received(:post_form).twice
    end

    it 'does not block other usernames' do
      2.times { |i| attempt_login('user1', "10.0.0.#{i}") }
      expect(attempt_login('user2', '10.0.0.9')).to eq(200)
    end

    it 'resets the username count after a successful login' do
      attempt_login('user1', '10.0.0.1')
      succeed_logins
      attempt_login('user1', '10.0.0.2')
      fail_logins
      expect(attempt_login('user1', '10.0.0.3')).to eq(200)
      expect(attempt_login('user1', '10.0.0.4')).to eq(200)
      expect(attempt_login('user1', '10.0.0.5')).to eq(429)
    end

    context 'when the username limit is 0' do
      let(:username_limit) { 0 }

      it 'does not block' do
        expect(Array.new(3) { |i| attempt_login('user1', "10.0.0.#{i}") }).to eq([200, 200, 200])
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
      expect(Array.new(5) { |i| attempt_login("user#{i}", '10.0.0.1') }).to eq([302] * 5)
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

  describe 'with settings that turn the limits off' do
    [nil, false, '0', 'off'].each do |value|
      context "when both limits are #{value.inspect}" do
        let(:username_limit) { value }
        let(:ip_limit) { value }

        it 'does not raise or block' do
          expect(Array.new(5) { attempt_login('user1', '10.0.0.1') }).to eq([200] * 5)
        end
      end
    end

    [nil, 0].each do |value|
      context "when the period is #{value.inspect}" do
        before { allow(AppConfig).to receive(:[]).with(:pui_login_throttle_period).and_return(value) }

        it 'does not raise or block, and a successful login works' do
          expect(Array.new(5) { attempt_login('user1', '10.0.0.1') }).to eq([200] * 5)
          succeed_logins
          expect(attempt_login('user1', '10.0.0.1')).to eq(302)
        end
      end
    end
  end
end
