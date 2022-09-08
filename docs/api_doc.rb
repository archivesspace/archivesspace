## ApiDoc
##
# This is a utility for generating a markdown document that can be consumed by the
# Slate api publishing tool. ApiDoc.generate_markdown_for_slate will output a
# slate-ready markdown file to docs/slate/source/index.html.md. It works by building
# a collection of ApiDoc::Example objects for each endpoint in the ArchivesSpace
# backend, and then emitting them into the markdown document. There are three ways to
# create an example:
# 1) by editing files in `backend/controllers` and supplying handwritten examples.
#
# 2) by registering examples using this class. Example:
#    ApiDoc.register_example "/search", :get, {
#                             q: "important papers",
#                             aq: build(:json_advanced_query),
#                             page: 1,
#                             page_size: 10
#                           }, "basic search with 10 results per page"
#
# 3) by doing nothing and allowing ApiDoc to build examples using FactoryBot
#    factories defined in `backend/spec/factories.rb`

require 'factory_bot'
require 'uri'
require 'rack/test'
require 'jsonmodel'
require 'erb'
require_relative "../common/jsonmodel_translatable.rb"
require_relative '../backend/spec/spec_helper.rb'

class ArchivesSpaceService
  def current_user
    User.first
  end

  def high_priority_request?
    false
  end
end

BACKEND_URL = ENV['ASPACE_BACKEND_URL'] || "http://localhost:8089"

FactoryBot.define do
  to_create { |instance|
    instance.uri = instance.class.uri_for(99, repo_id: 99)
  }
end

require_relative '../backend/spec/factories.rb'

