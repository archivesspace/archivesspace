require 'spec_helper'

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

  it "can pass a query to Solr" do
    http = MockHTTP.new
    Net::HTTP.stub(:start) { |host, port, &block| http.start(host, port, block) }

    response = Solr.search("hello world", 1, 10, @repo_id, ['optional_record_type'])

    http.request.path.should match(/hello\+world/)
    http.request.path.should match(/wt=json/)
    http.request.path.should match(/suppressed%3Afalse/)
    http.request.path.should match(/fq=type%3A%28]?%22optional_record_type/)

    response['offset_first'].should eq(1)
    response['offset_last'].should eq(1)

    response['total_hits'].should eq(1)
    response['first_page'].should eq(1)
    response['this_page'].should eq(1)
    response['last_page'].should eq(1)
    response['results'][0]['title'].should eq("A Resource")
  end

end
