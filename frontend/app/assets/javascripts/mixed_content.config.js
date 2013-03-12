$(function() {
  AS.mixedContentElements = [
      {
        tag: "blockquote",
        attributes: []
      },
      {
        tag: "date",
        attributes: ["type", "normal", "calendar", "era"]
      },
      {
        tag: "function",
        attributes: ["rules", "source"]
      },
      {
        tag: "occupation",
        attributes: ["type", "normal", "calendar", "era"]
      },
      {
        tag: "subject",
        attributes: ["type", "normal", "calendar", "era"]
      },
      {
        tag: "emph",
        attributes: ["render"]
      },
      {
        tag: "corpname",
        attributes: ["rules", "role", "source"]
      },
      {
        tag: "persname",
        attributes: ["rules", "role", "source"]
      },
      {
        tag: "famname",
        attributes: ["rules", "role", "source"]
      },
      {
        tag: "name",
        attributes: ["rules", "role", "source"]
      },
      {
        tag: "geogname",
        attributes: ["rules", "role", "source"]
      },
      {
        tag: "genreform",
        attributes: ["rules", "role", "type"]
      },
      {
        tag: "title",
        attributes: ["render"]
      },
      {
        tag: "ref",
        attributes: ["target", "show", "title", "actuate"]
      },
      {
        tag: "extref",
        attributes: ["target", "show", "title", "actuate"]
      },
      {
        tag: "outline",
        elements: [
          {
            tag: "level",
            elements: [
              {
                tag: "item"
              },
              {
                tag: "level",
                elements: [
                  {
                    tag: "item"
                  },
                  {
                    tag: "level",
                    elements: [
                      {
                        tag: "item"
                      },
                      {
                        tag: "level",
                        elements: [
                          {
                            tag: "item"
                          },
                          {
                            tag: "level",
                            elements: [
                              {
                                tag: "item"
                              },
                              {
                                tag: "level",
                                elements: [
                                  {
                                    tag: "item"
                                  },
                                  {
                                    tag: "level",
                                    elements: [
                                      {
                                        tag: "item"
                                      },
                                      {
                                        tag: "level"
                                      }
                                    ]
                                  }
                                ]
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ];
});
