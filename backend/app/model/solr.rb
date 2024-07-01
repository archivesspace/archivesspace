require 'uri'
require 'net/http'
require 'advanced_search'

class Solr

  class ChecksumMismatchError < StandardError; end

  class NotFound < StandardError; end

  module Checksums
    def checksum_valid?
      internal_checksum == external_checksum
    end

    def external_checksum
      @external_checksum || lookup_external_checksum
    end

    def internal_checksum
      @internal_checksum || lookup_internal_checksum
    end

    private

    def lookup_external_checksum
      url = URI(File.join(@url, @path))
      response = Net::HTTP.get_response(url)
      if response.code == '200'
        @external_checksum = Digest::SHA2.hexdigest(response.body)
      else
        # if we made it this far, solr (or another server) is probably there
        # but cannot find the documents we want, most likely because the core
        # has not been set up correctly.
        message = "Status #{response.code} when trying to verify #{@url}"
        if response.body
          message += "Server response:\n#{response.body}"
        end
        raise NotFound.new(message)
      end
    end

    def lookup_internal_checksum
      ASConstants::Solr.send(@name.upcase.intern)
    end
  end

  class Config
    include Checksums
    attr_reader :name

    def initialize(url, name = nil)
      @external_checksum = nil
      @internal_checksum = nil
      @name = name
      @path = nil
      @url = url
    end
  end

  class Schema < Config
    def initialize(url)
      super(url)
      @name = 'schema'
      @path = 'admin/file?file=schema.xml&contentType=text%2Fxml%3Bcharset%3Dutf-8'
    end
  end

  class Solrconfig < Config
    def initialize(url)
      super(url)
      @name = 'solrconfig'
      @path = 'admin/file?file=solrconfig.xml&contentType=text%2Fxml%3Bcharset%3Dutf-8'
    end
  end

  @@search_hooks ||= []


  def self.add_search_hook(&block)
    @@search_hooks << block
  end

  def self.search_hooks
    @@search_hooks
  end

  def self.verify_checksums!
    verify_checksum!(Solr::Schema.new(AppConfig[:solr_url]))
  end

  def self.verify_checksum!(config)
    return true if config.checksum_valid?

    raise ChecksumMismatchError.new "Solr checksum verification failed (#{config.name}): expected [#{config.internal_checksum}] got [#{config.external_checksum}]"
  end

  class Query

    def self.create_match_all_query
      new("*:*")
    end


    def self.create_keyword_search(query)
      new(query)
    end


    def self.create_term_query(field, term)
      new(term_query(field, term))
    end


    def self.create_advanced_search(advanced_query_json, protect_unpublished: false)
      query = new(construct_advanced_query_string(advanced_query_json['query'], protect_unpublished: protect_unpublished))
      query.protect_unpublished! if protect_unpublished
      query
    end


    # AdvancedQueryString maps application's search options to Solr fields.
    def self.construct_advanced_query_string(advanced_query, use_literal: false, protect_unpublished: false)
      if advanced_query.has_key?('subqueries')
        clauses = advanced_query['subqueries'].map {|subq|
          construct_advanced_query_string(subq, use_literal: use_literal, protect_unpublished: protect_unpublished)
        }
        subqueries = clauses.join(" #{advanced_query['op']} ")
        "(#{subqueries})"
      else
        AdvancedQueryString.new(advanced_query, use_literal: use_literal, protect_unpublished: protect_unpublished).to_solr_s
      end
    end

    # The query_string parameter needs to be created before
    # initialization (see above). Possible refactor to have that
    # conversion happen when the instance is rendered into a Solr url.
    def initialize(query_string, opts = {})
      @solr_url = URI.parse(AppConfig[:solr_url])

      @query_string = query_string
      @writer_type = "json"
      @query_type = :edismax
      @pagination = nil
      @solr_params = []
      @facet_fields = []
      @highlighting = false

      @show_suppressed = false
      @show_published_only = false
      @csv_header = true
      @protect_unpublished = opts[:protect_unpublished] || false
    end

    def add_solr_params_from_config
      if AppConfig[:solr_params].any?
        AppConfig[:solr_params].each do |param, value|
          if value.is_a? Array
            value.each do |v|
              add_solr_param(param, v.respond_to?(:call) ? self.instance_eval(&v) : v)
            end
          else
            add_solr_param(param, value.respond_to?(:call) ? self.instance_eval(&value) : value)
          end
        end
      end
    end

    def remove_csv_header
      @csv_header = false
    end

    def set_solr_url(solr_url)
      @solr_url = solr_url
      self
    end


    def highlighting(yes_please = true)
      @highlighting = yes_please
      self
    end


    def pagination(page, page_size)
      @pagination = {:page => page, :page_size => page_size}
      self
    end


    def page_size
      @pagination[:page_size]
    end


    def set_repo_id(repo_id)
      if repo_id
        add_solr_param(:fq, "repository:\"/repositories/#{repo_id}\" OR repository:global")
      end

      self
    end


    def set_root_record(root_record)
      if root_record
        add_solr_param(:fq, "(resource:\"#{root_record}\" OR digital_object:\"#{root_record}\")")
      end

      self
    end


    def set_record_types(record_types)
      if record_types
        query = Array(record_types).map { |type| "\"#{type}\"" }.join(' OR ')
        add_solr_param(:fq, "types:(#{query})")
      end

      self
    end


    def set_excluded_ids(ids)
      if ids
        query = ids.map { |id| "\"#{id}\"" }.join(' OR ')
        add_solr_param(:fq, "-id:(#{query})")
      end

      self
    end


    def set_filter(advanced_query)
      if advanced_query
        query_string = self.class.construct_advanced_query_string(advanced_query['query'],
                                                                  use_literal: true)
        add_solr_param(:fq, query_string)
      end

      self
    end

    def set_filter_queries(queries)
      ASUtils.wrap(queries).each do |q|
        add_solr_param(:fq, "{!type=edismax}#{q}")
      end

      self
    end


    def show_suppressed(value)
      @show_suppressed = value
      self
    end


    def set_facets(fields, mincount = 0)
      if fields
        @facet_fields = fields
      end

      @facet_mincount = mincount

      self
    end


    def set_sort(sort)
      add_solr_param(:sort, sort)
    end


    def show_excluded_docs(value)
      @show_excluded_docs = value
      self
    end


    def show_published_only(value)
      @show_published_only = value
      self
    end

    def limit_fields_to(fields)
      @fields_to_show = fields
      self
    end

    def add_solr_param(param, value)
      @solr_params << [param, value]
      self
    end


    def set_writer_type(type)
      @writer_type = type
    end

    def get_writer_type
      @writer_type
    end

    def to_solr_url
      raise "Missing pagination settings" unless @pagination

      if @fields_to_show
        add_solr_param(:fl, @fields_to_show.join(', '))
      end

      unless @show_excluded_docs
        add_solr_param(:fq, "-exclude_by_default:true")
      end

      if @show_published_only
        # public ui
        add_solr_param(:fq, "publish:true")
        add_solr_param(:fq, "types:pui")
      else
        # staff ui
        add_solr_param(:fq, "-types:pui_only")
      end


      if @highlighting
        add_solr_param(:hl, "true")
        add_solr_param(:"hl.fl", "*")
        add_solr_param(:"hl.simple.pre", '<span class="searchterm">')
        add_solr_param(:"hl.simple.post", "</span>")
      end

      unless @show_suppressed
        add_solr_param(:fq, "suppressed:false")
      end

      add_solr_param(:facet, "true")
      unless @facet_fields.empty?
        add_solr_param(:"facet.field", @facet_fields)
        add_solr_param(:"facet.limit", AppConfig[:solr_facet_limit])
        add_solr_param(:"facet.mincount", @facet_mincount)
      end

      if @query_type == :edismax
        add_solr_param(:defType, "edismax")
        add_solr_param(:pf, "four_part_id^4")
        if @protect_unpublished
          add_solr_param(:qf, "identifier_ws^3 title_ws^2 finding_aid_filing_title^2 fullrecord_published")
        else
          add_solr_param(:qf, "identifier_ws^3 title_ws^2 finding_aid_filing_title^2 fullrecord")
        end
      end

      # do it here so instance variables can be resolved
      add_solr_params_from_config

      Solr.search_hooks.each do |hook|
        hook.call(self)
      end

      url = @solr_url
      # retain path if present i.e. "solr/aspace/select" when using an external Solr with path required
      url.path += "/select"
      url.query = URI.encode_www_form([[:q, @query_string],
                                       [:wt, @writer_type],
                                       ["csv.escape", '\\'],
                                       ["csv.encapsulator", '"'],
                                       ["csv.header", @csv_header ],
                                       [:start, (@pagination[:page] - 1) * @pagination[:page_size]],
                                       [:rows, @pagination[:page_size]]] +
                                      @solr_params)

      url
    end


    def protect_unpublished!
      @protect_unpublished = true
    end

    private

    def self.term_query(field, term)
      "{!term f=#{field}}#{term}"
    end

  end


  def self.search(query)
    url = query.to_solr_url

    req = Net::HTTP::Post.new(url.path)
    req.body = url.query
    req.content_type = 'application/x-www-form-urlencoded'

    ASHTTP.start_uri(url) do |http|
      solr_response = http.request(req)

      if solr_response.code == '200'
        return solr_response.body unless query.get_writer_type == "json"
        json = ASUtils.json_parse(solr_response.body)

        result = {}

        page_size = query.page_size

        result['page_size'] = page_size
        result['first_page'] = 1
        result['last_page'] = (json['response']['numFound'] / page_size.to_f).ceil
        result['this_page'] = (json['response']['start'] / page_size) + 1

        result['offset_first'] = json['response']['start'] + 1
        result['offset_last'] = [(json['response']['start'] + page_size), json['response']['numFound']].min
        result['total_hits'] = json['response']['numFound']

        result['results'] = json['response']['docs'].map {|doc|
          doc['uri'] ||= doc['id']
          doc['jsonmodel_type'] = doc['primary_type']
          doc
        }

        result['facets'] = json['facet_counts']

        if json['highlighting']
          result['highlighting'] = json['highlighting']
        end

        return result
      else
        raise "Solr search failed: #{solr_response.body}"
      end
    end
  end

end
