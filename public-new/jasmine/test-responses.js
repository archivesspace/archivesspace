var TestResponses = {
  search: {
    success: {
      status: 200,
      responseText: JSON.stringify({
        facet_data: {},
        search_data: {
          this_page: 1,
          page_size: 40,
          total_hits: 3,
          results: [
            {
              title: "Jimmy Page Papers",
              primary_type: 'resource',
              uri: "/repositories/13/resources/666"
            },
            {
              title: "Robert Plant Papers"
            },
            {
              title: "Stairway to Heaven Manuscript"
            }
          ],
          criteria: {
            'filter_term[]': ['{"repositories":"/repositories/2"}'],
            'q': 'foo',
            'page_size': 40
          }
        }
      })
    },
    failure: {
      status: 500,
      responseText: 'BARF'
    }
  }
};
