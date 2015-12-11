beforeEach(function() {

  // It can be easy to forget, but doing something like:
  //   jasmine.Ajax.install();
  //   loadFixtures();
  // causes tests to silently die. This ensures that
  // we have things in the right order in our setups

  if(window.loadFixtures) {

    window.loadFixtures = function() {
      if (window.XMLHttpRequest.name === "FakeXMLHttpRequest") {
        throw new Error("Can't load fixtures after Mock Ajax has taken over");
      } else {
        jasmine.getFixtures().proxyCallTo_('load', arguments)
      }
    }
  }

});
