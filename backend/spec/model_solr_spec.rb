require 'spec_helper'
require 'cgi'

$dummy_data = <<EOF
  {
  "responseHeader":{
    "status":0,
    "QTime":58,
    "params":{
      "wt":"json",
      "indent":"true",
      "q":"*:*"}},
  "response":{"numFound":1,"start":0,"docs":[
      {
        "id":"/repositories/2/resources/1",
        "title":"A Resource",
        "type":"resource",
        "suppressed":false}]
  }}
EOF

class MockHTTP

  attr_accessor :request

  def start(host, port, block)
    http = Object.new

    def http.parent=(val)
      @parent = val
    end


    def http.request(req)
      @parent.request = req
      response = Object.new

      def response.body; $dummy_data; end

      def response.code; '200'; end

      response
    end

    http.parent = self

    block.call(http)
  end

end


describe 'Solr model' do

  it "can pass a query to Solr, including params from config" do
    http = MockHTTP.new
    Net::HTTP.stub(:start) { |host, port, &block| http.start(host, port, block) }

    AppConfig[:solr_params] = {
      "bq" => proc { "title:\"#{@query_string}\"*" },
      "pf" => 'title^10',
      "ps" => 0,
    }
    query = Solr::Query.create_keyword_search("hello world").
                        pagination(1, 10).
                        set_repo_id(@repo_id).
                        set_excluded_ids(%w(alpha omega)).
                        set_record_types(['optional_record_type']).
                        show_published_only(true).
                        highlighting

    response = Solr.search(query)

    expect(http.request.body).to match(/hello\+world/)
    expect(http.request.body).to match(/wt=json/)
    expect(http.request.body).to match(/suppressed%3Afalse/)
    expect(http.request.body).to match(/fq=types%3A%28?%22optional_record_type/)
    expect(http.request.body).to match(/-id%3A%28%22alpha%22\+OR\+%22omega/)
    expect(http.request.body).to match(/hl=true/)
    expect(http.request.body).to match(/bq=title%3A%22hello\+world%22\*/)
    expect(http.request.body).to match(/pf=title%5E10/)
    expect(http.request.body).to match(/ps=0/)
    expect(http.request.body).to match(/fq=publish%3Atrue/)
    expect(http.request.body).to_not match(/fq=-types%3Apui_only/)


    expect(response['offset_first']).to eq(1)
    expect(response['offset_last']).to eq(1)

    expect(response['total_hits']).to eq(1)
    expect(response['first_page']).to eq(1)
    expect(response['this_page']).to eq(1)
    expect(response['last_page']).to eq(1)
    expect(response['results'][0]['title']).to eq("A Resource")

    # repeat with show_published_only false i.e. a sui search
    query = Solr::Query.create_keyword_search("hello world").
                        pagination(1, 10).
                        set_repo_id(@repo_id).
                        set_excluded_ids(%w(alpha omega)).
                        set_record_types(['optional_record_type']).
                        show_published_only(false).
                        highlighting

    Solr.search(query)

    expect(http.request.body).to match(/hello\+world/)
    expect(http.request.body).to_not match(/fq=publish%3Atrue/)
    expect(http.request.body).to match(/fq=-types%3Apui_only/)
  end

  it "adjusts date searches for the local timezone" do
    test_time = Time.parse('2000-01-01')

    advanced_query = {
      "query" => {
        "jsonmodel_type" => "date_field_query",
        "comparator" => "equal",
        "field" => "create_time",
        "value" => test_time.strftime('%Y-%m-%d'),
        "precision": "day",
        "negated" => false
      }
    }

    query = Solr::Query.create_advanced_search(advanced_query)

    expect(CGI.unescape(query.pagination(1, 10).to_solr_url.to_s)).to include(test_time.utc.iso8601)
  end


  describe 'Query parsing' do

    let (:canned_query) {
      {"jsonmodel_type"=>"boolean_query",
       "op"=>"AND",
       "subqueries"=>[{"jsonmodel_type"=>"boolean_query",
                       "op"=>"AND",
                       "subqueries"=>[{"field"=>"title",
                                       "value"=>"tennis",
                                       "negated"=>true,
                                       "jsonmodel_type"=>"field_query",
                                       "literal"=>false}]},
                      {"jsonmodel_type"=>"boolean_query",
                       "op"=>"AND",
                       "subqueries"=>[{"jsonmodel_type"=>"boolean_query",
                                       "op"=>"AND",
                                       "subqueries"=>[{"field"=>"keyword",
                                                       "value"=>"golf",
                                                       "negated"=>false,
                                                       "jsonmodel_type"=>"field_query",
                                                       "literal"=>false}]}]}]}
    }

    it "constructs advanced query containing Boolean NOT without adding a match-all clause" do
      query_string = Solr::Query.construct_advanced_query_string(canned_query)

      expect(query_string).to eq("((-title:(tennis)) AND (((golf))))")
    end

  end

  describe 'Solr params from AppConfig' do
    let (:advanced_query) {
      { "query" => {
          "subqueries" => [
              {
                  "field" => "types",
                  "value" => "resource",
                  "literal" => true,
                  "jsonmodel_type" => "field_query",
                  "negated" => false
              },
              {
                  "field" => "published",
                  "value" => "true",
                  "literal" => true,
                  "jsonmodel_type" => "field_query",
                  "negated" => false
              }
          ],
          "jsonmodel_type" => "boolean_query"
      },
      "jsonmodel_type" => "advanced_query" }
    }

    let (:query) { Solr::Query.create_advanced_search(advanced_query).
                        pagination(1, 10).
                        set_repo_id(@repo_id) }

    it 'does not include q.op parameter in solr url when not configured' do
      AppConfig[:solr_params] = { }
      url = query.to_solr_url
      expect(url.query).not_to include('&q.op=')
    end

    it 'includes q.op parameter in solr url when configured' do
      AppConfig[:solr_params] = { "q.op" => "AND" }
      url = query.to_solr_url
      expect(url.query).to include('&q.op=AND')
    end

    it 'handles params with array values by passing the param multiple times' do
      AppConfig[:solr_params] = { "bq" => ["one", proc {"two"}]}
      url = query.to_solr_url
      expect(url.query).to include('&bq=one')
      expect(url.query).to include('&bq=two')
    end

  end

  describe 'Checksums' do
    let(:response) { instance_double(Net::HTTPResponse) }

    def solrfile(file)
      File.read(File.join(*[ ASUtils.find_base_directory, 'solr', file]))
    end

    it 'will be valid when the internal and external checksums match' do
      allow(response).to receive(:code).and_return('200')
      allow(response).to receive(:body).and_return(solrfile('schema.xml'))
      allow(Net::HTTP).to receive(:get_response).and_return(response)
      expect { Solr.verify_checksums! }.not_to raise_error
    end

    it 'will be invalid when the schema checksum does not match' do
      allow(response).to receive(:code).and_return('200')
      bad_schema = solrfile('schema.xml').sub('archivesspace', 'example')
      allow(response).to receive(:body).and_return(bad_schema)
      allow(Net::HTTP).to receive(:get_response).and_return(response)
      expect { Solr.verify_checksums! }.to raise_error(Solr::ChecksumMismatchError)
    end

    it 'will raise an error when the solr server returns a 404' do
      allow(response).to receive(:code).and_return('404')
      allow(response).to receive(:body).and_return("NOT FOUND")
      allow(Net::HTTP).to receive(:get_response).and_return(response)
      expect { Solr.verify_checksums! }.to raise_error(Solr::NotFound)
    end
  end

end
