require 'uri'
require 'net/http'
require 'advanced_search'

class Solr

  @@search_hooks ||= []


  def self.add_search_hook(&block)
    @@search_hooks << block
  end

  def self.search_hooks
    @@search_hooks
  end


  class Query

    def self.create_match_all_query
      new("*:*")
    end


    def self.create_keyword_search(query)
      new(query)
    end


    def self.create_term_query(field, term)
      new(term_query(field, term)).use_standard_query_type
    end


    def self.create_advanced_search(advanced_query_json)
      new(construct_advanced_query_string(advanced_query_json['query'])).
        use_standard_query_type
    end


    def self.construct_advanced_query_string(advanced_query, use_literal = false)
      if advanced_query.has_key?('subqueries')
        clauses = advanced_query['subqueries'].map {|subq|
          construct_advanced_query_string(subq, use_literal)
        }

# This causes incorrect results for X NOT Y queries via the PUI, see https://github.com/archivesspace/archivesspace/issues/1699
#        # Solr doesn't allow purely negative expression groups, so we add a
#        # match all query to compensate when we hit one of these.
#        if advanced_query['subqueries'].all? {|subquery| subquery['negated']}
#          clauses << '*:*'
#        end

        subqueries = clauses.join(" #{advanced_query['op']} ")

        "(#{subqueries})"
      else
        AdvancedQueryString.new(advanced_query, use_literal).to_solr_s
      end
    end


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


    def use_standard_query_type
      @query_type = :standard
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
        query =  Array(record_types).map { |type| "\"#{type}\"" }.join(' OR ')
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
                                                                  use_literal = true)
        add_solr_param(:fq, query_string)
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
      else
        # staff ui
        add_solr_param(:fq, "-types:pui_only")
      end


      if @highlighting
        add_solr_param(:hl, "true")
        if @query_type == :standard
          add_solr_param(:"hl.fl", "*")
        end
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
        add_solr_param(:qf, "four_part_id^3 title^2 finding_aid_filing_title^2 fullrecord")
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