class ApiDoc
  include FactoryBot::Syntax::Methods

  @@shell_example_erb = ERB.new(File.read(File.join(File.dirname(__FILE__), 'shell_example.erb')), nil, '-')
  @@examples= {}

  def self.generate_markdown_for_slate
    slate_erb = ERB.new(File.read(File.join(File.dirname(__FILE__), 'API.erb')), nil, '<>')
    slate_md = File.join(File.dirname(__FILE__), 'slate', 'source', 'index.html.md')
    endpoints = ArchivesSpaceService::Endpoint.all.sort{|a,b| a[:uri] <=> b[:uri]}.reject { |ep| ep[:uri] == '/slug' }

    endpoints.each do |endpoint|
      next if endpoint[:examples]['shell']
      endpoint[:examples]['shell'] = ApiDoc.shell_examples_for endpoint
    end

    admin_auth_response_body = JSON.pretty_generate({ session: "9528190655b979f00817a5d38f9daf07d1686fed99a1d53dd2c9ff2d852a0c6e",
                                                      user: JSON.parse(
                                                        ( JSONModel::HTTP.get_response JSONModel::JSONModel(:user).my_url(1) ).body ) })

    File.open(slate_md, 'w') do |f|
      f.write slate_erb.result(binding)
    end
  end

  # alternative to letting examples auto-generate is to register see scripts/tasks/docs.thor
  def self.register_example(uri, method, params, comment)
    @@examples[uri] ||= {}
    @@examples[uri][method] ||= []
    @@examples[uri][method] << Example.new(uri, method, params, comment)
  end

  def self.collect_examples(endpoint, method)
    if @@examples[endpoint[:uri]] && @@examples[endpoint[:uri]][method]
      @@examples[endpoint[:uri]][method] unless @@examples[endpoint[:uri]][method].empty?
    elsif endpoint[:paginated]
      variations = [
        [:page, 1, "return first 10 records"],
        [:all_ids, true, "return an array of all the ids"],
        [:id_set, '1,2,3,5,8', "return first 5 records in the Fibonacci sequence"]
      ].map do |pagination_option|
          (key, value, comment) = pagination_option
          example = Example.from_endpoint_defn(endpoint, method)
          example.add_param(key, value)
          example.comment = comment
          example
      end
    else
      [Example.from_endpoint_defn(endpoint, method)]
    end
  end

  def self.shell_examples_for(endpoint)
    # look up if already registered; otherwise generate from endpoint
    examples = endpoint[:method].map { |method| collect_examples(endpoint, method) }.flatten.compact
    @@shell_example_erb.result(binding)
  end

  class Example
    attr_accessor :comment
    attr_reader :params

    @@json_examples = {}

    JSONModel.models.each_pair do |type, klass|
      next if type =~ /^abstract_/
      @@json_examples[type] = JSON.parse( FactoryBot.build("json_#{type}".to_sym).to_json )
    end

    @@json_examples.freeze

    def self.from_endpoint_defn(endpoint, method)
      raise "#{method} not in #{endpoint[:method]}" unless endpoint[:method].include? method
      params = {}
      uri = endpoint[:uri].dup
      endpoint[:params].each do |param_defn|
        raise param_defn unless param_defn.is_a?(Array)
        (name, type, doc, opts) = param_defn
        param_class = type.is_a?(Array) ? type[0] : type
        value = if name == "resolve" && endpoint[:returns][0][1].match(/\(:[a-z]+\)/)
                  type = eval(endpoint[:returns][0][1])
                  type = type[0] if type.is_a? Array
                  schema = JSONModel::JSONModel(type).schema
                  schema["properties"].select {|k, v| v['type'] == 'object' && v['subtype'] == 'ref'}.keys
                elsif param_class.is_a?(Symbol)
                  param_class.to_s
                elsif param_class.respond_to?(:record_type)
                  raise "Missing Factory #{param_class.record_type}" unless @@json_examples[param_class.record_type]
                  @@json_examples[param_class.record_type]
                elsif param_class.to_s.include?("RESTHelpers")
                  param_class.to_s.split("::").last
                elsif param_class == Integer
                  "1"
                elsif param_class == String
                  ""
                elsif param_class == Username
                  "example_username"
                else
                  $stderr.puts param_class
                  raise "No param value for #{param_defn} in endpoint #{endpoint[:uri]}"
                end
        if opts && opts[:body] && value.is_a?(Hash)
          params.merge!(value)
        elsif type.is_a?(Array) || value.is_a?(Array)
          params["#{name}[]"] = value
        else
          params[name] = value
        end
      end
      params.each do |k, v|
        params.delete(k) if uri.sub!(":#{k}", v) if v.is_a?(String)
      end
      # in practice only .xml formats used for :fmt params:
      uri.sub!(":fmt", "xml")
      params = {} if endpoint[:no_data]
      self.new(uri, method, params, "auto-generated example")
    end

    def self.prune_params(params)
      pruned = params.dup
      pruned.each do |k, v|
        if v.is_a? Hash
          pruned[k] = prune_params(v)
        end
      end
      pruned.reject! { |k,v| v.respond_to?(:empty?) && v.empty? }
      pruned
    end

    def initialize(uri, method, params, comment = nil)
      @method = method.to_sym
      uri.sub!(":repo_id", (params[:repo_id] || 2).to_s)
      uri.sub!(":id", (params[:id] || 1).to_s)
      @uri = BACKEND_URL + uri.gsub(":repo_id", "2").gsub(":id", "1")
      @params = params
      @comment = comment
    end

    def get?
      @method == :get
    end

    def post?
      @method == :post
    end

    def delete?
      @method == :delete
    end

    def data?
      @params && !@params.keys.empty?
    end

    def form_payload
      pruned = self.class.prune_params(@params)
      JSON.pretty_generate(pruned)
    end

    def has_param?(param)
      @params.keys.map { |k| k.to_s }.include?(param.to_s)
    end

    def add_param(key, value)
      raise "already has #{key}" if has_param? key
      @params[key] = value
    end

    def request_url
      if get? && data?
        "#{@uri}?#{URI.encode_www_form(@params)}"
      else
        @uri
      end
    end

  end
end

include FactoryBot::Syntax::Methods


# Use the test factories, or register a bespoke example, or provide
# an example manually withing the backend/app/controller/*.rb files
ApiDoc.register_example "/search", :get, {
                          q: "important papers",
                          aq: build(:json_advanced_query),
                          page: 1,
                          page_size: 10
                        }, "basic search with 10 results per page"

ApiDoc.register_example "/repositories/:repo_id/top_containers/bulk/barcodes", :post, {
                          repo_id: 1,
                          barcode_data: "{\"/repositories/:repo_id/top_containers/1\":\"8675309\"}"
                        }, "assign barcodes in bulk by posting a hash"
