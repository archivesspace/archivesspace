var TestResponses = {
  search: {
    success: {
      status: 200,
      responseText: JSON.stringify({
        facet_data: {},
        criteria: {},
        search_data: {
          total_hits: 3,
          results: []
        }
      })
    },
    failure: {
      status: 500,
      responseText: 'BARF'
    }
  }
};
