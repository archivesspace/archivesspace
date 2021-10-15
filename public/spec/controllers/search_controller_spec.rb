require 'spec_helper'

describe SearchController, type: :controller do
  # Since test data is created in both `spec_helper` as well as in some of the individual
  # controller tests, predicting total numbers of results is tricky.  Just hardcoding
  # the repo id of these new tests to '2' (the `spec_helper` test data) for now.

  it 'should return all records' do
    response = get(:search, params: {
      :rid => 2,
      :q => ['*'],
      :op => ['OR'],
      :field => ['']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to eq(33)
  end

  it 'should return all digital objects when filtered' do
    response = get(:search, params: {
      :rid => 2,
      :q => ['*'],
      :op => ['OR'],
      :limit => 'digital_object',
      :field => ['']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to eq(4)
  end

  it 'should return digital object component with identifier search' do
    response = get(:search, params: {
     :rid => 2,
     :q => ['12345'],
     :op => ['OR'],
     :field => ['identifier']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to eq(1)
  end

  it 'should return a linked resource with subject search' do
    response = get(:search, params: {
     :rid => 2,
     :q => ['Term 1'],
     :op => ['OR'],
     :field => ['subjects_text']
    })
    result_data = controller.instance_variable_get(:@results)

    expect(response).to have_http_status(200)
    expect(response).to render_template('search/search_results')
    expect(result_data['total_hits']).to eq(1)
  end

end
