module ASpaceHelpers
  include Capybara::DSL

  def wait_for_jquery
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 1
      loop until finished_all_ajax_requests?
    end
  end

  BatchCreatedRecord = Struct.new(:id, :uri)

  # Creates `count` published archival objects in the current repository with
  # a single batch import request, instead of one request per record.  The
  # records are positioned in creation order under `parent` (or at the top
  # level of `resource`), so `result[i]` is the (i + 1)th sibling.  An optional
  # block receives the index and returns extra values for that record.
  def batch_create_archival_objects(count, resource:, parent: nil, **values)
    repo_id = JSONModel.repository
    records = Array.new(count) do |i|
      build(:archival_object, {
        resource: {'ref' => resource.uri},
        parent: parent && {'ref' => parent.uri},
        position: i,
        publish: true
      }.compact.merge(values).merge(block_given? ? yield(i) : {})).to_hash(:raw).merge(
        'uri' => "/repositories/#{repo_id}/archival_objects/import_#{SecureRandom.hex(8)}"
      )
    end

    url = URI("#{JSONModel::HTTP.backend_url}/repositories/#{repo_id}/batch_imports")
    response = JSONModel::HTTP.post_json(url, records.to_json)
    results = ASUtils.json_parse(response.body).last
    if response.code != '200' || results['errors']
      raise "Batch import failed (#{response.code}): #{results['errors'] || response.body}"
    end

    records.map do |record|
      uri, id = results['saved'].fetch(record['uri'])
      BatchCreatedRecord.new(id, uri)
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script("typeof window.jQuery != 'undefined'") &&
      page.evaluate_script('window.jQuery !== undefined') &&
      page.evaluate_script('jQuery.active !== undefined') &&
      page.evaluate_script('jQuery.active')&.zero?
  rescue Selenium::WebDriver::Error::JavascriptError
    false
  end
end
